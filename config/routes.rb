Rails.application.routes.draw do
  namespace :api do
    post "user", to: "users#create"
    post "sessions", to: "sessions#create"
    get "user", to: "users#show"
    post "user/game_events", to: "game_events#create"
  end

  # Health check endpoint for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check
end
