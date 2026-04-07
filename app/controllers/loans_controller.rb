class LoansController < ApplicationController
  before_action :require_login, except: %i[index show]
  before_action :set_loan, only: %i[show edit update destroy]
  before_action :authorize_loan, only: %i[edit update destroy]

  def index
    @loans = Loan.includes(:prepayments).order(created_at: :desc)
  end

  def show
  end

  def new
    @loan = current_user.loans.build(start_date: Date.current)
  end

  def create
    @loan = current_user.loans.build(loan_params)
    if @loan.save
      redirect_to loans_path, notice: "Loan created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @loan.update(loan_params)
      redirect_to root_path, notice: "Loan updated."
    else
      redirect_to root_path, alert: @loan.errors.full_messages.to_sentence.presence || "Could not update loan."
    end
  end

  def destroy
    @loan.destroy
    redirect_to loans_path, notice: "Loan deleted."
  end

  private

  def set_loan
    @loan = Loan.find(params[:id])
  end

  def authorize_loan
    return if @loan.user_id == current_user.id

    redirect_to root_path, alert: "You cannot change this loan."
  end

  def loan_params
    params.require(:loan).permit(:title, :principal, :annual_interest_rate, :term_months, :start_date, :notes)
  end
end
