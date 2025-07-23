class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :refresh_subscription, :clear_subscription_cache ]

  def index
    @users = User.order(created_at: :desc)
    @users = @users.where("email ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @users = @users.page(params[:page]).per(20)
  end

  def show
    @user_stats = UserStatsService.calculate(@user)

    # Use fresh status if provided (from cache clear), otherwise get cached status
    @subscription_status = if params[:fresh_status]
      params[:fresh_status]
    else
      safe_subscription_status(@user.id)
    end

    @recent_events = @user.game_events.order(occurred_at: :desc).limit(10)

    # Navigation data
    @prev_user = User.where("id < ?", @user.id).order(id: :desc).first
    @next_user = User.where("id > ?", @user.id).order(:id).first

    # Get actual API response
    @api_response = get_api_response(@user)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      Logging::AdminActivityLoggerService.log_activity(
        current_admin_user,
        "create",
        "user",
        @user.id,
        { email: @user.email }
      )
      redirect_to admin_user_path(@user)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Check if this is actually a delete request
    if params[:commit] == "Delete"
      user_email = @user.email
      @user.destroy
      Logging::AdminActivityLoggerService.log_activity(
        current_admin_user,
        "delete",
        "user",
        @user.id,
        { email: user_email, method: "update_form" }
      )
      redirect_to admin_users_path
    else
      if @user.update(user_params)
        Logging::AdminActivityLoggerService.log_activity(
          current_admin_user,
          "update",
          "user",
          @user.id,
          { email: @user.email }
        )
        redirect_to admin_user_path(@user)
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    user_email = @user.email
    @user.destroy
    Logging::AdminActivityLoggerService.log_activity(
      current_admin_user,
      "delete",
      "user",
      @user.id,
      { email: user_email, method: "destroy_action" }
    )
    redirect_to admin_users_path
  end

  def refresh_subscription
    @subscription_status = safe_fetch_subscription_status(@user.id)
    redirect_to admin_user_path(@user, subscription_refreshed: true)
  end

  def clear_subscription_cache
    cache_key = "subscription_status:#{@user.id}"
    Rails.cache.delete(cache_key)

    # Get fresh subscription status after clearing cache
    @subscription_status = safe_fetch_subscription_status(@user.id)

    redirect_to admin_user_path(@user, cache_cleared: true, fresh_status: @subscription_status)
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    unless @user
      redirect_to admin_users_path(error: "User with ID #{params[:id]} does not exist")
      nil # Important to stop further processing
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def get_api_response(user)
    begin
      # Use the same logic as Api::UsersController#show
      stats = UserStatsService.calculate(user)

      begin
        subscription_status = BillingService.get_subscription_status(user.id)

        extra_data = {
          stats: stats,
          subscription_status: subscription_status
        }

        # Use the same ResponseFormatter as the API
        ResponseFormatter.user_success(user, extra_data: extra_data)

      rescue BillingService::BillingServiceError => e
        response = ResponseFormatter.billing_error(e, user.id)
        response[:json]
      end
    rescue => e
      { error: "Failed to generate API response: #{e.message}" }
    end
  end
end
