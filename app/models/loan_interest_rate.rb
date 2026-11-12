# frozen_string_literal: true

class LoanInterestRate < ApplicationRecord
  belongs_to :loan

  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :effective_from, presence: true
  # Optional bank-revised terms applied from the first EMI due on/after effective_from.
  validates :emi_amount, :opening_principal, numericality: { greater_than: 0 }, allow_nil: true
  validates :remaining_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :effective_to_after_from
  validate :no_open_overlap

  scope :current, -> { where(effective_to: nil) }
  scope :chronological, -> { order(:effective_from, :id) }

  def self.rate_on(loan, on_date)
    on = on_date.to_date
    where(loan_id: loan.id)
      .where("effective_from <= ?", on)
      .where("effective_to IS NULL OR effective_to >= ?", on)
      .order(effective_from: :desc, id: :desc)
      .first
  end

  def current?
    effective_to.nil?
  end

  private

  def effective_to_after_from
    return if effective_to.blank? || effective_from.blank?
    return if effective_to >= effective_from

    errors.add(:effective_to, "must be on or after effective_from")
  end

  def no_open_overlap
    return if loan.blank? || effective_from.blank?

    scope = loan.loan_interest_rates.where.not(id: id)
    if effective_to.nil?
      other_open = scope.where(effective_to: nil)
      errors.add(:base, "loan already has a current interest rate") if other_open.exists?
    end

    overlapping = scope.where("effective_from <= ?", effective_to || Date.new(9999, 12, 31))
                       .where("effective_to IS NULL OR effective_to >= ?", effective_from)
    errors.add(:base, "interest rate period overlaps an existing period") if overlapping.exists?
  end
end
