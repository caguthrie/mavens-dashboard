require 'net/http'

MINIMUM_BALANCE_THRESHOLD = 100

module PairingHelper
  def make_pairings
    config=YAML.load_file('secrets.yml')
    url = URI.parse("#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsList&Fields=Player,Balance")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    data = JSON.parse res.body

    # Get a list of objects with player and balance properties
    player_balances = data["Player"].each_with_index.map do |username, i|
      {
          player: Player.find_by(username: username),
          balance: data["Balance"][i]
      }
    end
    # Exclude zeros and sort by largest absolute value
    non_zeros = player_balances.select{|player_balance| player_balance[:balance] != 0}
    non_zeros.sort! do |a, b|
      b[:balance].abs <=> a[:balance].abs
    end

    pb_not_going_to_game = non_zeros.select{|player_balance| !player_balance[:player].going_to_game}
    pb_not_going_to_game.each do |pb1|
      next if pb1[:balance].abs < MINIMUM_BALANCE_THRESHOLD

      type = 'winner'

      if pb1[:balance] < 0
        type = 'loser'
      end
      player_pairing = {player: pb1[:player], amount: 0}
      pairing = {
          to: [],
          from: []
      }

      #Pair off against friends first
      pair_off(pb1, pb_not_going_to_game.select{|pb2| pb1[:player].friends.include? pb2[:player]}, player_pairing, pairing)

      #Pair off against everyone else
      pair_off(pb1, pb_not_going_to_game, player_pairing, pairing)

      if type == 'winner'
        pairing[:to].push player_pairing
      else
        pairing[:from].push player_pairing
      end
      PlayerMailer.pairing_email(pairing).deliver!
      puts pairing
    end


  end

  def pair_off(pb1, list_of_hopefuls, player_pairing, pairing)
    list_of_hopefuls.each do |pb2|
      # If player 1 is a winner and we found a loser with a whole balance to match
      if pb1[:balance] > MINIMUM_BALANCE_THRESHOLD && pb2[:balance] < -MINIMUM_BALANCE_THRESHOLD && pb1[:balance].abs > pb2[:balance].abs
        player_pairing[:amount] = player_pairing[:amount] + pb2[:balance].abs
        pairing[:from].push({player: pb2[:player], amount: pb2[:balance].abs})
        pb1[:balance] = pb1[:balance] + pb2[:balance]
        pb2[:balance] = 0
        # If player 1 is a loser and we found a winner with a whole balance to match
      elsif pb1[:balance] < -MINIMUM_BALANCE_THRESHOLD && pb2[:balance] > MINIMUM_BALANCE_THRESHOLD && pb1[:balance].abs > pb2[:balance].abs
        player_pairing[:amount] = player_pairing[:amount] + pb2[:balance]
        pairing[:to].push({player: pb2[:player], amount: pb2[:balance]})
        pb1[:balance] = pb1[:balance] + pb2[:balance]
        pb2[:balance] = 0
        # If player 1 is a winner and we found a loser with a larger balance to match
      elsif pb1[:balance] > MINIMUM_BALANCE_THRESHOLD && pb2[:balance] < -MINIMUM_BALANCE_THRESHOLD
        player_pairing[:amount] = player_pairing[:amount] + pb1[:balance]
        pairing[:from].push({player: pb2[:player], amount: pb1[:balance]})
        pb2[:balance] = pb2[:balance] + pb1[:balance]
        pb1[:balance] = 0
        # If player 1 is a loser and we found a winner with a larger balance to match
      elsif pb1[:balance] < -MINIMUM_BALANCE_THRESHOLD && pb2[:balance] > MINIMUM_BALANCE_THRESHOLD
        player_pairing[:amount] = player_pairing[:amount] + pb1[:balance].abs
        pairing[:to].push({player: pb2[:player], amount: pb1[:balance].abs})
        pb2[:balance] = pb2[:balance] + pb1[:balance]
        pb1[:balance] = 0
      end
    end
  end
end
