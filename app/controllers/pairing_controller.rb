class PairingController < ApplicationController
  def index
    helpers.make_pairings
    redirect_to :root
  end
end
