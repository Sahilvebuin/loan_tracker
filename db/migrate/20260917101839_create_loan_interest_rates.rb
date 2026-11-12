# frozen_string_literal: true

class CreateLoanInterestRates < ActiveRecord::Migration[8.1]
  def up
    create_table :loan_interest_rates do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :interest_rate, precision: 6, scale: 4, null: false
      t.date :effective_from, null: false
      t.date :effective_to
      t.text :remarks

      t.timestamps
    end

    add_index :loan_interest_rates, [ :loan_id, :effective_from ]
    add_index :loan_interest_rates, [ :loan_id, :effective_to ]

    say_with_time "Backfill interest rate history from loans.annual_interest_rate" do
      execute <<~SQL.squish
        INSERT INTO loan_interest_rates (
          loan_id, interest_rate, effective_from, effective_to, remarks, created_at, updated_at
        )
        SELECT
          id,
          annual_interest_rate,
          COALESCE(emi_start_date, start_date),
          NULL,
          'Initial rate from loan master (Phase 3 backfill)',
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        FROM loans
        WHERE NOT EXISTS (
          SELECT 1 FROM loan_interest_rates lir WHERE lir.loan_id = loans.id
        )
      SQL
    end
  end

  def down
    drop_table :loan_interest_rates
  end
end
