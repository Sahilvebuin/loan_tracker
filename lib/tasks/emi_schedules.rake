# frozen_string_literal: true

namespace :emi do
  desc "Generate/backfill permanent EMI schedules for all loans (or LOAN_ID=)"
  task schedules: :environment do
    scope = Loan.all
    scope = scope.where(id: ENV["LOAN_ID"]) if ENV["LOAN_ID"].present?

    mode = (ENV["MODE"].presence || "full").to_sym
    as_of = ENV["AS_OF"].present? ? Date.parse(ENV["AS_OF"]) : Date.current

    scope.find_each do |loan|
      result = LoanEmiScheduleGenerator.generate!(loan, mode: mode, as_of: as_of)
      if result.success?
        puts "Loan ##{loan.id} (#{loan.title}): created=#{result.created_count} updated=#{result.updated_count} total=#{loan.loan_emi_schedules.count}"
      else
        warn "Loan ##{loan.id} FAILED: #{result.errors.join(', ')}"
      end
    end
  end
end
