Rails.application.routes.draw do
  resources :players
  root to: 'home#index'
  post '/players/update_all' => 'players#update_all'
  post '/players/deselect_all' => 'players#deselect_all'

  get '/sync' => 'sync#index'
  get '/pairings' => 'pairings#index'
end
