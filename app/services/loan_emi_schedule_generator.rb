# frozen_string_literal: true

# Builds permanent EMI schedule rows from existing CalculatorHelper amortization math.
# Does not change loan.principal / sanctioned amounts.
#
# mode:
#   :full   — replace all rows (initial backfill). Marks paid from emi_deductions.
#   :refresh_pending — keep locked rows; rebuild unpaid from original schedule math.
#   :rebuild_remaining — keep paid rows; rebuild future from current ledger outstanding (after prepayment).
class LoanEmiScheduleGenerator
  include CalculatorHelper

  Result = Struct.new(:success?, :created_count, :updated_count, :errors, keyword_init: true)

  def self.generate!(loan, mode: :full, as_of: Date.current)
    new(loan: loan, mode: mode, as_of: as_of).call
  end

  def self.rebuild_remaining!(loan, as_of: Date.current)
    new(loan: loan, mode: :rebuild_remaining, as_of: as_of).call
  end

  def initialize(loan:, mode: :full, as_of: Date.current)
    @loan = loan
    @mode = mode.to_sym
    @as_of = as_of.to_date
  end

  def call
    case @mode
    when :rebuild_remaining
      rebuild_remaining_from_outstanding!
    else
      rows = build_schedule_attributes
      return failure("Could not build EMI schedule (check principal/rate/tenure)") if rows.empty?

      created = 0
      updated = 0

      ActiveRecord::Base.transaction do
        case @mode
        when :full
          delete_schedule_rows!(@loan.loan_emi_schedules)
          rows.each { |attrs| @loan.loan_emi_schedules.create!(attrs); created += 1 }
        when :refresh_pending
          locked_dues = @loan.loan_emi_schedules.where(status: LoanEmiSchedule::LOCKED_STATUSES).pluck(:due_on).map(&:to_date).to_set
          delete_schedule_rows!(@loan.loan_emi_schedules.where.not(status: LoanEmiSchedule::LOCKED_STATUSES))

          rows.each do |attrs|
            due = attrs[:due_on]
            next if locked_dues.include?(due)

            existing = @loan.loan_emi_schedules.find_by(due_on: due)
            if existing
              existing.update!(attrs.except(:status, :paid_on, :actual_paid_amount))
              updated += 1
            else
              @loan.loan_emi_schedules.create!(attrs)
              created += 1
            end
          end
        else
          return failure("Unknown mode: #{@mode}")
        end
      end

      Result.new(success?: true, created_count: created, updated_count: updated, errors: [])
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  end

  private

  # Ledger payments reference schedule rows (FK); unlink them before deleting.
  # Re-run `emi:ledger` afterwards to re-link payments to the new rows.
  def delete_schedule_rows!(scope)
    LoanPayment.where(loan_emi_schedule_id: scope.select(:id)).update_all(loan_emi_schedule_id: nil)
    scope.delete_all
  end

  def rebuild_remaining_from_outstanding!
    created = 0

    ActiveRecord::Base.transaction do
      delete_schedule_rows!(@loan.loan_emi_schedules.where(status: %w[pending overdue]))

      opening = @loan.ledger_outstanding.to_d
      if opening <= 0.01
        return Result.new(success?: true, created_count: 0, updated_count: 0, errors: [])
      end

      rate = @loan.annual_interest_rate.to_d
      principal_basis = @loan.principal.to_d
      term = @loan.term_months.to_i
      monthly = (@loan.emi_amount.presence || loan_emi(principal_basis, rate, term)).to_d
      rem_months = loan_months_from_fixed_emi(opening.to_f, rate.to_f, monthly.to_f)
      rem_months = 1 if rem_months <= 0 && opening > 0.01

      last_paid = @loan.loan_emi_schedules.paid.order(:installment_no).last
      due_day = (@loan.emi_due_day.presence || EMI_PAY_DAY).to_i.clamp(1, 28)

      if last_paid
        next_date = last_paid.due_on.next_month.change(day: [ due_day, 28 ].min)
        start_no = last_paid.installment_no + 1
      else
        sy, sm =
          if @loan.emi_start_date.present?
            [ @loan.emi_start_date.year, @loan.emi_start_date.month ]
          else
            emi_schedule_anchor_year_month(@loan.start_date)
          end
        next_date = Date.new(sy, sm, due_day)
        start_no = 1
      end

      # Avoid due dates in the past for the new tail start
      while next_date < @as_of.beginning_of_month
        next_date = next_date.next_month.change(day: [ due_day, 28 ].min)
      end

      amort = monthly_amortization_rows(
        opening.to_f,
        rate.to_f,
        rem_months,
        start_year: next_date.year,
        start_month: next_date.month,
        fixed_payment: monthly.to_f
      )

      opening_walk = opening
      amort.each_with_index do |row, idx|
        due_on = Date.new(row[:calendar_year], row[:month], due_day)
        @loan.loan_emi_schedules.create!(
          installment_no: start_no + idx,
          due_on: due_on,
          opening_principal: opening_walk.round(2),
          scheduled_emi: row[:total_paid].to_d.round(2),
          interest_amount: row[:interest_paid].to_d.round(2),
          principal_amount: row[:principal_paid].to_d.round(2),
          closing_principal: row[:balance].to_d.round(2),
          applicable_interest_rate: @loan.interest_rate_on(due_on).to_d.round(4),
          status: due_on < @as_of ? "overdue" : "pending",
          paid_on: nil,
          actual_paid_amount: nil
        )
        opening_walk = row[:balance].to_d
        created += 1
      end
    end

    Result.new(success?: true, created_count: created, updated_count: 0, errors: [])
  end

  # Original terms, then any bank revisions (rate change / revised EMI / restated outstanding).
  # Prepayments are handled by :rebuild_remaining, not folded into the base schedule.
  def build_schedule_attributes
    due_day = (@loan.emi_due_day.presence || EMI_PAY_DAY).to_i.clamp(1, 28)
    amort = loan_schedule_rows(@loan, apply_prepayments: false)

    deductions_by_due = @loan.emi_deductions.index_by { |d| d.due_on.to_date }
    attrs = []

    amort.each_with_index do |row, idx|
      opening = row[:opening].to_d
      due_on = Date.new(row[:calendar_year], row[:month], due_day)
      interest = row[:interest_paid].to_d
      principal_part = row[:principal_paid].to_d
      closing = row[:balance].to_d
      scheduled = row[:total_paid].to_d
      applicable = @loan.interest_rate_on(due_on).to_d

      status = "pending"
      paid_on = nil
      actual = nil

      if (deduction = deductions_by_due[due_on])
        status = "paid"
        paid_on = deduction.due_on
        actual = deduction.amount.to_d
      elsif due_on < @as_of
        status = "overdue"
      end

      attrs << {
        installment_no: idx + 1,
        due_on: due_on,
        opening_principal: opening.round(2),
        scheduled_emi: scheduled.round(2),
        interest_amount: interest.round(2),
        principal_amount: principal_part.round(2),
        closing_principal: closing.round(2),
        applicable_interest_rate: applicable.round(4),
        status: status,
        paid_on: paid_on,
        actual_paid_amount: actual
      }
    end

    attrs
  end

  def failure(messages)
    Result.new(success?: false, created_count: 0, updated_count: 0, errors: Array(messages))
  end
end
