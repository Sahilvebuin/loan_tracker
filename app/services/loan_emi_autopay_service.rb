# Deducts scheduled EMI totals from the borrower's account on each due date (see CalculatorHelper::EMI_PAY_DAY).
# Idempotent per (loan, due_on) via EmiDeduction records. Also posts loan_payments ledger rows.
# Run daily at 00:01 — on the 15th, that day's EMI is debited.
class LoanEmiAutopayService
  include CalculatorHelper

  class << self
    def call(as_of: Date.current)
      new.call(as_of: as_of)
    end
  end

  def call(as_of: Date.current)
    Loan.includes(:user, :emi_deductions, :loan_emi_schedules).find_each do |loan|
      process_loan(loan, as_of: as_of)
    end
  end

  private

  def process_loan(loan, as_of:)
    schedule_principal = loan.outstanding_after_prepayments.to_f
    return if schedule_principal <= 0.01

    # Original terms, then any bank revisions (rate change / revised EMI) — see CalculatorHelper#loan_term_segments.
    rows = loan_schedule_rows(loan)

    rows.each do |row|
      due_on = Date.new(row[:calendar_year], row[:month], EMI_PAY_DAY)
      next if due_on > as_of

      amount = row[:total_paid].to_d
      next if amount <= 0
      next if loan.emi_deductions.exists?(due_on: due_on)

      ActiveRecord::Base.transaction do
        user = User.lock.find(loan.user_id)
        balance = user.account_balance.to_d
        if balance < amount
          Rails.logger.warn(
            "LoanEmiAutopayService: insufficient balance user_id=#{user.id} loan_id=#{loan.id} due_on=#{due_on} " \
            "required=#{amount} balance=#{balance}"
          )
          raise ActiveRecord::Rollback
        end

        deduction = loan.emi_deductions.create!(due_on: due_on, amount: amount)
        user.update!(account_balance: balance - amount)

        schedule = loan.loan_emi_schedules.find_by(due_on: due_on)
        principal_part = schedule&.principal_amount || row[:principal_paid].to_d
        interest_part = schedule&.interest_amount || row[:interest_paid].to_d

        result = LoanPaymentRecorder.record_emi!(
          loan: loan,
          schedule: schedule,
          paid_on: due_on,
          amount: amount,
          principal_amount: principal_part,
          interest_amount: interest_part,
          emi_deduction: deduction,
          notes: "Autopay EMI"
        )
        raise ActiveRecord::Rollback unless result.success?
      end
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end
end
