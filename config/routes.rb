Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :degree_days, only: :index do
    collection do
      get "info"
      get "dd_table"
      get "grid"
      get "grid_for"
      get "map"
    end
  end

  resources :evapotranspirations, only: :index do
    collection do
      get "info"
      get "grid"
      get "map"
    end
  end

  resources :insolations, only: :index do
    collection do
      get "info"
      get "grid"
      get "map"
    end
  end

  resources :precips, only: :index do
    collection do
      get "info"
      get "all_for_date"
    end
  end

  resources :pest_forecasts, only: :index do
    collection do
      get "custom"
      get "point_details"
      get "custom_point_details"
      get "pvy"
      get "freeze"
      get "info"
    end
  end

  resources :weather, only: :index do
    collection do
      get "map"
      get "info"
      get "grid"
      get "forecast"
      get "forecast_nws"
      get "freeze_grid"
    end
  end

  resources :station_observations, only: [:index]
  resources :stations, only: [:index]

  root to: "application#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "*path", to: redirect("/") unless Rails.env.development?
end
