require 'net/http'

module SyncHelper
  def sync_with_mavens
    config=YAML.load_file('secrets.yml')
    url = URI.parse("#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsList&Fields=Player,RealName,Email")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    data = JSON.parse res.body
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
