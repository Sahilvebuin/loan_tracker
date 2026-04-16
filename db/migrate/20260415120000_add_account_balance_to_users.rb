class AddAccountBalanceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :account_balance, :decimal, precision: 15, scale: 2, null: false, default: 0
  end
end
