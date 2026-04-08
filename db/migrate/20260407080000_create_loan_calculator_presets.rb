class CreateLoanCalculatorPresets < ActiveRecord::Migration[8.1]
  def change
    create_table :loan_calculator_presets do |t|
      t.string :key, null: false
      t.decimal :principal, precision: 15, scale: 2
      t.decimal :annual_interest_rate, precision: 6, scale: 2
      t.integer :term_months
      t.integer :amount_slider_max

      t.timestamps
    end

    add_index :loan_calculator_presets, :key, unique: true
  end
end
