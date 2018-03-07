class HomeController < ApplicationController
  def index
    @latest_date = Pnl.order('date DESC').limit(1).first.date
  end
end
