module Logging
  class AdminActivityLoggerService < Logging::BaseLoggerService
    # Service for logging admin activities for audit trail
    # Stores activities in Rails cache and logs to Rails logger
    CACHE_KEY = "admin_activity_logs_array"

    # Log an admin activity with details
    # @param admin_user [User] The admin user performing the action
    # @param action [String] The action performed (create, update, delete)
    # @param resource_type [String] The type of resource (user, game_event)
    # @param resource_id [Integer] The ID of the resource
    # @param details [Hash] Additional details about the action
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

      log_entry(CACHE_KEY, log_entry, 500, "Admin Activity")
    end

    def self.get_recent_logs(limit = 50)
      super(CACHE_KEY, limit)
    end

    def self.clear_logs
      super(CACHE_KEY)
    end
  end
end
