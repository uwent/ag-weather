Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :evapotranspirations, only: [:show, :index] do
    collection do
      get 'all_for_date'
    end
  end
  resources :weather, only: [:index]
  resources :insolations, only: [:show]

  resources :degree_days, only: [:show, :index]

  resources :stations, only: [:index]
  resources :station_observations, only: [:index]
  resources :pest_forecasts, only: [:index] do
    collection do
      get 'point_details'
      get 'custom'
      get 'custom_point_details'
    end
  end
  get '/calculate_et', to: 'evapotranspirations#calculate_et'
end
