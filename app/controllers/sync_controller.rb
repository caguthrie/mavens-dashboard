class SyncController < ApplicationController
  def index
    helpers.sync_with_mavens
    redirect_to :root
  end
end
