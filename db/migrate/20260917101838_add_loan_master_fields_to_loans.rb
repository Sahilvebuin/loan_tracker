# frozen_string_literal: true

class AddLoanMasterFieldsToLoans < ActiveRecord::Migration[8.1]
  def up
    add_column :loans, :loan_type, :string unless column_exists?(:loans, :loan_type)
    add_column :loans, :lender_name, :string unless column_exists?(:loans, :lender_name)
    add_column :loans, :account_number, :string unless column_exists?(:loans, :account_number)
    add_column :loans, :sanctioned_amount, :decimal, precision: 15, scale: 2 unless column_exists?(:loans, :sanctioned_amount)
    add_column :loans, :disbursed_amount, :decimal, precision: 15, scale: 2 unless column_exists?(:loans, :disbursed_amount)
    add_column :loans, :interest_rate_type, :string, null: false, default: "fixed" unless column_exists?(:loans, :interest_rate_type)
    add_column :loans, :emi_start_date, :date unless column_exists?(:loans, :emi_start_date)
    add_column :loans, :emi_amount, :decimal, precision: 15, scale: 2 unless column_exists?(:loans, :emi_amount)
    add_column :loans, :emi_due_day, :integer, null: false, default: 15 unless column_exists?(:loans, :emi_due_day)
    add_column :loans, :processing_fee, :decimal, precision: 15, scale: 2, null: false, default: 0 unless column_exists?(:loans, :processing_fee)
    add_column :loans, :insurance_amount, :decimal, precision: 15, scale: 2, null: false, default: 0 unless column_exists?(:loans, :insurance_amount)
    add_column :loans, :other_initial_charges, :decimal, precision: 15, scale: 2, null: false, default: 0 unless column_exists?(:loans, :other_initial_charges)
    add_column :loans, :status, :string, null: false, default: "active" unless column_exists?(:loans, :status)
    add_column :loans, :closed_on, :date unless column_exists?(:loans, :closed_on)

    add_index :loans, :status unless index_exists?(:loans, :status)
    add_index :loans, :loan_type unless index_exists?(:loans, :loan_type)
    unless index_exists?(:loans, [ :user_id, :account_number ], name: "index_loans_on_user_id_and_account_number")
      add_index :loans, [ :user_id, :account_number ],
                unique: true,
                where: "account_number IS NOT NULL AND account_number <> ''",
                name: "index_loans_on_user_id_and_account_number"
    end

    say_with_time "Backfill loan master fields from existing principal/rate/term" do
      execute <<~SQL.squish
        UPDATE loans
        SET
          sanctioned_amount = COALESCE(sanctioned_amount, principal),
          disbursed_amount = COALESCE(disbursed_amount, principal),
          loan_type = COALESCE(
            loan_type,
            CASE
              WHEN lower(coalesce(title, '')) LIKE '%additional%' THEN 'additional'
              WHEN lower(coalesce(title, '')) LIKE '%home%' THEN 'home'
              ELSE 'other'
            END
          )
      SQL

      Loan.reset_column_information
      Loan.find_each do |loan|
        emi_start = compute_emi_start_date(loan.start_date, loan.emi_due_day)
        emi = compute_emi(loan.principal, loan.annual_interest_rate, loan.term_months)
        loan.update_columns(
          emi_start_date: loan.emi_start_date || emi_start,
          emi_amount: loan.emi_amount || emi,
          sanctioned_amount: loan.sanctioned_amount || loan.principal,
          disbursed_amount: loan.disbursed_amount || loan.principal
        )
      end
    end
  end

  def down
    remove_index :loans, name: "index_loans_on_user_id_and_account_number", if_exists: true
    remove_index :loans, :loan_type, if_exists: true
    remove_index :loans, :status, if_exists: true

    %i[
      loan_type lender_name account_number sanctioned_amount disbursed_amount
      interest_rate_type emi_start_date emi_amount emi_due_day
      processing_fee insurance_amount other_initial_charges status closed_on
    ].each do |col|
      remove_column :loans, col if column_exists?(:loans, col)
    end
  end

  private

  def compute_emi_start_date(start_date, due_day)
    d = start_date.to_date
    day = due_day.to_i.clamp(1, 28)
    due_this_month = Date.new(d.year, d.month, day)
    if d > due_this_month
      n = d.beginning_of_month + 1.month
      Date.new(n.year, n.month, day)
    else
      due_this_month
    end
  end

  def compute_emi(principal, annual_rate_percent, months)
    p = principal.to_d
    n = months.to_i
    return 0.to_d if n <= 0 || p <= 0

    r = annual_rate_percent.to_d / 12 / 100
    return (p / n).round(2) if r.zero?

    x = (1 + r)**n
    ((p * r * x) / (x - 1)).round(2)
  end
end
