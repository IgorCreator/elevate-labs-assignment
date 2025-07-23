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

  helper_method :admin_signed_in?, :current_admin_user
end
