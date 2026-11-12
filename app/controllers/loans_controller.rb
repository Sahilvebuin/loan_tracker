class LoansController < ApplicationController
  before_action :require_login, except: %i[index show]
  before_action :set_loan, only: %i[show edit update destroy]
  before_action :authorize_loan, only: %i[edit update destroy]

  def index
    @loans = Loan.includes(:user, :loan_payments, :loan_emi_schedules).order(:title, :id)
    preferred = %w[Sahil Sanket]
    @loans_by_person = @loans.group_by(&:user).sort_by { |user, _|
      [ preferred.index(user.name) || preferred.size, user.name.to_s ]
    }
  end

  def show
    @rates = @loan.loan_interest_rates.chronological
    @co_borrowers = @loan.loan_borrowers.select { |lb| lb.role == "co_borrower" }
    @next_emi = @loan.loan_emi_schedules.where(status: %w[pending overdue]).order(:due_on, :installment_no).first
    @remaining_months = @loan.loan_emi_schedules.where(status: %w[pending overdue]).count
    @recent_payments = @loan.loan_payments.posted.order(paid_on: :desc, id: :desc).limit(6)
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
    scope = Loan.all
    if action_name == "show"
      scope = scope.includes(
        :user,
        :loan_interest_rates,
        :loan_emi_schedules,
        :loan_payments,
        :loan_monthly_snapshots,
        loan_borrowers: :user
      )
    end
    @loan = scope.find(params[:id])
  end

  def authorize_loan
    return if @loan.user_id == current_user.id

    redirect_to root_path, alert: "You cannot change this loan."
  end

  def loan_params
    params.require(:loan).permit(
      :title, :principal, :annual_interest_rate, :term_months, :start_date, :notes,
      :loan_type, :lender_name, :account_number, :sanctioned_amount, :disbursed_amount,
      :interest_rate_type, :emi_start_date, :emi_amount, :emi_due_day,
      :processing_fee, :insurance_amount, :other_initial_charges, :status, :closed_on
    )
  end
end