Rails.application.routes.draw do
  resources :players
  post '/players/update_all' => 'players#update_all'
  post '/players/deselect_all' => 'players#deselect_all'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
