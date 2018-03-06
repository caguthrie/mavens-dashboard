class CreateBalances < ActiveRecord::Migration[5.0]
  def change
    create_table :balances do |t|
      t.string :username
      t.date :date
      t.integer :balance
      t.integer :transfer
      t.boolean :zeroed_out

      t.references :player, foreign_key: true
      t.timestamps
    end
  end
end
