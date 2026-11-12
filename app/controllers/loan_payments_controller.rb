# frozen_string_literal: true

class LoanPaymentsController < ApplicationController
  before_action :set_loan

  def index
    @payments = @loan.loan_payments.posted.chronological
    @payments = @payments.for_year(params[:year]) if params[:year].present?
    @payments = @payments.of_type(params[:payment_type]) if params[:payment_type].present?
    @payments = @payments.paid_between(parse_date(params[:from]), parse_date(params[:to]))

    @years = @loan.loan_payments.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM paid_on)::integer")).sort
    @snapshots = @loan.loan_monthly_snapshots.chronological
    @fy_summaries = build_fy_summaries(@snapshots)
  end

  private

  def set_loan
    @loan = Loan.includes(:loan_payments, :loan_monthly_snapshots).find(params[:loan_id])
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  # Indian FY: Apr (year) – Mar (year+1)
  def build_fy_summaries(snapshots)
    snapshots.group_by { |s| s.month >= 4 ? "#{s.year}-#{s.year + 1}" : "#{s.year - 1}-#{s.year}" }
             .map do |label, rows|
      ordered = rows.sort_by { |r| [ r.year, r.month ] }
      {
        label: "FY #{label}",
        opening: ordered.first.opening_balance,
        closing: ordered.last.closing_balance,
        emi: ordered.sum { |r| r.emi_paid.to_d },
        principal: ordered.sum { |r| r.principal_paid.to_d },
        interest: ordered.sum { |r| r.interest_paid.to_d },
        prepayment: ordered.sum { |r| r.prepayment.to_d },
        charges: ordered.sum { |r| r.charges.to_d },
        total: ordered.sum { |r| r.total_paid.to_d }
      }
    end
  end
end
