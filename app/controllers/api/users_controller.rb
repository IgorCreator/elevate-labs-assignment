class Api::UsersController < ApplicationController
  before_action :authenticate_request!, only: [ :show ]

  wrap_parameters false

  def create
    @user = User.new(user_params)

    if @user.save
      Logging::ApiLoggerService.log_request(@user, "POST /api/user", 201)
      render json: ResponseFormatter.user_success(@user, include_token: true),
             status: :created
    else
      Logging::ApiLoggerService.log_request(nil, "POST /api/user", 422, nil, StandardError.new("Validation failed"))
      response = ResponseFormatter.validation_errors(@user.errors)
      render response
    end
  end

  def show
    stats = UserStatsService.calculate(current_user)

    begin
      Logging::ApiLoggerService.log_request(current_user, "GET /api/user", 200)
      subscription_status = BillingService.get_subscription_status(current_user.id)

      extra_data = {
        stats: stats,
        subscription_status: subscription_status
      }

      render json: ResponseFormatter.user_success(current_user, extra_data: extra_data)

    rescue BillingService::BillingServiceError => e
      Logging::ApiLoggerService.log_request(current_user, "GET /api/user", 503, nil, e)
      response = ResponseFormatter.billing_error(e, current_user.id)
      render response
    end
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end
end
