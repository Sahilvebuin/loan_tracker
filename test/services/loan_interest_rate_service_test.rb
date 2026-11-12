# frozen_string_literal: true

require "test_helper"

class LoanInterestRateServiceTest < ActiveSupport::TestCase
  setup do
    @loan = loans(:one)
  end

  test "records rate change without deleting previous rate" do
    assert_difference -> { @loan.loan_interest_rates.count }, 1 do
      result = LoanInterestRateService.change!(
        loan: @loan,
        interest_rate: 8.5,
        effective_from: Date.new(2026, 7, 1),
        remarks: "Repo cut"
      )
      assert result.success?, result.errors.inspect
    end

    rates = @loan.loan_interest_rates.chronological.to_a
    assert_equal 2, rates.size
    assert_equal Date.new(2026, 6, 30), rates.first.effective_to
    assert_nil rates.last.effective_to
    assert_equal 8.5, rates.last.interest_rate.to_f
    assert_equal 8.5, @loan.reload.annual_interest_rate.to_f
  end

  test "rate_on returns applicable historical rate" do
    LoanInterestRateService.change!(
      loan: @loan,
      interest_rate: 7.7,
      effective_from: Date.new(2026, 9, 1),
      remarks: "Sep change"
    )

    assert_equal 9.0, @loan.interest_rate_on(Date.new(2026, 8, 15)).to_f
    assert_equal 7.7, @loan.interest_rate_on(Date.new(2026, 9, 16)).to_f
  end

  test "rejects effective_from on or before current rate start" do
    result = LoanInterestRateService.change!(
      loan: @loan,
      interest_rate: 8.0,
      effective_from: Date.new(2026, 4, 7)
    )
    assert_not result.success?
  end
end
