class PnlController < ApplicationController
  def index
  end

  def fetch
    helpers.fetch_and_save_balances
  end
end
