# frozen_string_literal: true

# Posts EMI / prepayment / other payments to the permanent ledger.
class LoanPaymentRecorder
  Result = Struct.new(:success?, :payment, :errors, keyword_init: true)

  def self.record_emi!(loan:, schedule:, paid_on:, amount:, principal_amount:, interest_amount:,
                       charges_amount: 0, emi_deduction: nil, reference_number: nil, notes: nil, user: nil)
    new(loan: loan).record(
      payment_type: "emi",
      schedule: schedule,
      paid_on: paid_on,
      amount: amount,
      principal_amount: principal_amount,
      interest_amount: interest_amount,
      charges_amount: charges_amount,
      emi_deduction: emi_deduction,
      reference_number: reference_number,
      notes: notes,
      user: user
    )
  end

  def self.record_prepayment!(loan:, paid_on:, amount:, prepayment: nil, charges_amount: 0,
                              reference_number: nil, notes: nil, reason: nil, user: nil)
    new(loan: loan).record(
      payment_type: "prepayment",
      paid_on: paid_on,
      amount: amount,
      principal_amount: amount.to_d - charges_amount.to_d,
      interest_amount: 0,
      charges_amount: charges_amount,
      prepayment: prepayment,
      reference_number: reference_number,
      notes: notes.presence || reason,
      user: user
    )
  end

  def initialize(loan:)
    @loan = loan
  end

  def record(payment_type:, paid_on:, amount:, principal_amount:, interest_amount:, charges_amount: 0,
             schedule: nil, emi_deduction: nil, prepayment: nil, reference_number: nil, notes: nil, user: nil)
    ActiveRecord::Base.transaction do
      before = current_balance(paid_on.to_date)
      after = before - principal_amount.to_d
      after = 0.to_d if after.negative?

      payment = @loan.loan_payments.create!(
        loan_emi_schedule: schedule,
        emi_deduction: emi_deduction,
        prepayment: prepayment,
        paid_on: paid_on.to_date,
        amount: amount.to_d.round(2),
        principal_amount: principal_amount.to_d.round(2),
        interest_amount: interest_amount.to_d.round(2),
        charges_amount: charges_amount.to_d.round(2),
        payment_type: payment_type,
        reference_number: reference_number,
        notes: notes,
        balance_before: before.round(2),
        balance_after: after.round(2),
        status: "posted"
      )

      payment.loan_payment_allocations.create!(
        user_id: (user || @loan.user).id,
        amount: payment.amount,
        ownership_percent: 100,
        contribution_percent: 100
      )

      if schedule && payment_type == "emi"
        schedule.update!(
          status: "paid",
          paid_on: payment.paid_on,
          actual_paid_amount: payment.amount
        )
      end

      LoanAuditEntry.record!(
        loan: @loan,
        auditable: payment,
        action: "create",
        new_values: payment.attributes.slice(
          "payment_type", "amount", "principal_amount", "interest_amount", "paid_on", "balance_after"
        ),
        user: user
      )

      LoanMonthlySnapshotBuilder.rebuild_for_loan!(@loan)

      Result.new(success?: true, payment: payment, errors: [])
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, payment: nil, errors: e.record.errors.full_messages)
  end

  # Backfill ledger from existing schedule + deductions + prepayments without inventing amounts.
  def self.backfill_loan!(loan)
    new(loan: loan).backfill!
  end

  def backfill!
    ActiveRecord::Base.transaction do
      @loan.loan_payments.destroy_all

      balance = @loan.principal.to_d
      events = []

      @loan.loan_emi_schedules.paid.chronological.each do |row|
        events << {
          sort_key: [ row.due_on, 0, row.installment_no ],
          type: "emi",
          paid_on: row.paid_on || row.due_on,
          amount: (row.actual_paid_amount.presence || row.scheduled_emi).to_d,
          principal: row.principal_amount.to_d,
          interest: row.interest_amount.to_d,
          charges: 0.to_d,
          schedule: row,
          deduction: @loan.emi_deductions.find_by(due_on: row.due_on)
        }
      end

      @loan.prepayments.find_each do |pp|
        events << {
          sort_key: [ pp.paid_on, 1, pp.id ],
          type: "prepayment",
          paid_on: pp.paid_on,
          amount: pp.amount.to_d,
          principal: (pp.principal_reduction.presence || pp.amount).to_d,
          interest: 0.to_d,
          charges: pp.charges.to_d,
          schedule: nil,
          deduction: nil,
          prepayment: pp
        }
      end

      # Bank revisions that state the outstanding reset the running balance on their effective date.
      @loan.loan_interest_rates.where.not(opening_principal: nil).each do |rate|
        events << { sort_key: [ rate.effective_from, -1, rate.id ], type: "restatement", balance: rate.opening_principal.to_d }
      end

      events.sort_by { |e| e[:sort_key] }.each do |event|
        if event[:type] == "restatement"
          balance = event[:balance]
          next
        end

        before = balance
        after = before - event[:principal]
        after = 0.to_d if after.negative?

        payment = @loan.loan_payments.create!(
          loan_emi_schedule: event[:schedule],
          emi_deduction: event[:deduction],
          prepayment: event[:prepayment],
          paid_on: event[:paid_on],
          amount: event[:amount].round(2),
          principal_amount: event[:principal].round(2),
          interest_amount: event[:interest].round(2),
          charges_amount: event[:charges].round(2),
          payment_type: event[:type],
          balance_before: before.round(2),
          balance_after: after.round(2),
          status: "posted",
          notes: "Backfilled from #{event[:type]} history"
        )

        payment.loan_payment_allocations.create!(
          user_id: @loan.user_id,
          amount: payment.amount,
          ownership_percent: 100,
          contribution_percent: 100
        )

        if event[:prepayment]
          event[:prepayment].update_columns(
            principal_reduction: event[:principal].round(2),
            balance_before: before.round(2),
            balance_after: after.round(2)
          )
        end

        balance = after
      end

      LoanMonthlySnapshotBuilder.rebuild_for_loan!(@loan)
    end

    true
  end

  private

  # Balance just before a payment on +paid_on+: last ledger balance, unless a bank revision
  # restated the outstanding (opening_principal) after that payment.
  def current_balance(paid_on = Date.current)
    last = @loan.loan_payments.posted.chronological.last
    if last&.balance_after
      restated = @loan.bank_restatement_between(last.paid_on, paid_on)
      return restated ? restated.opening_principal.to_d : last.balance_after.to_d
    end

    @loan.outstanding_principal(as_of: paid_on).to_d
  end
end
