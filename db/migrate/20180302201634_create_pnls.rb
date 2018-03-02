class CreatePnls < ActiveRecord::Migration[5.0]
  def change
    create_table :pnls do |t|
      t.string :username
      t.date :date
      t.integer :balance
      t.integer :transfer

      t.timestamps
    end
  end
end
