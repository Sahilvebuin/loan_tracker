# frozen_string_literal: true

class CreateLoanEmiSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_emi_schedules do |t|
      t.references :loan, null: false, foreign_key: true
      t.integer :installment_no, null: false
      t.date :due_on, null: false
      t.decimal :opening_principal, precision: 15, scale: 2, null: false
      t.decimal :scheduled_emi, precision: 15, scale: 2, null: false
      t.decimal :interest_amount, precision: 15, scale: 2, null: false
      t.decimal :principal_amount, precision: 15, scale: 2, null: false
      t.decimal :closing_principal, precision: 15, scale: 2, null: false
      t.decimal :applicable_interest_rate, precision: 6, scale: 4, null: false
      t.string :status, null: false, default: "pending"
      t.date :paid_on
      t.decimal :actual_paid_amount, precision: 15, scale: 2

      t.timestamps
    end

    add_index :loan_emi_schedules, [ :loan_id, :installment_no ], unique: true
    add_index :loan_emi_schedules, [ :loan_id, :due_on ], unique: true
    add_index :loan_emi_schedules, [ :loan_id, :status ]
  end
end
