class AddRestrictedAndLimitToPlayers < ActiveRecord::Migration[5.0]
  def change
    add_column :players, :restricted, :boolean
    add_column :players, :limit, :integer
  end
end
