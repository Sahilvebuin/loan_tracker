class EmiDeduction < ApplicationRecord
  belongs_to :loan

  validates :due_on, presence: true, uniqueness: { scope: :loan_id }
  validates :amount, numericality: { greater_than: 0 }
end
