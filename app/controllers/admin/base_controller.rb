class Admin::BaseController < ActionController::Base
  before_action :authenticate_admin!
  before_action :set_admin_layout

  private

  def authenticate_admin!
    unless admin_signed_in?
      redirect_to admin_login_path(redirected: true)
    end
  end

  def set_admin_layout
    self.class.layout "admin"
  end

  def admin_signed_in?
    session[:admin_id].present?
  end

  def current_admin_user
    @current_admin_user ||= User.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  # Helper method to safely get subscription status with error handling
  def safe_subscription_status(user_id)
    begin
      BillingService.get_subscription_status(user_id)
    rescue BillingService::BillingServiceError => e
      "Error: #{e.error_type}"
    end
  end

  # Helper method to safely fetch fresh subscription status
  def safe_fetch_subscription_status(user_id)
    begin
      BillingService.fetch_from_billing_service(user_id)
    rescue BillingService::BillingServiceError => e
      "Error: #{e.error_type}"
    end
  end

  helper_method :admin_signed_in?, :current_admin_user
end
