# frozen_string_literal: true

require "test_helper"

class LoanMasterTest < ActiveSupport::TestCase
  test "creating a loan sets master defaults and side records" do
    user = users(:one)
    loan = user.loans.create!(
      title: "Car Loan #{SecureRandom.hex(4)}",
      principal: 500_000,
      annual_interest_rate: 10.5,
      term_months: 60,
      start_date: Date.new(2026, 3, 20)
    )

    assert_equal 500_000, loan.sanctioned_amount.to_f
    assert_equal 500_000, loan.disbursed_amount.to_f
    assert_equal "fixed", loan.interest_rate_type
    assert_equal "active", loan.status
    assert_equal 15, loan.emi_due_day
    assert_equal "other", loan.loan_type
    assert_equal Date.new(2026, 4, 15), loan.emi_start_date
    assert loan.emi_amount.to_d.positive?
    assert_equal loan.principal, loan.original_principal

    assert_equal 1, loan.loan_interest_rates.count
    assert_equal 10.5, loan.current_interest_rate_row.interest_rate.to_f
    assert_nil loan.current_interest_rate_row.effective_to

    primary = loan.loan_borrowers.find_by(role: "primary")
    assert_equal user.id, primary.user_id
    assert_equal 100, primary.ownership_percent.to_f
  end

  test "original principal is not the outstanding balance" do
    loan = loans(:one)
    assert_equal loan.principal, loan.original_principal
  end
end
