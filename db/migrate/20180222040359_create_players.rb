class CreatePlayers < ActiveRecord::Migration[5.0]
  def change
    create_table :players do |t|
      t.string :real_name
      t.string :username
      t.string :email
      t.boolean :going_to_game

      t.timestamps
    end
  end
end
