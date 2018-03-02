load 'http_request.rb'
require 'time'

module PnlHelper
  def fetch_and_save_balances
    config = YAML.load_file('secrets.yml')
    url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsList&Fields=Player,RingChips,RegChips,Balance"
    data = HttpRequest.get url
    data['Player'].each_with_index do |player, i|
      pnl = Pnl.new
      pnl.username = player
      pnl.balance = data['Balance'][i].to_i + data['RingChips'][i].to_i + data['RegChips'][i].to_i
      pnl.date = Date.today
      most_recent_record_for_player = Pnl.where(username: player).order('date DESC').limit(1)

      # Carry over transfer balance if exists
      if most_recent_record_for_player
        pnl.transfer = most_recent_record_for_player.transfer
      end

      unless Pnl.find_by(username: player, date: Date.today)
        unless pnl.save!
          # If the save failed, delete all records for this date
          Pnl.where(date: Date.today).delete_all
          raise 'Saving a record failed, rolled back all players for today\'s date'
        end
      end
    end
  end
end
