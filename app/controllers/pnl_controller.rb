load 'http_request.rb'

class PnlController < ApplicationController
  def index
    latest_date = Pnl.order('date DESC').limit(1).first.date
    redirect_to "/pnl/daily?year=#{latest_date.year}&month=#{latest_date.month}"
  end

  def transfer
    @players = Player.all.sort{|a,b| a.real_name <=> b.real_name}
  end

  def make_transfer
    config=YAML.load_file('secrets.yml')
    from = Player.find(params[:from][:id])
    to = Player.find(params[:to][:id])
    amount = params[:amount].to_i
    to_balance = Balance.where(player: to).order(:date).last
    from_balance = Balance.where(player: from).order(:date).last
    if amount == 0
      redirect_to '/pnl/transfer', notice: "Please enter an amount."
    elsif to_balance && from_balance
      to_transfer_amount = to_balance.transfer ? to_balance.transfer + amount : amount

      url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsIncBalance&Player=#{to.username}&Amount=#{amount}"
      data = HttpRequest.get url
      # TODO something to verify this actually worked
      to_balance.update transfer: to_transfer_amount

      from_balance_amount = from_balance.transfer ? from_balance.transfer - amount : -amount
      url = "#{config['root']}/api?password=#{config['password']}&JSON=Yes&Command=AccountsDecBalance&Player=#{from.username}&Amount=#{amount}"
      data = HttpRequest.get url
      # TODO something to verify this actually worked
      from_balance.update transfer: from_balance_amount
      redirect_to '/pnl/transfer', notice: "Success! Transferred #{amount} from #{from.real_name} to #{to.real_name}"
    else
      redirect_to '/pnl/transfer', notice: "Nothing done. Cannot find any balances."
    end
  end

  def daily
    raw_data = Pnl.where("cast(strftime('%m', date) as int) = ?", params[:month].to_i).where("cast(strftime('%Y', date) as int) = ?", params[:year].to_i)
    grouped_data = raw_data.group_by{|row| row.username}.delete_if{|k,v| v.all?{|item| item.amount == 0}}
    @month = params[:month].to_i
    @months = ActiveRecord::Base.connection.execute(
        "Select strftime('%m', date) as month " +
            "from pnls " +
            "group by strftime('%m', date)"
    ).map{|d| d['month'].to_i}.uniq.sort
    @year = params[:year]
    @years = ActiveRecord::Base.connection.execute(
        "Select strftime('%Y', date) as year " +
            "from pnls " +
            "group by strftime('%Y', date)"
    ).map{|d| d['year']}
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
    @year = params[:year]
    @years = ActiveRecord::Base.connection.execute(
        "Select strftime('%Y', date) as year " +
            "from pnls " +
            "group by strftime('%Y', date)"
    ).map{|d| d['year']}
    @headers = grouped_dates.map{|k,v| k}.sort
    grouped_by_plaer_and_month = ActiveRecord::Base.connection.execute(
        "Select player_id, sum(amount) as amount, strftime('%m', date) as month " +
        "from pnls " +
        "where cast(strftime('%Y', date) as int) = #{params[:year].to_i} " +
        "group by strftime('%m', date), player_id "
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
