# frozen_string_literal: true

require "test_helper"

# Bank revision after a repo-rate change: new rate, revised EMI, restated outstanding, remaining tenure.
class LoanRateRevisionTest < ActiveSupport::TestCase
  include CalculatorHelper

  setup do
    @loan = loans(:one) # ₹10,00,000 @ 9% · 120 months · first EMI 15 Apr 2026
    @loan.prepayments.destroy_all # brothers have no prepayments; keep the walk EMI-only
    @user = @loan.user
    @user.update!(account_balance: 10_000_000)
    3.times do |i|
      due = Date.new(2026, 4 + i, 15)
      LoanEmiAutopayService.call(as_of: due)
    end
  end

  def revise!(**opts)
    LoanInterestRateService.change!(
      loan: @loan,
      interest_rate: 9.25,
      effective_from: Date.new(2026, 6, 16),
      remarks: "Repo +0.25%",
      **opts
    ).tap { |r| assert r.success?, r.errors.inspect }
  end

  test "bank-revised terms reset schedule from next EMI and sync loan EMI" do
    revise!(emi_amount: 12_800, opening_principal: 975_000, remaining_months: 116)
    @loan.reload

    assert_equal 9.25, @loan.annual_interest_rate.to_f
    assert_equal 12_800, @loan.emi_amount.to_f

    rows = loan_schedule_rows(@loan)
    assert_equal 3 + 116, rows.length
    jul = rows[3]
    assert_equal [ 2026, 7 ], [ jul[:calendar_year], jul[:month] ]
    assert_in_delta 975_000, jul[:opening], 0.01
    assert_in_delta 12_800, jul[:total_paid], 0.01
    assert_in_delta 975_000 * 9.25 / 1200, jul[:interest_paid], 0.01
    assert_in_delta 0, rows.last[:balance], 0.01

    # Ledger balance restated to the bank figure once the revision is in effect.
    assert_in_delta 975_000, @loan.outstanding_principal(as_of: Date.new(2026, 7, 1)).to_f, 0.01
    assert_not_in_delta 975_000, @loan.outstanding_principal(as_of: Date.new(2026, 6, 15)).to_f, 0.01

    state = loan_payment_state(@loan)
    assert_equal 3, state[:emis_paid_count]
    assert_equal 116, state[:remaining_months]
    assert_in_delta 975_000, state[:current_balance], 0.01
  end

  test "autopay debits revised EMI and ledger starts from restated balance" do
    revise!(emi_amount: 12_800, opening_principal: 975_000, remaining_months: 116)
    LoanEmiScheduleGenerator.generate!(@loan.reload, mode: :full, as_of: Date.new(2026, 7, 14))
    LoanPaymentRecorder.backfill_loan!(@loan)

    LoanEmiAutopayService.call(as_of: Date.new(2026, 7, 15))

    deduction = @loan.emi_deductions.find_by!(due_on: Date.new(2026, 7, 15))
    assert_equal 12_800, deduction.amount.to_f
    payment = @loan.loan_payments.chronological.last
    assert_in_delta 975_000, payment.balance_before.to_f, 0.01
    schedule = @loan.loan_emi_schedules.find_by!(due_on: Date.new(2026, 7, 15))
    assert_equal "paid", schedule.status
    assert_in_delta 9.25, schedule.applicable_interest_rate.to_f, 0.0001
  end

  test "rate change without bank terms keeps EMI and carries balance" do
    old_emi = loan_emi(@loan.principal, 9.0, 120)
    revise!
    rows = loan_schedule_rows(@loan.reload)

    assert_in_delta rows[2][:balance], rows[3][:opening], 0.01
    assert_in_delta old_emi, rows[3][:total_paid], 0.01
    assert_operator rows.length, :>, 120 # higher rate at same EMI stretches tenure
  end
end
