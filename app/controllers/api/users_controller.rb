class Api::UsersController < ApplicationController
  before_action :authenticate_request!, only: [ :show ]

  def create
    @user = User.new(user_params)

    if @user.save
      token = JwtService.generate_token(@user)

      render json: {
        user: {
          id: @user.id,
          email: @user.email
        },
        token: token
      }, status: :created
    else
      render json: {
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def show
    stats = calculate_user_stats(current_user)

    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        stats: stats
      }
    }
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end

  def calculate_user_stats(user)
    game_events = user.game_events.where(event_type: GameEvent::VALID_EVENT_TYPES)

    {
      total_games_played: game_events.count,
      games: game_events.group(:game_name).count
    }
  end
end
