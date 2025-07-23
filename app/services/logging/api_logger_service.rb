module Logging
  class ApiLoggerService < Logging::BaseLoggerService
    # Service for logging API requests for monitoring and debugging
    # Stores requests in Rails cache and logs to Rails logger
    CACHE_KEY = "api_logs_array"

    # Log an API request with details
    # @param user [User] The user making the request
    # @param endpoint [String] The API endpoint being called
    # @param status [Integer] The HTTP status code
    # @param response_time [Float] Response time in seconds (optional)
    # @param error [Exception] Error object if request failed (optional)
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

      log_entry(CACHE_KEY, log_entry, 1000, "API Request")
    end

    def self.get_recent_logs(limit = 50)
      super(CACHE_KEY, limit)
    end

    def self.clear_logs
      super(CACHE_KEY)
    end
  end
end
