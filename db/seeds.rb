# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# EMI is auto-debited from each brother's account on the 15th at 00:01 (see LoanEmiAutopayJob / config/recurring.yml).
# Remaining principal comes ONLY from those EMI debits — no lump prepayments.

def seed_emi_debits_through!(loan, user, as_of: Date.current)
  helper = Class.new { include CalculatorHelper }.new
  # Original terms until the revision, then the bank-revised EMI (see LOAN_REVISIONS).
  rows = helper.loan_schedule_rows(loan)

  rows.each do |row|
    due_on = Date.new(row[:calendar_year], row[:month], CalculatorHelper::EMI_PAY_DAY)
    next if due_on > as_of

    amount = row[:total_paid].to_d
    next if amount <= 0
    next if loan.emi_deductions.exists?(due_on: due_on)

    loan.emi_deductions.create!(due_on: due_on, amount: amount)
    user.update!(account_balance: user.account_balance.to_d - amount)
  end
end

SHARED_HOME_LOAN = {
  principal: 2_637_592.17,
  annual_interest_rate: 7.70,
  term_months: 165,
  start_date: Date.new(2026, 3, 16),
  loan_type: "home",
  interest_rate_type: "fixed",
  status: "active",
  notes: "Home loan · ~₹26,37,592 sanctioned · EMI on 15th each month. " \
         "Revised Nov 2026 (repo +0.25%): 7.95%, EMI ₹26,310 (₹52,620 combined), 159 months."
}.freeze

SHARED_ADDITIONAL_LOAN = {
  principal: 493_615.07,
  annual_interest_rate: 7.55,
  term_months: 172,
  start_date: Date.new(2026, 3, 16),
  loan_type: "additional",
  interest_rate_type: "fixed",
  status: "active",
  notes: "Additional home loan · ~₹4,93,615 sanctioned · EMI on 15th each month. " \
         "Revised Nov 2026 (repo +0.25%): 7.80%, EMI ₹4,790 (₹9,580 combined), 164 months."
}.freeze

# Bank-revised terms after the repo rate hike of 0.25% (effective after the 15 Oct 2026 EMI).
# Bank figures are combined for both brothers; each brother's loan carries half.
# No prepayments by either brother — outstanding comes only from EMIs.
#   Home:       ₹51,44,625 @ 7.95% · EMI ₹52,620 · 159 months
#   Additional: ₹9,64,377  @ 7.80% · EMI ₹9,580  · 164 months
REPO_HIKE_EFFECTIVE_FROM = Date.new(2026, 10, 16) # first EMI on new terms: 15 Nov 2026

LOAN_REVISIONS = {
  "Home Loan" => [
    {
      effective_from: REPO_HIKE_EFFECTIVE_FROM,
      interest_rate: 7.95,
      emi_amount: 52_620 / 2.0,
      opening_principal: 5_144_625 / 2.0,
      remaining_months: 159,
      remarks: "Repo rate +0.25% · bank revised: ₹51,44,625 combined @ 7.95%, EMI ₹52,620 combined, 159 months"
    }
  ],
  "Additional Home Loan" => [
    {
      effective_from: REPO_HIKE_EFFECTIVE_FROM,
      interest_rate: 7.80,
      emi_amount: 9_580 / 2.0,
      opening_principal: 964_377 / 2.0,
      remaining_months: 164,
      remarks: "Repo rate +0.25% · bank revised: ₹9,64,377 combined @ 7.80%, EMI ₹9,580 combined, 164 months"
    }
  ]
}.freeze

def ensure_loan_master_side_records!(loan)
  loan.send(:apply_master_defaults)
  loan.save! if loan.changed?

  # Rebuilt every run: initial rate, then each bank revision (keeps loan rate / EMI in sync).
  loan.loan_interest_rates.destroy_all
  loan.loan_interest_rates.create!(
    interest_rate: loan.annual_interest_rate,
    effective_from: loan.emi_start_date || loan.start_date,
    effective_to: nil,
    remarks: "Initial rate"
  )
  LOAN_REVISIONS.fetch(loan.title, []).each do |rev|
    result = LoanInterestRateService.change!(loan: loan, **rev)
    raise "Rate revision failed for #{loan.title}: #{result.errors.join(', ')}" unless result.success?
  end
  loan.reload

  unless loan.loan_borrowers.exists?(user_id: loan.user_id)
    loan.loan_borrowers.create!(
      user_id: loan.user_id,
      role: "primary",
      ownership_percent: 100
    )
  end
end

brother_specs = [
  { email: "brother1@example.com", name: "Sahil" },
  { email: "brother2@example.com", name: "Sanket" }
]

brothers = brother_specs.map do |spec|
  user = User.find_or_initialize_by(email: spec[:email])
  user.name = spec[:name]
  user.password = "password"
  user.password_confirmation = "password"
  user.account_balance = 10_000_000
  user.save!
  user
end

brothers.each do |user|
  loan = Loan.find_or_initialize_by(user: user, title: "Home Loan")
  loan.assign_attributes(SHARED_HOME_LOAN.merge(emi_amount: nil))
  loan.save!
  ensure_loan_master_side_records!(loan)
  loan.loan_payments.destroy_all # ledger references deductions/prepayments; rebuilt by backfill below
  loan.prepayments.destroy_all
  loan.emi_deductions.destroy_all
  seed_emi_debits_through!(loan, user, as_of: Date.current)
  LoanEmiScheduleGenerator.generate!(loan, mode: :full, as_of: Date.current)
  LoanPaymentRecorder.backfill_loan!(loan)
end

brothers.each do |user|
  loan = Loan.find_or_initialize_by(user: user, title: "Additional Home Loan")
  loan.assign_attributes(SHARED_ADDITIONAL_LOAN.merge(emi_amount: nil))
  loan.save!
  ensure_loan_master_side_records!(loan)
  loan.loan_payments.destroy_all # ledger references deductions/prepayments; rebuilt by backfill below
  loan.prepayments.destroy_all
  loan.emi_deductions.destroy_all
  seed_emi_debits_through!(loan, user, as_of: Date.current)
  LoanEmiScheduleGenerator.generate!(loan, mode: :full, as_of: Date.current)
  LoanPaymentRecorder.backfill_loan!(loan)
end

LoanCalculatorPreset.find_or_initialize_by(key: "home").tap do |p|
  p.principal = SHARED_HOME_LOAN[:principal]
  p.annual_interest_rate = LOAN_REVISIONS["Home Loan"].last[:interest_rate]
  p.term_months = SHARED_HOME_LOAN[:term_months]
  p.amount_slider_max = 20_000_000
  p.save!
end

LoanCalculatorPreset.find_or_initialize_by(key: "additional").tap do |p|
  p.principal = SHARED_ADDITIONAL_LOAN[:principal]
  p.annual_interest_rate = LOAN_REVISIONS["Additional Home Loan"].last[:interest_rate]
  p.term_months = SHARED_ADDITIONAL_LOAN[:term_months]
  p.amount_slider_max = 5_000_000
  p.save!
end

puts "Seeded #{User.count} users, #{Loan.count} loans, #{EmiDeduction.count} EMI debits, #{LoanEmiSchedule.count} schedule rows, #{LoanPayment.count} payments, #{LoanMonthlySnapshot.count} snapshots (through #{Date.current})."
