# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

SHARED_HOME_LOAN = {
  principal: 2_637_000,
  annual_interest_rate: 7.70,
  term_months: 165,
  start_date: Date.new(2026, 4, 7),
  notes: "Principal ₹26,37,000 · 7.70% p.a. · 165 months — EMI deduction 15th (same as additional loan)."
}.freeze

SHARED_ADDITIONAL_LOAN = {
  principal: 493_693,
  annual_interest_rate: 7.55,
  term_months: 172,
  start_date: Date.new(2026, 4, 7),
  notes: "Principal ₹4,93,693 · 7.55% p.a. · 172 months — EMI deduction 15th (same as home loan)."
}.freeze

brother_specs = [
  { email: "brother1@example.com", name: "Sahil" },
  { email: "brother2@example.com", name: "Sanket" }
]

brothers = brother_specs.map do |spec|
  user = User.find_or_initialize_by(email: spec[:email])
  if user.new_record?
    user.name = spec[:name]
    user.password = "password"
    user.password_confirmation = "password"
    user.save!
  elsif user.name != spec[:name]
    user.update!(name: spec[:name])
  end
  user
end

# Identical home loan on each user (separate rows; same principal, rate, tenure)
brothers.each do |user|
  loan = Loan.find_or_initialize_by(user: user, title: "Home Loan")
  loan.assign_attributes(SHARED_HOME_LOAN)
  loan.save!
end

# Identical additional home loan on each user (separate loan, separate prepayments)
brothers.each do |user|
  loan = Loan.find_or_initialize_by(user: user, title: "Additional Home Loan")
  loan.assign_attributes(SHARED_ADDITIONAL_LOAN)
  loan.save!
end

LoanCalculatorPreset.find_or_initialize_by(key: "home").tap do |p|
  p.principal = SHARED_HOME_LOAN[:principal]
  p.annual_interest_rate = SHARED_HOME_LOAN[:annual_interest_rate]
  p.term_months = SHARED_HOME_LOAN[:term_months]
  p.amount_slider_max = 20_000_000
  p.save!
end

LoanCalculatorPreset.find_or_initialize_by(key: "additional").tap do |p|
  p.principal = SHARED_ADDITIONAL_LOAN[:principal]
  p.annual_interest_rate = SHARED_ADDITIONAL_LOAN[:annual_interest_rate]
  p.term_months = SHARED_ADDITIONAL_LOAN[:term_months]
  p.amount_slider_max = 5_000_000
  p.save!
end
