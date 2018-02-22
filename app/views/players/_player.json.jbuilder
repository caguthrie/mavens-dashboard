json.extract! player, :id, :real_name, :username, :email, :going_to_game, :created_at, :updated_at
json.url player_url(player, format: :json)
