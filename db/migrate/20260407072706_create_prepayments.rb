class CreatePrepayments < ActiveRecord::Migration[8.1]
  def change
    create_table :prepayments do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :amount, null: false, precision: 15, scale: 2
      t.date :paid_on, null: false
      t.text :notes

      t.timestamps
    end

    add_index :prepayments, %i[loan_id paid_on]
  end
end
