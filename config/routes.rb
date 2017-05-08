Rails.application.routes.draw do

  resources :evapotranspirations, only: [:show, :index] do
    collection do
      get 'all_for_date'
    end
  end
  resources :weather, only: [:index]
  resources :insolations, only: [:show]

  resources :degree_days, only: [:show, :index]

  resources :pest_forecasts, only: [:index] do
    collection do
      get 'point_details'
    end
  end

  resources :carrot_forecasts, only: [:index] do
    collection do
      get 'info'
    end
  end

  resources :potato_forecasts, only: [:index] do
    collection do
      get 'info'
    end
  end

  get '/calculate_et', to: 'evapotranspirations#calculate_et'
end
