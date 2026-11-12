# frozen_string_literal: true

class LoanPaymentAllocation < ApplicationRecord
  belongs_to :loan_payment
  belongs_to :user

  validates :amount, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :loan_payment_id }
end
