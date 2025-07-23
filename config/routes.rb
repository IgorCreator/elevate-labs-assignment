Rails.application.routes.draw do
  root to: redirect("/admin")

  namespace :api do
    post "user", to: "users#create"
    post "sessions", to: "sessions#create"
    get "user", to: "users#show"
    post "user/game_events", to: "game_events#create"
  end

  # Admin routes
  namespace :admin do
    get "/", to: "dashboard#index"

    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    post "logout", to: "sessions#destroy"

    resources :users, only: [ :index, :show, :new, :create, :edit ] do
      member do
        post :update
        post :destroy
        post :refresh_subscription
        post :clear_subscription_cache
      end
    end
    resources :game_events, only: [ :index, :show, :new, :create, :edit ] do
      member do
        post :update
        post :destroy
      end
    end

    get "stats", to: "dashboard#stats"
    get "logs", to: "dashboard#logs"
  end

  # Health check endpoint for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check
end
