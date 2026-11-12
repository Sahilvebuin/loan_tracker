# frozen_string_literal: true

class LoanPayment < ApplicationRecord
  PAYMENT_TYPES = %w[emi prepayment part_payment late_payment other].freeze
  STATUSES = %w[posted reversed corrected].freeze

  belongs_to :loan
  belongs_to :loan_emi_schedule, optional: true
  belongs_to :prepayment, optional: true
  belongs_to :emi_deduction, optional: true
  belongs_to :reversed_payment, class_name: "LoanPayment", optional: true
  has_many :reversals, class_name: "LoanPayment", foreign_key: :reversed_payment_id, dependent: :nullify
  has_many :loan_payment_allocations, dependent: :destroy

  validates :paid_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :principal_amount, :interest_amount, :charges_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_type, inclusion: { in: PAYMENT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validate :amounts_add_up

  scope :posted, -> { where(status: "posted") }
  scope :chronological, -> { order(:paid_on, :id) }
  scope :emis, -> { where(payment_type: "emi") }
  scope :prepayments, -> { where(payment_type: "prepayment") }
  scope :for_year, ->(year) { where("EXTRACT(YEAR FROM paid_on) = ?", year.to_i) }
  scope :of_type, ->(type) { where(payment_type: type) if type.present? }
  scope :paid_between, ->(from_date, to_date) {
    rel = all
    rel = rel.where("paid_on >= ?", from_date) if from_date.present?
    rel = rel.where("paid_on <= ?", to_date) if to_date.present?
    rel
  }

  def posted?
    status == "posted"
  end

  private

  def amounts_add_up
    return if amount.blank?

    sum = principal_amount.to_d + interest_amount.to_d + charges_amount.to_d
    return if (sum - amount.to_d).abs <= 0.02

    errors.add(:amount, "must equal principal + interest + charges (#{sum})")
  end
end
