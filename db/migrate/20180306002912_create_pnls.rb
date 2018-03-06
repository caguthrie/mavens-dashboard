class CreatePnls < ActiveRecord::Migration[5.0]
  def change
    create_table :pnls do |t|
      t.integer :amount
      t.string :username
      t.date :date

      t.references :player, foreign_key: true
      t.timestamps
    end
  end
end
