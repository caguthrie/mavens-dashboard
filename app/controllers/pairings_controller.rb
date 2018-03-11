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
end
