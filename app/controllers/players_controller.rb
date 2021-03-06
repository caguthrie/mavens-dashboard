class PlayersController < ApplicationController
  before_action :set_player, only: [:show, :edit, :update, :destroy]

  # GET /players
  # GET /players.json
  def index
    helpers.sync_with_mavens
    @players = Player.all
  end

  # GET /players/1
  # GET /players/1.json
  def show
  end

  # GET /players/new
  def new
    @player = Player.new
  end

  # GET /players/1/edit
  def edit
  end

  # POST /players
  # POST /players.json
  def create
    @player = Player.new(player_params)

    respond_to do |format|
      if @player.save
        format.html { redirect_to @player, notice: 'Player was successfully created.' }
        format.json { render :show, status: :created, location: @player }
      else
        format.html { render :new }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /players/1
  # PATCH/PUT /players/1.json
  def update
    respond_to do |format|
      if @player.update(player_params)

        # Deal with friends
        new_friend_set = params[:player]['friends'].reject{|s| s.empty?}.map{|friend_id| Player.find(friend_id)}
        this_player = Player.find(params[:id])
        current_friends = this_player.friends
        subtractions = current_friends - new_friend_set
        additions = new_friend_set - current_friends
        subtractions.each{|sub| this_player.friends.destroy sub}
        additions.each{|add| this_player.friends << add}

        format.html { redirect_to @player, notice: 'Player was successfully updated.' }
        format.json { render :show, status: :ok, location: @player }
      else
        format.html { render :edit }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_all
    params.require(:players).permit!.each do |key, value|
      player = Player.find(key.to_i)
      player.going_to_game = value["going_to_game"].to_i
      player.restricted = value["restricted"].to_i
      if player.restricted
        player.limit = (value["limit"] || 0).to_i
      else
        player.limit = nil
      end
      player.save
    end
    redirect_to players_path
  end

  def deselect_all
    Player.all.each do |player|
      player.going_to_game = 0
      player.save
    end
    redirect_to players_path
  end

  # DELETE /players/1
  # DELETE /players/1.json
  def destroy
    @player.destroy
    respond_to do |format|
      format.html { redirect_to players_url, notice: 'Player was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_params
      params.require(:player).permit(:real_name, :username, :email, :going_to_game)
    end
end
