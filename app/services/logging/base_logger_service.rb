module Logging
  class BaseLoggerService
    # Base service for logging activities with caching and Rails logger integration
    # Provides common functionality for different types of logging

    def self.log_entry(cache_key, log_entry, max_logs = 1000, log_prefix = "Log")
      # Get existing logs
      logs = Rails.cache.read(cache_key) || []

      # Add new log entry
      logs << log_entry

      # Keep only the last N logs to prevent memory issues
      logs = logs.last(max_logs) if logs.length > max_logs

      # Store back in cache
      Rails.cache.write(cache_key, logs, expires_in: 24.hours)

      # Also log to Rails logger
      Rails.logger.info "#{log_prefix}: #{log_entry.to_json}"
    end

    def self.get_recent_logs(cache_key, limit = 50)
      logs = Rails.cache.read(cache_key) || []

      # Sort by timestamp (newest first) and limit
      logs.sort_by { |log| log[:timestamp] }.reverse.first(limit)
    end

    def self.clear_logs(cache_key)
      Rails.cache.delete(cache_key)
    end
  end
end
