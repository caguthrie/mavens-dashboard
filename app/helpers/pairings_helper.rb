require 'net/http'
load 'http_request.rb'

module PairingsHelper
  def make_pairings
    config=YAML.load_file('secrets.yml')
    all_pairings = []
    from_aggregate = {}
    to_aggregate = {}
    url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsList&Fields=Player,RingChips,RegChips,Balance"
    data = HttpRequest.get url

    if data['Balance'].reduce(:+) + data['RegChips'].reduce(:+) + data['RingChips'].reduce(:+) != 0
      return "Can't do pairings. Balances off by #{data['Balance'].reduce(:+) + data['RegChips'].reduce(:+) + data['RingChips'].reduce(:+)}"
    end

    # Get a list of objects with player and balance properties
    player_balances = data['Player'].each_with_index.map do |username, i|
      {
          player: Player.find_by(username: username),
          balance: data['Balance'][i] + data['RegChips'][i] + data['RingChips'][i],
          username: username
      }
    end

    player_balances.each do |pb|
      if pb[:balance] > 0
        to_aggregate[pb[:username]] = {balance: pb[:balance], from: []}
      elsif pb[:balance] < 0
        from_aggregate[pb[:username]] = {balance: pb[:balance], to: []}
      end
    end
    # Exclude zeros and sort by largest absolute value
    non_zeros = player_balances.select{|player_balance| player_balance[:balance] != 0}
    non_zeros.sort! do |a, b|
      b[:balance].abs <=> a[:balance].abs
    end

    priority_players = ['Chrisman', 'Riclesb']

    pb_not_going_to_game = non_zeros.select{|player_balance| !player_balance[:player].going_to_game}
    pb_going_to_game = non_zeros.select{|player_balance| player_balance[:player].going_to_game && !priority_players.include?(player_balance[:player].username)}
    pb_going_to_game_priority = non_zeros.select{|player_balance| player_balance[:player].going_to_game && priority_players.include?(player_balance[:player].username)}

    # This loop deals with friends first
    pb_not_going_to_game.size.times do |i|
      pb1 = pb_not_going_to_game[i]
      type = 'winner'

      if pb1[:balance] < 0
        type = 'loser'
      end
      player_pairing = {player: pb1[:player], amount: 0, username: pb1[:username]}
      pairing = {
          to: [],
          from: []
      }

      # Pair off against friends
      pair_off(pb1, pb_not_going_to_game.select{|pb2| pb1[:player].friends.include? pb2[:player]}, player_pairing, pairing)

      if type == 'winner'
        pairing[:to].push player_pairing
      else
        pairing[:from].push player_pairing
      end

      # If no pairing, go to next
      next if pairing[:to].length == 0 || pairing[:from].length == 0

      # Crazy logic to get some data models that actually make the view easy to work with
      if pairing[:to].length == 1
        pairing[:from].each do |pb_from|
          to_aggregate[pairing[:to][0][:username]][:from].push(pb_from)
          from_aggregate[pb_from[:username]][:to].push({username: pairing[:to][0][:username], player: pairing[:to][0][:player], amount: pb_from[:amount]})
        end
      elsif pairing[:from].length == 1
        pairing[:to].each do |pb_to|
          from_aggregate[pairing[:from][0][:username]][:to].push(pb_to)
          to_aggregate[pb_to[:username]][:from].push({username: pairing[:from][0][:username], player: pairing[:from][0][:player], amount: pb_to[:amount]})
        end
      end

      all_pairings.push pairing
    end

    # This loop deals with non-friends
    loop do
      # Re-sort players not going to the game
      pb_not_going_to_game.sort! do |a, b|
        a[:balance].abs <=> b[:balance].abs
      end

      pb1 = pb_not_going_to_game.find{|p| p[:balance] != 0 }

      unless pb1
        break
      end

      type = 'winner'

      if pb1[:balance] < 0
        type = 'loser'
      end
      player_pairing = {player: pb1[:player], amount: 0, username: pb1[:username]}
      pairing = {
          to: [],
          from: []
      }

      # Pair off against everyone else not going to the game
      pair_off(pb1, pb_not_going_to_game, player_pairing, pairing)

      # Pair off against people coming to the game
      pair_off(pb1, pb_going_to_game, player_pairing, pairing)

      # Pair off against priority people coming to the game if there is anything left
      pair_off(pb1, pb_going_to_game_priority, player_pairing, pairing)

      if type == 'winner'
        pairing[:to].push player_pairing
      else
        pairing[:from].push player_pairing
      end

      # If no pairing, go to next
      next if pairing[:to].length == 0 || pairing[:from].length == 0

      # Crazy logic to get some data models that actually make the view easy to work with
      if pairing[:to].length == 1
        pairing[:from].each do |pb_from|
          to_aggregate[pairing[:to][0][:username]][:from].push(pb_from)
          from_aggregate[pb_from[:username]][:to].push({username: pairing[:to][0][:username], player: pairing[:to][0][:player], amount: pb_from[:amount]})
        end
      elsif pairing[:from].length == 1
        pairing[:to].each do |pb_to|
          from_aggregate[pairing[:from][0][:username]][:to].push(pb_to)
          to_aggregate[pb_to[:username]][:from].push({username: pairing[:from][0][:username], player: pairing[:from][0][:player], amount: pb_to[:amount]})
        end
      end

      all_pairings.push pairing
    end

    collect_at_game = pb_going_to_game.concat(pb_going_to_game_priority).select{|pb| pb[:balance] != 0}
    {
      all_pairings: all_pairings,
      to_aggregate: to_aggregate,
      from_aggregate: from_aggregate,
      collect_at_game: collect_at_game
    }
  end

  def pair_off(pb1, list_of_hopefuls, player_pairing, pairing)
    list_of_hopefuls.each do |pb2|
      # If player 1 is a winner and we found a loser with a whole balance to match
      if pb1[:balance] > 0 && pb2[:balance] < 0 && pb1[:balance].abs > pb2[:balance].abs
        player_pairing[:amount] = player_pairing[:amount] + pb2[:balance].abs
        pairing[:from].push({player: pb2[:player], amount: pb2[:balance].abs, username: pb2[:player].username})
        pb1[:balance] = pb1[:balance] + pb2[:balance]
        pb2[:balance] = 0
      # If player 1 is a loser and we found a winner with a whole balance to match
      elsif pb1[:balance] < 0 && pb2[:balance] > 0 && pb1[:balance].abs > pb2[:balance].abs
        player_pairing[:amount] = player_pairing[:amount] + pb2[:balance]
        pairing[:to].push({player: pb2[:player], amount: pb2[:balance], username: pb2[:player].username})
        pb1[:balance] = pb1[:balance] + pb2[:balance]
        pb2[:balance] = 0
      # If player 1 is a winner and we found a loser with a larger balance to match
      elsif pb1[:balance] > 0 && pb2[:balance] < 0
        player_pairing[:amount] = player_pairing[:amount] + pb1[:balance]
        pairing[:from].push({player: pb2[:player], amount: pb1[:balance], username: pb2[:player].username})
        pb2[:balance] = pb2[:balance] + pb1[:balance]
        pb1[:balance] = 0
      # If player 1 is a loser and we found a winner with a larger balance to match
      elsif pb1[:balance] < 0 && pb2[:balance] > 0
        player_pairing[:amount] = player_pairing[:amount] + pb1[:balance].abs
        pairing[:to].push({player: pb2[:player], amount: pb1[:balance].abs, username: pb2[:player].username})
        pb2[:balance] = pb2[:balance] + pb1[:balance]
        pb1[:balance] = 0
      end
    end
  end
end
