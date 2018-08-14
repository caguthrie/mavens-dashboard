load 'http_request.rb'

# Ban restricted players if their balance is under their limit
Thread.new do
  interval = 30.seconds
  config=YAML.load_file('secrets.yml')

  while true do
    begin
      restricted_players = Player.where(restricted: true)
      connections_url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=ConnectionsList&Fields=SessionID,Player"
      connections_data = HttpRequest.get connections_url
      logged_in_restricted_players = restricted_players.select{|player| connections_data["Player"].include? player.username}
      logged_in_restricted_players.each do |player|
        player_data_url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsGet&Player=#{player.username}"
        player_data = HttpRequest.get player_data_url
        if player_data["Balance"] < player.limit
          ban_url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=BlacklistAdd&Player=#{player.username}"
          ban_data = HttpRequest.get ban_url
          terminate_url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=ConnectionsTerminate&SessionID=#{player_data['SessionID']}"
          terminate_data = HttpRequest.get terminate_url
          if terminate_data["Result"] == "Ok" && ban_data["Result"] == "Ok"
            puts "Banned #{player.username} !"
            PlayerMailer.ban_email(player.username).deliver!
          else
            puts "Failed to ban #{player.username} !"
            PlayerMailer.ban_failed_email(player.username).deliver!
          end
        end
      end
    rescue Exception => e
        puts e
    end
    sleep(interval)
  end
end
