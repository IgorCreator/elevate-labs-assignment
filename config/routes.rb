Rails.application.routes.draw do
  namespace :api do
    # User signup endpoint
    post "user", to: "users#create"

    # User login endpoint
    post "sessions", to: "sessions#create"

    # User details endpoint (will be added in Phase 3)
    get "user", to: "users#show"

    # Game events endpoint (will be added in Phase 2)
    post "user/game_events", to: "game_events#create"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
