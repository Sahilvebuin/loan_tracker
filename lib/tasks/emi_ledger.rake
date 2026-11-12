# frozen_string_literal: true

namespace :emi do
  desc "Backfill loan_payments + monthly snapshots from schedules/deductions/prepayments"
  task ledger: :environment do
    scope = Loan.all
    scope = scope.where(id: ENV["LOAN_ID"]) if ENV["LOAN_ID"].present?

    scope.find_each do |loan|
      if loan.loan_emi_schedules.none?
        LoanEmiScheduleGenerator.generate!(loan, mode: :full)
      end
      LoanPaymentRecorder.backfill_loan!(loan)
      puts "Loan ##{loan.id} (#{loan.title}): payments=#{loan.loan_payments.count} snapshots=#{loan.loan_monthly_snapshots.count} outstanding=#{loan.ledger_outstanding}"
    end
  end
end
