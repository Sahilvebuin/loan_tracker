# frozen_string_literal: true

require "test_helper"

class LoanEmiScheduleGeneratorTest < ActiveSupport::TestCase
  setup do
    @loan = loans(:one)
    @loan.emi_deductions.destroy_all
    @loan.loan_emi_schedules.destroy_all
  end

  test "generates full schedule from existing EMI math without changing principal" do
    original_principal = @loan.principal.to_d

    result = LoanEmiScheduleGenerator.generate!(@loan, mode: :full, as_of: Date.new(2026, 4, 1))
    assert result.success?, result.errors.inspect
    assert result.created_count.positive?
    assert_equal original_principal, @loan.reload.principal.to_d

    first = @loan.loan_emi_schedules.chronological.first
    assert_equal 1, first.installment_no
    assert_equal original_principal, first.opening_principal.to_d
    assert first.scheduled_emi.to_d.positive?
    assert_equal "pending", first.status
  end

  test "marks schedule rows paid when emi_deductions exist" do
    helper = Class.new { include CalculatorHelper }.new
    monthly = helper.loan_emi(@loan.principal, @loan.annual_interest_rate, @loan.term_months)
    sy, sm = helper.emi_schedule_anchor_year_month(@loan.start_date)
    due = Date.new(sy, sm, CalculatorHelper::EMI_PAY_DAY)
    @loan.emi_deductions.create!(due_on: due, amount: monthly.round(2))

    result = LoanEmiScheduleGenerator.generate!(@loan, mode: :full, as_of: due)
    assert result.success?

    row = @loan.loan_emi_schedules.find_by!(due_on: due)
    assert_equal "paid", row.status
    assert_equal due, row.paid_on
    assert_in_delta monthly, row.actual_paid_amount.to_f, 0.02
  end

  test "refresh_pending keeps paid rows" do
    LoanEmiScheduleGenerator.generate!(@loan, mode: :full, as_of: Date.new(2026, 4, 1))
    first = @loan.loan_emi_schedules.chronological.first
    first.update!(status: "paid", paid_on: first.due_on, actual_paid_amount: first.scheduled_emi)

    result = LoanEmiScheduleGenerator.generate!(@loan, mode: :refresh_pending, as_of: Date.new(2026, 4, 1))
    assert result.success?

    kept = @loan.loan_emi_schedules.find_by!(installment_no: 1)
    assert_equal "paid", kept.status
    assert_equal first.actual_paid_amount.to_d, kept.actual_paid_amount.to_d
  end
end
