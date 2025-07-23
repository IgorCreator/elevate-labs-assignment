class Api::SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      ApiLoggerService.log_request(user, "POST /api/sessions", 200)
      render json: ResponseFormatter.user_success(user, include_token: true),
             status: :ok
    else
      ApiLoggerService.log_request(nil, "POST /api/sessions", 401, nil, StandardError.new("Invalid credentials"))
      response = ResponseFormatter.error("Invalid email or password", :unauthorized)
      render response
    end
  end
end
