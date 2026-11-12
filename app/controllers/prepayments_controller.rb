class PrepaymentsController < ApplicationController
  before_action :require_login
  before_action :set_loan
  before_action :authorize_loan
  REMOVE_WINDOW_DAYS = 5

  def create
    @prepayment = @loan.prepayments.build(prepayment_params)
    error_message = nil
    balance_before = @loan.ledger_outstanding

    ActiveRecord::Base.transaction do
      unless @prepayment.save
        error_message = @prepayment.errors.full_messages.to_sentence.presence || "Could not save prepayment."
        raise ActiveRecord::Rollback
      end

      @prepayment.update!(
        principal_reduction: @prepayment.amount,
        charges: @prepayment.charges.to_d,
        balance_before: balance_before,
        balance_after: balance_before - @prepayment.amount.to_d
      )

      result = LoanPaymentRecorder.record_prepayment!(
        loan: @loan,
        paid_on: @prepayment.paid_on,
        amount: @prepayment.amount,
        prepayment: @prepayment,
        charges_amount: @prepayment.charges.to_d,
        notes: @prepayment.notes,
        reason: @prepayment.reason,
        user: current_user
      )
      unless result.success?
        error_message = result.errors.to_sentence
        raise ActiveRecord::Rollback
      end

      # Recalculate future EMIs from the new outstanding (EMI amount stays the same).
      schedule_result = LoanEmiScheduleGenerator.rebuild_remaining!(@loan)
      unless schedule_result.success?
        error_message = schedule_result.errors.to_sentence
        raise ActiveRecord::Rollback
      end
    end

    if error_message
      redirect_to root_path, alert: error_message
    else
      redirect_to loans_path,
                  notice: "Prepayment of #{helpers.format_inr(@prepayment.amount)} saved. #{@loan.user.name}'s account remaining and paid updated."
    end
  end

  def destroy
    prepayment = @loan.prepayments.find(params[:id])
    if prepayment.paid_on.present? && prepayment.paid_on < (Date.current - REMOVE_WINDOW_DAYS)
      redirect_to root_path, alert: "This prepayment can only be removed within #{REMOVE_WINDOW_DAYS} days."
      return
    end

    ActiveRecord::Base.transaction do
      payment = prepayment.loan_payment
      if payment
        old = payment.attributes.slice("amount", "principal_amount", "status", "balance_after")
        payment.update!(status: "reversed")
        LoanAuditEntry.record!(
          loan: @loan,
          auditable: payment,
          action: "reverse",
          old_values: old,
          new_values: { "status" => "reversed" },
          reason: "Prepayment removed within correction window",
          user: current_user
        )
      end
      prepayment.destroy!
      # Rebuild ledger snapshots and remaining schedule without this prepayment.
      LoanPaymentRecorder.backfill_loan!(@loan)
      LoanEmiScheduleGenerator.rebuild_remaining!(@loan)
    end

    redirect_to loans_path, notice: "Prepayment removed. Outstanding and EMI plan recalculated."
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def authorize_loan
    return if @loan.user_id == current_user.id

    redirect_to root_path, alert: "You cannot change this loan."
  end

  def prepayment_params
    params.require(:prepayment).permit(:amount, :paid_on, :notes, :reason, :reference_number, :charges)
  end
end
