# frozen_string_literal: true

class LoanEmiSchedulesController < ApplicationController
  before_action :set_loan
  before_action :require_login, only: :create
  before_action :authorize_loan_owner!, only: :create

  def index
    @schedules = @loan.loan_emi_schedules.chronological
    @schedules = @schedules.for_year(params[:year]) if params[:year].present?
    @schedules = @schedules.with_status(params[:status]) if params[:status].present?
    @schedules = @schedules.due_between(parse_date(params[:from]), parse_date(params[:to]))

    @years = @loan.loan_emi_schedules.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM due_on)::integer")).sort
    @summary = {
      total: @loan.loan_emi_schedules.count,
      paid: @loan.loan_emi_schedules.paid.count,
      pending: @loan.loan_emi_schedules.pending.count,
      overdue: @loan.loan_emi_schedules.where(status: "overdue").count
    }
  end

  def create
    mode = params[:mode].presence&.to_sym || :full
    result = LoanEmiScheduleGenerator.generate!(@loan, mode: mode)
    if result.success?
      redirect_to loan_loan_emi_schedules_path(@loan), notice: "EMI schedule generated (#{result.created_count} rows)."
    else
      redirect_to loan_loan_emi_schedules_path(@loan), alert: result.errors.to_sentence
    end
  end

  private

  def set_loan
    @loan = Loan.find(params[:loan_id])
  end

  def authorize_loan_owner!
    return if @loan.user_id == current_user.id

    redirect_to loan_loan_emi_schedules_path(@loan), alert: "You cannot regenerate this schedule."
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
