class HomeController < ApplicationController
  def index
    pnl = Pnl.order('date DESC').limit(1).first
    @latest_date = pnl ? pnl.date : Date.today
  end
end
