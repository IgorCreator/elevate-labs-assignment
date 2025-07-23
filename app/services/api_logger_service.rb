class ApiLoggerService
  CACHE_KEY = "api_logs_array"

  def self.log_request(user, endpoint, status, response_time = nil, error = nil)
    log_entry = {
      user_id: user&.id,
      user_email: user&.email,
      endpoint: endpoint,
      status: status,
      response_time: response_time,
      error: error&.message,
      timestamp: Time.current
    }

    # Get existing logs
    logs = Rails.cache.read(CACHE_KEY) || []

    # Add new log entry
    logs << log_entry

    # Keep only the last 1000 logs to prevent memory issues
    logs = logs.last(1000) if logs.length > 1000

    # Store back in cache
    Rails.cache.write(CACHE_KEY, logs, expires_in: 24.hours)

    # Also log to Rails logger
    Rails.logger.info "API Request: #{log_entry.to_json}"
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
