class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :principal, null: false, precision: 15, scale: 2
      t.decimal :annual_interest_rate, null: false, precision: 5, scale: 2
      t.integer :term_months, null: false
      t.date :start_date, null: false
      t.string :title
      t.text :notes

      t.timestamps
    end

    add_index :loans, %i[user_id start_date]
  end
end
