load 'http_request.rb'
require 'time'

module PnlHelper
  def fetch_and_save_balances
    config = YAML.load_file('secrets.yml')
    url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsList&Fields=Player,RingChips,RegChips,Balance"
    data = HttpRequest.get url
    data['Player'].each_with_index do |username, i|
      bal = Balance.new
      bal.username = username
      bal.balance = data['Balance'][i].to_i + data['RingChips'][i].to_i + data['RegChips'][i].to_i
      bal.date = Date.today
      most_recent_record_for_player = Balance.where(username: username).order('date DESC').limit(1).first

      # Carry over transfer balance if exists
      if most_recent_record_for_player
        bal.transfer = most_recent_record_for_player.transfer
      end

      player = Player.find_by(username: username)
      bal.player = player
      bal.save

      yesterdays_balance = Balance.find_by(username: username, date: (Date.yesterday - 1))

      pnl = Pnl.new
      pnl.username = username
      pnl.player = player
      pnl.date = Date.today

      if yesterdays_balance && !yesterdays_balance.zeroed_out
        pnl.amount = bal.balance - yesterdays_balance.balance
      else
        pnl.amount = bal.balance
      end
      pnl.save
    end
  end
end
