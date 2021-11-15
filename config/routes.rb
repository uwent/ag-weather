Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :degree_days, only: [:index] do
    collection do
      get "info"
    end
  end

  resources :evapotranspirations, only: [:show, :index] do
    collection do
      get "info"
      get "all_for_date"
      get "calculate_et"
    end
  end

  resources :insolations, only: [:show, :index] do
    collection do
      get "info"
      get "all_for_date"
    end
  end

  resources :precips, only: [:show, :index] do
    collection do
      get "info"
      get "all_for_date"
    end
  end

  resources :pest_forecasts, only: [:index] do
    collection do
      get "custom"
      get "point_details"
      get "custom_point_details"
      get "info"
    end
  end

  resources :weather, only: [:show, :index] do
    collection do
      get "info"
      get "all_for_date"
    end
  end

  resources :station_observations, only: [:index]
  resources :stations, only: [:index]

  root to: "application#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "*path", to: redirect("/") unless Rails.env.development?
end
