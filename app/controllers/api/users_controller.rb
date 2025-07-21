class Api::UsersController < ApplicationController
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
    # Will be implemented in Phase 3
    # This endpoint will return user details with stats and subscription status
    render json: { message: "User details endpoint - to be implemented in Phase 3" }
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end
end
