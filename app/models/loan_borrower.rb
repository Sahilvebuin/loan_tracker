# frozen_string_literal: true

class LoanBorrower < ApplicationRecord
  ROLES = %w[primary co_borrower].freeze

  belongs_to :loan
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :ownership_percent, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :user_id, uniqueness: { scope: :loan_id }
  validate :single_primary_per_loan

  private

  def single_primary_per_loan
    return unless role == "primary" && loan.present?

    others = loan.loan_borrowers.where(role: "primary").where.not(id: id)
    errors.add(:role, "loan already has a primary borrower") if others.exists?
  end
end
