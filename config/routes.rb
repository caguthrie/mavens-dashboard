Rails.application.routes.draw do
  resources :players
  root to: 'home#index'
  post '/players/update_all' => 'players#update_all'
  post '/players/deselect_all' => 'players#deselect_all'

  get '/sync' => 'sync#index'
  get '/pairings' => 'pairings#index'
  post '/pairings/action' => 'pairings#action'

  get '/pnl/fetch' => 'pnl#fetch'
  get '/pnl' => 'pnl#index'
  get '/pnl/daily' => 'pnl#daily'
  get '/pnl/monthly' => 'pnl#monthly'
  get '/pnl/yearly' => 'pnl#yearly'
  get '/pnl/transfer' => 'pnl#transfer'
  get '/pnl/calculate' => 'pnl#calculate'
  post '/pnl/transfer' => 'pnl#make_transfer'
end
