Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: "application#index"

  resources :degree_days, only: :index do
    collection do
      get "grid"
      get "map"
      get "dd_table"
      get "info"
    end
  end

  resources :evapotranspirations, only: :index do
    collection do
      get "grid"
      get "map"
      get "info"
    end
  end

  resources :insolations, only: :index do
    collection do
      get "grid"
      get "map"
      get "info"
    end
  end

  resources :precips, only: :index do
    collection do
      get "grid"
      get "map"
      get "info"
    end
  end

  resources :pest_forecasts, only: :index do
    collection do
      get "grid"
      get "map"
      # get "pvy"
      get "vegpath"
      get "info"
    end
  end

  resources :weather, only: :index do
    collection do
      get "grid"
      get "map"
      get "forecast"
      get "forecast_nws"
      get "freeze_grid"
      get "info"
    end
  end

  # resources :station_observations, only: [:index]
  # resources :stations, only: [:index]

  # docs_path = File.join(Rails.application.config.relative_url_root.to_s, "docs")
  mount Rswag::Ui::Engine => "/docs"
  mount Rswag::Api::Engine => "/docs"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

end
