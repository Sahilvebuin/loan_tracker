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

ActiveRecord::Schema[8.1].define(version: 2026_04_07_080000) do
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

  create_table "loans", force: :cascade do |t|
    t.decimal "annual_interest_rate", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.decimal "principal", precision: 15, scale: 2, null: false
    t.date "start_date", null: false
    t.integer "term_months", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "start_date"], name: "index_loans_on_user_id_and_start_date"
    t.index ["user_id"], name: "index_loans_on_user_id"
  end

  create_table "prepayments", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "loan_id", null: false
    t.text "notes"
    t.date "paid_on", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id", "paid_on"], name: "index_prepayments_on_loan_id_and_paid_on"
    t.index ["loan_id"], name: "index_prepayments_on_loan_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "loans", "users"
  add_foreign_key "prepayments", "loans"
end
