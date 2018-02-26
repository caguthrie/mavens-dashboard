class PairingsController < ApplicationController
  def index
    result = helpers.make_pairings
    @all_pairings = result[:all_pairings]
    @to_aggregate = result[:to_aggregate]
    @from_aggregate = result[:from_aggregate]
  end
end
