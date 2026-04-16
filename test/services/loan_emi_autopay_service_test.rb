require "test_helper"

class LoanEmiAutopayServiceTest < ActiveSupport::TestCase
  test "deducts EMI when due date reached and records emi_deduction" do
    user = users(:one)
    user.update!(account_balance: 1_000_000)

    loan = user.loans.create!(
      title: "Autopay test",
      principal: 100_000,
      annual_interest_rate: 12.0,
      term_months: 12,
      start_date: Date.new(2026, 1, 1)
    )

    before = user.account_balance.to_d
    LoanEmiAutopayService.call(as_of: Date.new(2026, 1, 15))

    loan.reload
    user.reload
    assert_equal 1, loan.emi_deductions.count
    deduction = loan.emi_deductions.sole
    assert_equal Date.new(2026, 1, 15), deduction.due_on
    assert_equal deduction.amount, before - user.account_balance.to_d
  end

  test "does not double-charge the same due date" do
    user = users(:one)
    user.update!(account_balance: 1_000_000)

    loan = user.loans.create!(
      title: "Idempotent",
      principal: 50_000,
      annual_interest_rate: 12.0,
      term_months: 6,
      start_date: Date.new(2026, 2, 1)
    )

    as_of = Date.new(2026, 2, 15)
    LoanEmiAutopayService.call(as_of: as_of)
    bal = user.reload.account_balance.to_d

    LoanEmiAutopayService.call(as_of: as_of)
    assert_equal bal, user.reload.account_balance.to_d
    assert_equal 1, loan.reload.emi_deductions.count
  end
end
