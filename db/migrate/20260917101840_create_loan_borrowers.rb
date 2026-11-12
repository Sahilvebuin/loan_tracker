# frozen_string_literal: true

class CreateLoanBorrowers < ActiveRecord::Migration[8.1]
  def up
    create_table :loan_borrowers do |t|
      t.references :loan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "primary"
      t.decimal :ownership_percent, precision: 5, scale: 2, null: false, default: 100

      t.timestamps
    end

    add_index :loan_borrowers, [ :loan_id, :user_id ], unique: true
    add_index :loan_borrowers, [ :loan_id, :role ]

    say_with_time "Backfill primary borrower from loans.user_id" do
      execute <<~SQL.squish
        INSERT INTO loan_borrowers (
          loan_id, user_id, role, ownership_percent, created_at, updated_at
        )
        SELECT
          id,
          user_id,
          'primary',
          100,
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        FROM loans
        WHERE NOT EXISTS (
          SELECT 1 FROM loan_borrowers lb WHERE lb.loan_id = loans.id AND lb.user_id = loans.user_id
        )
      SQL
    end
  end

  def down
    drop_table :loan_borrowers
  end
end
