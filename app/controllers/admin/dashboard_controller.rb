class Admin::DashboardController < Admin::BaseController
  def index
    @total_users = User.count
    @total_game_events = GameEvent.count
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_events = GameEvent.includes(:user).order(occurred_at: :desc).limit(10)

    # Basic stats
    @games_played_today = GameEvent.where(occurred_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    @users_created_today = User.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
  end

  def stats
    @users = User.includes(:game_events).all

    # Calculate user stats
    @user_stats = @users.map do |user|
      stats = UserStatsService.calculate(user)
      subscription_status = safe_subscription_status(user.id)

      {
        user: user,
        stats: stats,
        subscription_status: subscription_status
      }
    end

    # Game statistics
    @game_stats = GameEvent.group(:game_name).count
    @event_stats = GameEvent.group(:event_type).count
  end

    def logs
    @recent_activity = []

    # Add admin activity logs
    admin_logs = Logging::AdminActivityLoggerService.get_recent_logs(20)
    admin_logs.each do |log|
      @recent_activity << {
        type: "admin_activity",
        timestamp: log[:timestamp],
        message: "#{log[:admin_user_email] || 'Unknown'} #{log[:action]} #{log[:resource_type]} #{log[:resource_id]}",
        data: {
          admin_user_id: log[:admin_user_id],
          action: log[:action],
          resource_type: log[:resource_type],
          resource_id: log[:resource_id],
          details: log[:details]
        }
      }
    end

    # Add API request logs
    api_logs = Logging::ApiLoggerService.get_recent_logs(20)
    api_logs.each do |log|
      @recent_activity << {
        type: "api_request",
        timestamp: log[:timestamp],
        message: "#{log[:user_email] || 'Unknown'} - #{log[:endpoint]} (#{log[:status]})",
        data: {
          user_id: log[:user_id],
          endpoint: log[:endpoint],
          status: log[:status],
          response_time: log[:response_time],
          error: log[:error]
        }
      }
    end

    # Add recent user registrations
    User.order(created_at: :desc).limit(10).each do |user|
      @recent_activity << {
        type: "user_registration",
        timestamp: user.created_at,
        message: "User #{user.email} registered",
        data: { user_id: user.id, email: user.email }
      }
    end

    # Add recent game events
    GameEvent.includes(:user).order(occurred_at: :desc).limit(10).each do |event|
      @recent_activity << {
        type: "game_event",
        timestamp: event.occurred_at,
        message: "User #{event.user.email} completed #{event.game_name}",
        data: { user_id: event.user_id, game_name: event.game_name, event_type: event.event_type }
      }
    end

    # Sort by timestamp
    @recent_activity.sort_by! { |activity| activity[:timestamp] }.reverse!
  end
end
