# frozen_string_literal: true

# A rate change can also come with bank-revised terms (new EMI, outstanding, remaining tenure).
# When present, these reset the schedule from the first EMI due on/after effective_from.
class AddRevisionTermsToLoanInterestRates < ActiveRecord::Migration[8.1]
  def change
    add_column :loan_interest_rates, :emi_amount, :decimal, precision: 15, scale: 2
    add_column :loan_interest_rates, :opening_principal, :decimal, precision: 15, scale: 2
    add_column :loan_interest_rates, :remaining_months, :integer
  end
end
