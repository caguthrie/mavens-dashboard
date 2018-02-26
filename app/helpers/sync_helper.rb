require 'net/http'
load 'http_request.rb'

module SyncHelper
  def sync_with_mavens
    config=YAML.load_file('secrets.yml')
    url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsList&Fields=Player,RealName,Email"
      data = HttpRequest.get url
    data["Player"].each_with_index do |player, i|
      player_from_db = Player.find_by(username: player)
      if player_from_db
        player_from_db.email = data["Email"][i]
        player_from_db.real_name = data["RealName"][i]
        player_from_db.save
      else
        new_player = Player.new
        new_player.username = player
        new_player.real_name = data["RealName"][i]
        new_player.email = data["Email"][i]
        new_player.going_to_game = false
        new_player.save
      end
    end
  end
end
