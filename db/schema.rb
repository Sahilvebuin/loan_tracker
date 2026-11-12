# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "emi_deductions", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.integer "loan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id", "due_on"], name: "index_emi_deductions_on_loan_id_and_due_on", unique: true
  end

  create_table "loan_audit_entries", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id", null: false
    t.string "auditable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "loan_id"
    t.jsonb "new_values", default: {}, null: false
    t.jsonb "old_values", default: {}, null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_loan_audit_entries_on_auditable_type_and_auditable_id"
    t.index ["loan_id", "created_at"], name: "index_loan_audit_entries_on_loan_id_and_created_at"
    t.index ["loan_id"], name: "index_loan_audit_entries_on_loan_id"
    t.index ["user_id"], name: "index_loan_audit_entries_on_user_id"
  end

  create_table "loan_borrowers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "loan_id", null: false
    t.decimal "ownership_percent", precision: 5, scale: 2, default: "100.0", null: false
    t.string "role", default: "primary", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["loan_id", "role"], name: "index_loan_borrowers_on_loan_id_and_role"
    t.index ["loan_id", "user_id"], name: "index_loan_borrowers_on_loan_id_and_user_id", unique: true
    t.index ["loan_id"], name: "index_loan_borrowers_on_loan_id"
    t.index ["user_id"], name: "index_loan_borrowers_on_user_id"
  end

  create_table "loan_calculator_presets", force: :cascade do |t|
    t.integer "amount_slider_max"
    t.decimal "annual_interest_rate", precision: 6, scale: 3
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.decimal "principal", precision: 15, scale: 2
    t.integer "term_months"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_loan_calculator_presets_on_key", unique: true
  end

  create_table "loan_emi_schedules", force: :cascade do |t|
    t.decimal "actual_paid_amount", precision: 15, scale: 2
    t.decimal "applicable_interest_rate", precision: 6, scale: 4, null: false
    t.decimal "closing_principal", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.integer "installment_no", null: false
    t.decimal "interest_amount", precision: 15, scale: 2, null: false
    t.bigint "loan_id", null: false
    t.decimal "opening_principal", precision: 15, scale: 2, null: false
    t.date "paid_on"
    t.decimal "principal_amount", precision: 15, scale: 2, null: false
    t.decimal "scheduled_emi", precision: 15, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id", "due_on"], name: "index_loan_emi_schedules_on_loan_id_and_due_on", unique: true
    t.index ["loan_id", "installment_no"], name: "index_loan_emi_schedules_on_loan_id_and_installment_no", unique: true
    t.index ["loan_id", "status"], name: "index_loan_emi_schedules_on_loan_id_and_status"
    t.index ["loan_id"], name: "index_loan_emi_schedules_on_loan_id"
  end

  create_table "loan_interest_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.decimal "emi_amount", precision: 15, scale: 2
    t.decimal "interest_rate", precision: 6, scale: 4, null: false
    t.bigint "loan_id", null: false
    t.decimal "opening_principal", precision: 15, scale: 2
    t.integer "remaining_months"
    t.text "remarks"
    t.datetime "updated_at", null: false
    t.index ["loan_id", "effective_from"], name: "index_loan_interest_rates_on_loan_id_and_effective_from"
    t.index ["loan_id", "effective_to"], name: "index_loan_interest_rates_on_loan_id_and_effective_to"
    t.index ["loan_id"], name: "index_loan_interest_rates_on_loan_id"
  end

  create_table "loan_monthly_snapshots", force: :cascade do |t|
    t.decimal "charges", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "closing_balance", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "emi_paid", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "interest_paid", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "interest_rate", precision: 6, scale: 4
    t.bigint "loan_id", null: false
    t.integer "month", null: false
    t.decimal "opening_balance", precision: 15, scale: 2, null: false
    t.decimal "prepayment", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "principal_paid", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "remaining_months"
    t.decimal "total_paid", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["loan_id", "year", "month"], name: "index_loan_monthly_snapshots_on_loan_id_and_year_and_month", unique: true
    t.index ["loan_id"], name: "index_loan_monthly_snapshots_on_loan_id"
  end

  create_table "loan_payment_allocations", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "contribution_percent", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "loan_payment_id", null: false
    t.decimal "ownership_percent", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["loan_payment_id", "user_id"], name: "index_loan_payment_allocations_on_payment_and_user", unique: true
    t.index ["loan_payment_id"], name: "index_loan_payment_allocations_on_loan_payment_id"
    t.index ["user_id"], name: "index_loan_payment_allocations_on_user_id"
  end

  create_table "loan_payments", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "balance_after", precision: 15, scale: 2
    t.decimal "balance_before", precision: 15, scale: 2
    t.decimal "charges_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.bigint "emi_deduction_id"
    t.decimal "interest_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.bigint "loan_emi_schedule_id"
    t.bigint "loan_id", null: false
    t.text "notes"
    t.date "paid_on", null: false
    t.string "payment_type", null: false
    t.bigint "prepayment_id"
    t.decimal "principal_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.string "reference_number"
    t.bigint "reversed_payment_id"
    t.string "status", default: "posted", null: false
    t.datetime "updated_at", null: false
    t.index ["emi_deduction_id"], name: "index_loan_payments_on_emi_deduction_id"
    t.index ["loan_emi_schedule_id"], name: "index_loan_payments_on_loan_emi_schedule_id"
    t.index ["loan_id", "paid_on"], name: "index_loan_payments_on_loan_id_and_paid_on"
    t.index ["loan_id", "payment_type"], name: "index_loan_payments_on_loan_id_and_payment_type"
    t.index ["loan_id", "status"], name: "index_loan_payments_on_loan_id_and_status"
    t.index ["loan_id"], name: "index_loan_payments_on_loan_id"
    t.index ["prepayment_id"], name: "index_loan_payments_on_prepayment_id"
  end

  create_table "loans", force: :cascade do |t|
    t.string "account_number"
    t.decimal "annual_interest_rate", precision: 5, scale: 2, null: false
    t.date "closed_on"
    t.datetime "created_at", null: false
    t.decimal "disbursed_amount", precision: 15, scale: 2
    t.decimal "emi_amount", precision: 15, scale: 2
    t.integer "emi_due_day", default: 15, null: false
    t.date "emi_start_date"
    t.decimal "insurance_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.string "interest_rate_type", default: "fixed", null: false
    t.string "lender_name"
    t.string "loan_type"
    t.text "notes"
    t.decimal "other_initial_charges", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "principal", precision: 15, scale: 2, null: false
    t.decimal "processing_fee", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "sanctioned_amount", precision: 15, scale: 2
    t.date "start_date", null: false
    t.string "status", default: "active", null: false
    t.integer "term_months", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["loan_type"], name: "index_loans_on_loan_type"
    t.index ["status"], name: "index_loans_on_status"
    t.index ["user_id", "account_number"], name: "index_loans_on_user_id_and_account_number", unique: true, where: "((account_number IS NOT NULL) AND ((account_number)::text <> ''::text))"
    t.index ["user_id", "start_date"], name: "index_loans_on_user_id_and_start_date"
    t.index ["user_id"], name: "index_loans_on_user_id"
  end

  create_table "prepayments", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "balance_after", precision: 15, scale: 2
    t.decimal "balance_before", precision: 15, scale: 2
    t.decimal "charges", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.integer "loan_id", null: false
    t.text "notes"
    t.date "paid_on", null: false
    t.decimal "principal_reduction", precision: 15, scale: 2
    t.string "reason"
    t.string "reference_number"
    t.datetime "updated_at", null: false
    t.index ["loan_id", "paid_on"], name: "index_prepayments_on_loan_id_and_paid_on"
    t.index ["loan_id"], name: "index_prepayments_on_loan_id"
  end

  create_table "users", force: :cascade do |t|
    t.decimal "account_balance", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "emi_deductions", "loans"
  add_foreign_key "loan_audit_entries", "loans"
  add_foreign_key "loan_audit_entries", "users"
  add_foreign_key "loan_borrowers", "loans"
  add_foreign_key "loan_borrowers", "users"
  add_foreign_key "loan_emi_schedules", "loans"
  add_foreign_key "loan_interest_rates", "loans"
  add_foreign_key "loan_monthly_snapshots", "loans"
  add_foreign_key "loan_payment_allocations", "loan_payments"
  add_foreign_key "loan_payment_allocations", "users"
  add_foreign_key "loan_payments", "emi_deductions"
  add_foreign_key "loan_payments", "loan_emi_schedules"
  add_foreign_key "loan_payments", "loan_payments", column: "reversed_payment_id"
  add_foreign_key "loan_payments", "loans"
  add_foreign_key "loan_payments", "prepayments"
  add_foreign_key "loans", "users"
  add_foreign_key "prepayments", "loans"
end
