class PrepaymentsController < ApplicationController
  before_action :require_login
  before_action :set_loan
  before_action :authorize_loan
  REMOVE_WINDOW_DAYS = 5

  def create
    @prepayment = @loan.prepayments.build(prepayment_params)
    if @prepayment.save
      redirect_to root_path, notice: "Prepayment recorded. EMI stays the same; remaining tenure is updated."
    else
      redirect_to root_path, alert: @prepayment.errors.full_messages.to_sentence.presence || "Could not save prepayment."
    end
  end

  def destroy
    prepayment = @loan.prepayments.find(params[:id])
    if prepayment.paid_on.present? && prepayment.paid_on < (Date.current - REMOVE_WINDOW_DAYS)
      redirect_to root_path, alert: "This prepayment can only be removed within #{REMOVE_WINDOW_DAYS} days."
      return
    end

    prepayment.destroy
    redirect_to root_path, notice: "Prepayment removed."
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
    params.require(:prepayment).permit(:amount, :paid_on, :notes)
  end
end
