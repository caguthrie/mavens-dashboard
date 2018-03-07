class PnlController < ApplicationController
  def index
    latest_date = Pnl.order('date DESC').limit(1).first.date
    redirect_to "/pnl/daily?year=#{latest_date.year}&month=#{latest_date.month}"
  end

  def daily
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
    raw_data = Pnl.where("cast(strftime('%Y', date) as int) = ?", params[:year].to_i)
    grouped_dates = raw_data.group_by {|d| d.date.beginning_of_month }
    @headers = grouped_dates.map{|k,v| k}.sort
    grouped_by_plaer_and_month = ActiveRecord::Base.connection.execute(
        "Select player_id, sum(amount) as amount, strftime('%m', date) as month " +
        "from pnls group by strftime('%m', date), player_id"
    )

    @rows = []
    grouped_by_plaer_and_month.group_by{|r| r['player_id']}.reject{|k,v| v.all?{|item| item['amount'] == 0}}.each do |player_id, grouped_amount_and_dates|
      player = Player.find(player_id)
      ret = {}
      ret['player'] = player
      grouped_amount_and_dates.each do |item|
        ret[item['month']] = item
      end
      @rows.push ret
    end
    @rows.sort!{|a, b| a['player'].real_name <=> b['player'].real_name}
  end

  def yearly
    raw_data = Pnl.all
    grouped_dates = raw_data.group_by {|d| d.date.beginning_of_year }
    @headers = grouped_dates.map{|k,v| k}.sort
    grouped_by_plaer_and_month = ActiveRecord::Base.connection.execute(
        "Select player_id, sum(amount) as amount, strftime('%Y', date) as year " +
            "from pnls group by strftime('%Y', date), player_id"
    )

    @rows = []
    grouped_by_plaer_and_month.group_by{|r| r['player_id']}.reject{|k,v| v.all?{|item| item['amount'] == 0}}.each do |player_id, grouped_amount_and_dates|
      player = Player.find(player_id)
      ret = {}
      ret['player'] = player
      grouped_amount_and_dates.each do |item|
        ret[item['year']] = item
      end
      @rows.push ret
    end
    @rows.sort!{|a, b| a['player'].real_name <=> b['player'].real_name}
  end

  def fetch
    helpers.fetch_and_save_balances
  end
end
