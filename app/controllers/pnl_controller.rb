class PnlController < ApplicationController
  def index
    latest_date = Pnl.order('date DESC').limit(1).first.date
    redirect_to "/pnl/daily?year=#{latest_date.year}&month=#{latest_date.month}"
  end

  def daily
    @month = params[:month]
    @year = params[:year]
    raw_data = Pnl.where("cast(strftime('%m', date) as int) = ?", params[:month].to_i).where("cast(strftime('%Y', date) as int) = ?", params[:year].to_i)
    grouped_data = raw_data.group_by{|row| row.username}.delete_if{|k,v| v.all?{|item| item.amount == 0}}
    @headers = raw_data.map{|d| d.date}.uniq.sort
    @rows = grouped_data.map do |username,v|
      ret = {}
      ret['player'] = v[0].player
      v.each do |item|
        ret[item.date] = item
      end
      ret
    end
    @rows = @rows.sort_by{|row| row['player'].real_name}
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
