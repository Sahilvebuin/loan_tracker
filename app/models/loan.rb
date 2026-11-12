class Loan < ApplicationRecord
  include CalculatorHelper

  STATUSES = %w[active closed].freeze
  RATE_TYPES = %w[fixed floating].freeze
  LOAN_TYPES = %w[home additional other].freeze

  belongs_to :user

  has_many :prepayments, dependent: :destroy
  has_many :emi_deductions, dependent: :destroy
  has_many :loan_interest_rates, dependent: :destroy
  has_many :loan_borrowers, dependent: :destroy
  has_many :loan_emi_schedules, dependent: :destroy
  has_many :loan_payments, dependent: :destroy
  has_many :loan_monthly_snapshots, dependent: :destroy
  has_many :loan_audit_entries, dependent: :destroy
  has_many :borrowers, through: :loan_borrowers, source: :user

  validates :title, uniqueness: { scope: :user_id }, allow_blank: true

  validates :principal, numericality: { greater_than: 0 }
  validates :annual_interest_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :term_months, numericality: { only_integer: true, greater_than: 0 }
  validates :start_date, presence: true
  validates :interest_rate_type, inclusion: { in: RATE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :emi_due_day, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 28 }
  validates :loan_type, inclusion: { in: LOAN_TYPES }, allow_nil: true
  validates :sanctioned_amount, :disbursed_amount, :emi_amount,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :processing_fee, :insurance_amount, :other_initial_charges,
            numericality: { greater_than_or_equal_to: 0 }

  before_validation :apply_master_defaults, on: :create
  after_create :ensure_initial_interest_rate!
  after_create :ensure_primary_borrower!

  def total_prepayments
    prepayments.sum(:amount)
  end

  def outstanding_principal(as_of: Date.current)
    # Prefer stored ledger when payments exist (correct with prepays after EMIs).
    last = loan_payments.posted.where("paid_on <= ?", as_of).order(:paid_on, :id).last
    return balance_after_ledger_payment(last, as_of: as_of) if last&.balance_after

    loan_payment_state(self, as_of: as_of)[:current_balance].to_d
  end

  # Latest bank-stated outstanding (rate revision with opening_principal) effective after +after+
  # and on/before +on_or_before+ — it supersedes the ledger balance carried from before it.
  def bank_restatement_between(after, on_or_before)
    scope = loan_interest_rates.where.not(opening_principal: nil).where("effective_from <= ?", on_or_before)
    scope = scope.where("effective_from > ?", after) if after
    scope.order(:effective_from, :id).last
  end

  def outstanding_after_prepayments
    [ principal - total_prepayments, 0 ].max
  end

  # Original sanctioned principal — never treat outstanding as this value.
  def original_principal
    (sanctioned_amount.presence || principal).to_d
  end

  def current_interest_rate_row
    loan_interest_rates.current.order(effective_from: :desc, id: :desc).first
  end

  def interest_rate_on(date)
    LoanInterestRate.rate_on(self, date)&.interest_rate || annual_interest_rate
  end

  def primary_borrower
    loan_borrowers.find_by(role: "primary")&.user || user
  end

  # Ledger source of truth when payments exist; otherwise derived schedule state.
  def ledger_outstanding(as_of: Date.current)
    last = loan_payments.posted.chronological.last
    return balance_after_ledger_payment(last, as_of: [ as_of.to_date, last.paid_on ].max) if last&.balance_after

    outstanding_principal(as_of: as_of)
  end

  def total_principal_paid_ledger
    loan_payments.posted.sum(:principal_amount).to_d
  end

  def total_interest_paid_ledger
    loan_payments.posted.sum(:interest_amount).to_d
  end

  def total_emi_paid_ledger
    loan_payments.posted.emis.sum(:amount).to_d
  end

  def total_prepayment_ledger
    loan_payments.posted.prepayments.sum(:principal_amount).to_d
  end

  def total_amount_paid_ledger
    loan_payments.posted.sum(:amount).to_d
  end

  private

  def balance_after_ledger_payment(payment, as_of:)
    restated = bank_restatement_between(payment.paid_on, as_of)
    restated ? restated.opening_principal.to_d : payment.balance_after.to_d
  end

  def apply_master_defaults
    self.sanctioned_amount ||= principal
    self.disbursed_amount ||= principal
    self.interest_rate_type = "fixed" if interest_rate_type.blank?
    self.status = "active" if status.blank?
    self.emi_due_day = CalculatorHelper::EMI_PAY_DAY if emi_due_day.blank?
    self.loan_type ||= infer_loan_type
    self.emi_start_date ||= default_emi_start_date
    self.emi_amount ||= computed_emi_amount
  end

  def infer_loan_type
    t = title.to_s.downcase
    return "additional" if t.include?("additional")
    return "home" if t.include?("home")

    "other"
  end

  def default_emi_start_date
    return nil if start_date.blank?

    sy, sm = emi_schedule_anchor_year_month(start_date)
    Date.new(sy, sm, emi_due_day.to_i.clamp(1, 28))
  end

  def computed_emi_amount
    return nil if principal.blank? || annual_interest_rate.blank? || term_months.blank?

    loan_emi(principal, annual_interest_rate, term_months).to_d.round(2)
  end

  def ensure_initial_interest_rate!
    return if loan_interest_rates.exists?

    loan_interest_rates.create!(
      interest_rate: annual_interest_rate,
      effective_from: emi_start_date || start_date,
      effective_to: nil,
      remarks: "Initial rate"
    )
  end

  def ensure_primary_borrower!
    return if loan_borrowers.exists?(user_id: user_id)

    loan_borrowers.create!(
      user_id: user_id,
      role: "primary",
      ownership_percent: 100
    )
  end
end
