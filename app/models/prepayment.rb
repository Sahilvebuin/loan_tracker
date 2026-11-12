class Prepayment < ApplicationRecord
  belongs_to :loan
  has_one :loan_payment, dependent: :nullify

  validates :amount, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validates :charges, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :amount_within_outstanding

  private

  def amount_within_outstanding
    return if loan.blank? || amount.blank?

    max = loan.ledger_outstanding
    errors.add(:amount, "cannot exceed outstanding principal") if amount.to_d > max.to_d
  end
end
