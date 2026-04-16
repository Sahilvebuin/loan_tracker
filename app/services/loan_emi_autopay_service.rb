# Deducts scheduled EMI totals from the borrower's account on each due date (see CalculatorHelper::EMI_PAY_DAY).
# Idempotent per (loan, due_on) via EmiDeduction records.
class LoanEmiAutopayService
  include CalculatorHelper

  class << self
    def call(as_of: Date.current)
      new.call(as_of: as_of)
    end
  end

  def call(as_of: Date.current)
    Loan.includes(:user).find_each do |loan|
      process_loan(loan, as_of: as_of)
    end
  end

  private

  def process_loan(loan, as_of:)
    outstanding = loan.outstanding_principal.to_f
    return if outstanding <= 0.01

    original_emi = loan_emi(loan.principal, loan.annual_interest_rate, loan.term_months)
    remaining = remaining_schedule_months(loan, original_emi, outstanding)
    return if remaining <= 0

    start_year, start_month = emi_schedule_anchor_year_month(loan.start_date)
    rows = monthly_amortization_rows(
      outstanding,
      loan.annual_interest_rate,
      remaining,
      start_year: start_year,
      start_month: start_month,
      fixed_payment: original_emi
    )

    rows.each do |row|
      due_on = Date.new(row[:calendar_year], row[:month], EMI_PAY_DAY)
      next if due_on > as_of

      amount = row[:total_paid].to_d
      next if amount <= 0

      ActiveRecord::Base.transaction do
        if EmiDeduction.exists?(loan_id: loan.id, due_on: due_on)
          raise ActiveRecord::Rollback
        end

        user = User.lock.find(loan.user_id)
        balance = user.account_balance.to_d
        if balance < amount
          Rails.logger.warn(
            "LoanEmiAutopayService: insufficient balance user_id=#{user.id} loan_id=#{loan.id} due_on=#{due_on} " \
            "required=#{amount} balance=#{balance}"
          )
          raise ActiveRecord::Rollback
        end

        loan.emi_deductions.create!(due_on: due_on, amount: amount)
        user.update!(account_balance: balance - amount)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # Concurrent run claimed this due_on; safe to ignore.
    nil
  end

  def remaining_schedule_months(loan, original_emi, outstanding)
    term = loan.term_months.to_i
    prepay_gap = loan.principal.to_f - outstanding
    if outstanding <= 0.01
      0
    elsif prepay_gap <= 0.01
      term
    else
      loan_months_from_fixed_emi(outstanding, loan.annual_interest_rate, original_emi)
    end
  end
end
