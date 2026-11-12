# frozen_string_literal: true

class LoanEmiSchedule < ApplicationRecord
  STATUSES = %w[pending paid partially_paid overdue skipped cancelled].freeze
  LOCKED_STATUSES = %w[paid partially_paid skipped cancelled].freeze

  belongs_to :loan

  validates :installment_no, numericality: { only_integer: true, greater_than: 0 }
  validates :due_on, presence: true
  validates :opening_principal, :scheduled_emi, :interest_amount, :principal_amount, :closing_principal,
            numericality: true
  validates :applicable_interest_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :installment_no, uniqueness: { scope: :loan_id }
  validates :due_on, uniqueness: { scope: :loan_id }

  scope :chronological, -> { order(:installment_no, :due_on) }
  scope :paid, -> { where(status: "paid") }
  scope :pending, -> { where(status: "pending") }
  scope :for_year, ->(year) { where("EXTRACT(YEAR FROM due_on) = ?", year.to_i) }
  scope :with_status, ->(status) { where(status: status) if status.present? }
  scope :due_between, ->(from_date, to_date) {
    rel = all
    rel = rel.where("due_on >= ?", from_date) if from_date.present?
    rel = rel.where("due_on <= ?", to_date) if to_date.present?
    rel
  }

  def locked?
    LOCKED_STATUSES.include?(status)
  end

  def paid?
    status == "paid"
  end
end
