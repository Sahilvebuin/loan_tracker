# frozen_string_literal: true

# Rebuilds monthly financial snapshots from posted loan_payments.
class LoanMonthlySnapshotBuilder
  def self.rebuild_for_loan!(loan)
    new(loan: loan).rebuild!
  end

  def initialize(loan:)
    @loan = loan
  end

  def rebuild!
    @loan.loan_monthly_snapshots.delete_all

    payments = @loan.loan_payments.posted.chronological.to_a
    return if payments.empty?

    opening = @loan.principal.to_d
    groups = payments.group_by { |p| [ p.paid_on.year, p.paid_on.month ] }

    groups.keys.sort.each do |year, month|
      month_payments = groups[[ year, month ]]
      emi_paid = month_payments.select { |p| p.payment_type == "emi" }.sum { |p| p.amount.to_d }
      principal_paid = month_payments.sum { |p| p.principal_amount.to_d }
      interest_paid = month_payments.sum { |p| p.interest_amount.to_d }
      prepayment = month_payments.select { |p| p.payment_type == "prepayment" }.sum { |p| p.principal_amount.to_d }
      charges = month_payments.sum { |p| p.charges_amount.to_d }
      total_paid = month_payments.sum { |p| p.amount.to_d }
      closing = month_payments.last.balance_after.to_d
      rate = @loan.interest_rate_on(Date.new(year, month, 1)).to_d
      month_end = Date.new(year, month, -1)
      rem = @loan.loan_emi_schedules.where("due_on > ?", month_end).where(status: %w[pending overdue]).count

      @loan.loan_monthly_snapshots.create!(
        year: year,
        month: month,
        opening_balance: opening.round(2),
        emi_paid: emi_paid.round(2),
        principal_paid: principal_paid.round(2),
        interest_paid: interest_paid.round(2),
        prepayment: prepayment.round(2),
        charges: charges.round(2),
        total_paid: total_paid.round(2),
        closing_balance: closing.round(2),
        interest_rate: rate.round(4),
        remaining_months: rem
      )

      opening = closing
    end
  end
end
