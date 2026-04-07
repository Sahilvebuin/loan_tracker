class LoanCalculatorPreset < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  validates :principal, numericality: { greater_than: 0 }, allow_nil: true
  validates :annual_interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :term_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :amount_slider_max, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end

