class PnlController < ApplicationController
  def daily
    # TODO this should accepts some url params when denote the year and month
    # Query for that year and month
  end

  def monthly
    # TODO this should accepts some url params when denote the year
    # Group by month
  end

  def yearly
    # Group by month
  end

  def export
    # Generic table export. Keep data structures between periods consistent
  end

  def fetch
    helpers.fetch_and_save_balances
  end
end
