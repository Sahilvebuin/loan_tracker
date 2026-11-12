# frozen_string_literal: true

class LoanMonthlySnapshot < ApplicationRecord
  belongs_to :loan

  validates :year, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, uniqueness: { scope: [ :loan_id, :month ] }
  validates :opening_balance, :closing_balance, numericality: true

  scope :chronological, -> { order(:year, :month) }

  def period_label
    Date.new(year, month, 1).strftime("%b %Y")
  end
end
