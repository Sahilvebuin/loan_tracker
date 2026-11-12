# frozen_string_literal: true

require "test_helper"

class LoanPaymentRecorderTest < ActiveSupport::TestCase
  setup do
    @loan = loans(:one)
    @loan.emi_deductions.destroy_all
    @loan.loan_emi_schedules.destroy_all
    @loan.loan_payments.destroy_all
    @loan.loan_monthly_snapshots.destroy_all
  end

  test "backfill stores EMI payments and monthly snapshots from schedule" do
    due = Date.new(2026, 5, 15)
    travel_to due do
      helper = Class.new { include CalculatorHelper }.new
      monthly = helper.loan_emi(@loan.principal, @loan.annual_interest_rate, @loan.term_months)
      sy, sm = helper.emi_schedule_anchor_year_month(@loan.start_date)
      first_due = Date.new(sy, sm, CalculatorHelper::EMI_PAY_DAY)
      @loan.emi_deductions.create!(due_on: first_due, amount: monthly.round(2))

      result = LoanEmiScheduleGenerator.generate!(@loan, mode: :full, as_of: due)
      assert result.success?

      assert LoanPaymentRecorder.backfill_loan!(@loan)
      @loan.reload

      assert @loan.loan_payments.posted.emis.count.positive?
      assert @loan.loan_monthly_snapshots.count.positive?
      assert @loan.loan_payments.posted.first.loan_payment_allocations.count == 1

      last = @loan.loan_payments.posted.chronological.last
      assert_in_delta last.balance_after.to_f, @loan.ledger_outstanding.to_f, 0.02
      assert_equal @loan.principal.to_d, @loan.original_principal
    end
  end

  test "record_emi posts ledger row and marks schedule paid" do
    LoanEmiScheduleGenerator.generate!(@loan, mode: :full, as_of: Date.new(2026, 4, 1))
    row = @loan.loan_emi_schedules.chronological.first

    result = LoanPaymentRecorder.record_emi!(
      loan: @loan,
      schedule: row,
      paid_on: row.due_on,
      amount: row.scheduled_emi,
      principal_amount: row.principal_amount,
      interest_amount: row.interest_amount
    )
    assert result.success?, result.errors.inspect
    assert_equal "paid", row.reload.status
    assert_equal 1, @loan.loan_audit_entries.where(action: "create").count
  end
end
