class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  attr_reader :current_user

  protected

  def authenticate_request!
    token = extract_token_from_header

    if token.blank?
      render json: { error: "Missing authorization token" }, status: :unauthorized
      return
    end

    payload = JwtService.decode(token)

    if payload.nil?
      render json: { error: "Invalid or expired token" }, status: :unauthorized
      return
    end

    @current_user = User.find_by(id: payload[:user_id])

    if @current_user.nil?
      render json: { error: "User not found" }, status: :unauthorized
      nil
    end
  end

  private

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end
end
