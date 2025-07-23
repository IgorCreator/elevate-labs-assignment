class Api::GameEventsController < ApplicationController
  before_action :authenticate_request!

  def create
    game_event_params_mapped = game_event_params
    game_event_params_mapped[:event_type] = game_event_params_mapped.delete(:type) if game_event_params_mapped[:type]

    @game_event = current_user.game_events.build(game_event_params_mapped)

    if @game_event.save
      Logging::ApiLoggerService.log_request(current_user, "POST /api/user/game_events", 201)
      render json: {
        message: "Game event created successfully",
        game_event: {
          id: @game_event.id,
          game_name: @game_event.game_name,
          type: @game_event.event_type,
          occurred_at: @game_event.occurred_at,
          created_at: @game_event.created_at
        }
      }, status: :created
    else
      Logging::ApiLoggerService.log_request(current_user, "POST /api/user/game_events", 422, nil, StandardError.new("Validation failed"))
      render json: {
        errors: @game_event.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
          Logging::ApiLoggerService.log_request(current_user, "POST /api/user/game_events", 400, nil, e)
    render json: {
      error: e.message
    }, status: :bad_request
  end

  private

  def game_event_params
    params.require(:game_event).permit(:game_name, :type, :occurred_at)
  end
end
