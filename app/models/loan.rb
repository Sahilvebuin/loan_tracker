class Loan < ApplicationRecord
  belongs_to :user

  has_many :prepayments, dependent: :destroy

  validates :title, uniqueness: { scope: :user_id }, allow_blank: true

  validates :principal, numericality: { greater_than: 0 }
  validates :annual_interest_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :term_months, numericality: { only_integer: true, greater_than: 0 }
  validates :start_date, presence: true

  def total_prepayments
    prepayments.sum(:amount)
  end

  def outstanding_principal
    [ principal - total_prepayments, 0 ].max
  end
end
