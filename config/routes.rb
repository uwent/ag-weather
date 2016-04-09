Rails.application.routes.draw do

  resources :evapotranspirations, only: [:show, :index]
  resources :weather, only: [:index]
  resources :insolations, only: [:show]
  resources :degree_days, only: [:show, :index]

  get '/calculate_et', to: 'evapotranspirations#calculate_et'

end
