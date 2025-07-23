class AdminActivityLoggerService
  CACHE_KEY = "admin_activity_logs_array"

  def self.log_activity(admin_user, action, resource_type, resource_id, details = {})
    log_entry = {
      admin_user_id: admin_user&.id,
      admin_user_email: admin_user&.email || "Unknown Admin",
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      details: details,
      timestamp: Time.current
    }

    # Get existing logs
    logs = Rails.cache.read(CACHE_KEY) || []

    # Add new log entry
    logs << log_entry

    # Keep only the last 500 logs to prevent memory issues
    logs = logs.last(500) if logs.length > 500

    # Store back in cache
    Rails.cache.write(CACHE_KEY, logs, expires_in: 24.hours)

    # Also log to Rails logger
    Rails.logger.info "Admin Activity: #{log_entry.to_json}"
  end

  def self.get_recent_logs(limit = 50)
    logs = Rails.cache.read(CACHE_KEY) || []

    # Sort by timestamp (newest first) and limit
    logs.sort_by { |log| log[:timestamp] }.reverse.first(limit)
  end

  def self.clear_logs
    Rails.cache.delete(CACHE_KEY)
  end
end
