class CreateEmiDeductions < ActiveRecord::Migration[8.1]
  def change
    create_table :emi_deductions do |t|
      t.references :loan, null: false, foreign_key: true, index: false
      t.date :due_on, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :emi_deductions, [ :loan_id, :due_on ], unique: true
  end
end
