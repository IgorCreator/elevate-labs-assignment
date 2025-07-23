class Admin::SessionsController < Admin::BaseController
  skip_before_action :authenticate_admin!, only: [ :new, :create ]

  def new
    redirect_to admin_path if admin_signed_in?
    @show_redirect_notice = params[:redirected] == "true"
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      # For now, we'll use a simple admin check
      # In production, you'd want a proper admin flag or role system
      if user.id == 1 || user.email.include?("admin") # Simple admin check
        session[:admin_id] = user.id
        redirect_to admin_path
      else
        @error_message = "Access denied. Admin privileges required."
        render :new, status: :unauthorized
      end
    else
      @error_message = "Invalid email or password"
      render :new, status: :unauthorized
    end
  end

  def destroy
    session[:admin_id] = nil
    redirect_to admin_login_path
  end
end
