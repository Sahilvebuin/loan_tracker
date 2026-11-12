# frozen_string_literal: true

# Records interest-rate changes without overwriting history.
# Keeps loans.annual_interest_rate (and loans.emi_amount, when the bank revised it) in sync with the current open rate row.
#
# Optional bank-revised terms (all applied from the first EMI due on/after effective_from):
#   emi_amount        — new EMI the bank will debit
#   opening_principal — outstanding principal the bank states before that EMI
#   remaining_months  — EMIs left at the new EMI
class LoanInterestRateService
  Result = Struct.new(:success?, :interest_rate, :errors, keyword_init: true)

  def self.change!(loan:, interest_rate:, effective_from:, remarks: nil, sync_loan_rate: true,
                   emi_amount: nil, opening_principal: nil, remaining_months: nil)
    new(
      loan: loan, interest_rate: interest_rate, effective_from: effective_from, remarks: remarks,
      sync_loan_rate: sync_loan_rate, emi_amount: emi_amount, opening_principal: opening_principal,
      remaining_months: remaining_months
    ).call
  end

  def initialize(loan:, interest_rate:, effective_from:, remarks: nil, sync_loan_rate: true,
                 emi_amount: nil, opening_principal: nil, remaining_months: nil)
    @loan = loan
    @interest_rate = interest_rate.to_d
    @effective_from = effective_from.to_date
    @remarks = remarks
    @sync_loan_rate = sync_loan_rate
    @emi_amount = emi_amount&.to_d
    @opening_principal = opening_principal&.to_d
    @remaining_months = remaining_months&.to_i
  end

  def call
    ActiveRecord::Base.transaction do
      current = @loan.loan_interest_rates.current.lock.first
      if current
        if @effective_from <= current.effective_from
          return failure("effective_from must be after the current rate's effective_from (#{current.effective_from})")
        end

        current.update!(effective_to: @effective_from - 1.day)
      end

      row = @loan.loan_interest_rates.create!(
        interest_rate: @interest_rate,
        effective_from: @effective_from,
        effective_to: nil,
        remarks: @remarks,
        emi_amount: @emi_amount,
        opening_principal: @opening_principal,
        remaining_months: @remaining_months
      )

      if @sync_loan_rate
        attrs = { annual_interest_rate: @interest_rate }
        attrs[:emi_amount] = @emi_amount if @emi_amount
        @loan.update!(attrs)
      end

      Result.new(success?: true, interest_rate: row, errors: [])
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  end

  private

  def failure(messages)
    Result.new(success?: false, interest_rate: nil, errors: Array(messages))
  end
end
