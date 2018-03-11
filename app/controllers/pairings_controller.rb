load 'http_request.rb'

class PairingsController < ApplicationController
  def index
    helpers.sync_with_mavens
    result = helpers.make_pairings
    if result.is_a? String
      @result = result
      render 'balances_off'
    else
      @all_pairings = result[:all_pairings]
      @to_aggregate = result[:to_aggregate]
      @from_aggregate = result[:from_aggregate]
      @collect_at_game = result[:collect_at_game]
    end
  end

  def action
    config=YAML.load_file('secrets.yml')
    pairings = JSON.parse params[:pairings]

    # Reset next p/l generation in the database
    latest_balance_date = Balance.order('date DESC').limit(1).first.date
    Balance.where(date: latest_balance_date).each do |balance|
      balance.update(zeroed_out: true)
    end

    pairings.each do |pairing|
      # Fire off emails to everyone
      # PlayerMailer.pairing_email(pairing).deliver!

      # Adjust balances with mavens API
      pairing['from'].each do |from|
        # url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsIncBalance&Player=#{from['username']}&Amount=#{from['amount']}"
        # data = HttpRequest.get url
        puts "Increment $#{from['amount']} from #{from['username']}'s balance'"
      end

      pairing['to'].each do |to|
        # url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsDecBalance&Player=#{to['username']}&Amount=#{to['amount']}"
        # data = HttpRequest.get url
        puts "Decrement $#{to['amount']} from #{to['username']}'s balance'"
      end
    end

  end
end
