# frozen_string_literal: true

class CreateLoanLedgerTables < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_payments do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :loan_emi_schedule, foreign_key: true
      t.date :paid_on, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :principal_amount, precision: 15, scale: 2, null: false, default: 0
      t.decimal :interest_amount, precision: 15, scale: 2, null: false, default: 0
      t.decimal :charges_amount, precision: 15, scale: 2, null: false, default: 0
      t.string :payment_type, null: false
      t.string :reference_number
      t.text :notes
      t.decimal :balance_before, precision: 15, scale: 2
      t.decimal :balance_after, precision: 15, scale: 2
      t.string :status, null: false, default: "posted"
      t.bigint :reversed_payment_id
      t.references :prepayment, foreign_key: true
      t.references :emi_deduction, foreign_key: true

      t.timestamps
    end

    add_index :loan_payments, [ :loan_id, :paid_on ]
    add_index :loan_payments, [ :loan_id, :payment_type ]
    add_index :loan_payments, [ :loan_id, :status ]
    add_foreign_key :loan_payments, :loan_payments, column: :reversed_payment_id

    create_table :loan_payment_allocations do |t|
      t.references :loan_payment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :ownership_percent, precision: 5, scale: 2
      t.decimal :contribution_percent, precision: 5, scale: 2

      t.timestamps
    end

    add_index :loan_payment_allocations, [ :loan_payment_id, :user_id ], unique: true, name: "index_loan_payment_allocations_on_payment_and_user"

    create_table :loan_monthly_snapshots do |t|
      t.references :loan, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :opening_balance, precision: 15, scale: 2, null: false
      t.decimal :emi_paid, precision: 15, scale: 2, null: false, default: 0
      t.decimal :principal_paid, precision: 15, scale: 2, null: false, default: 0
      t.decimal :interest_paid, precision: 15, scale: 2, null: false, default: 0
      t.decimal :prepayment, precision: 15, scale: 2, null: false, default: 0
      t.decimal :charges, precision: 15, scale: 2, null: false, default: 0
      t.decimal :total_paid, precision: 15, scale: 2, null: false, default: 0
      t.decimal :closing_balance, precision: 15, scale: 2, null: false
      t.decimal :interest_rate, precision: 6, scale: 4
      t.integer :remaining_months

      t.timestamps
    end

    add_index :loan_monthly_snapshots, [ :loan_id, :year, :month ], unique: true

    create_table :loan_audit_entries do |t|
      t.references :loan, foreign_key: true
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.string :action, null: false
      t.jsonb :old_values, null: false, default: {}
      t.jsonb :new_values, null: false, default: {}
      t.text :reason
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :loan_audit_entries, [ :auditable_type, :auditable_id ]
    add_index :loan_audit_entries, [ :loan_id, :created_at ]

    # Prepayment impact fields (keep legacy table; ledger is source of truth)
    change_table :prepayments, bulk: true do |t|
      t.decimal :principal_reduction, precision: 15, scale: 2
      t.decimal :charges, precision: 15, scale: 2, default: 0
      t.decimal :balance_before, precision: 15, scale: 2
      t.decimal :balance_after, precision: 15, scale: 2
      t.string :reference_number
      t.string :reason
    end
  end
end
