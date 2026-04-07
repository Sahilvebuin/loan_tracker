class Prepayment < ApplicationRecord
  belongs_to :loan

  validates :amount, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validate :amount_within_outstanding

  private

  def amount_within_outstanding
    return if loan.blank? || amount.blank?

    max = loan.outstanding_principal
    errors.add(:amount, "cannot exceed outstanding principal") if amount.to_d > max.to_d
  end
end
