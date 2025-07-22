class Api::SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      render json: ResponseFormatter.user_success(user, include_token: true),
             status: :ok
    else
      response = ResponseFormatter.error("Invalid email or password", :unauthorized)
      render response
    end
  end
end
