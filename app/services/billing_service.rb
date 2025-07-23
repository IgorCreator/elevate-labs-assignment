require "net/http"
require "json"

class BillingService
  class << self
    def get_subscription_status(user_id)
      cache_key = "subscription_status:#{user_id}"

      cached_status = Rails.cache.read(cache_key)
      if cached_status
        Rails.logger.info "💾 BillingService: Using CACHED status for user #{user_id}"
        return cached_status
      end

      Rails.logger.info "💾 BillingService: Cache MISS for user #{user_id}, making network call"

      begin
        subscription_status = fetch_from_billing_service(user_id)

        Rails.cache.write(
          cache_key,
          subscription_status,
          expires_in: cache_expiration_time
        )

        Rails.logger.info "💾 BillingService: Cached fresh status for user #{user_id}"

        subscription_status
      rescue BillingServiceError => e
        Rails.logger.error "BillingService error for user #{user_id}: #{e.message}"

        # Fallback to stale cache if available
        stale_cached_status = Rails.cache.read(cache_key, expired: true)
        return stale_cached_status if stale_cached_status

        raise e
      end
    end

    def fetch_from_billing_service(user_id)
      Rails.logger.info "🌐 BillingService: Making NETWORK CALL to billing service for user #{user_id}"

      uri = URI("#{base_url}/users/#{user_id}/billing")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{jwt_token}"
      request["Content-Type"] = "application/json"

      response = http.request(request)

      Rails.logger.info "🌐 BillingService: Network call completed for user #{user_id} - Status: #{response.code}"

      handle_response(response, user_id)
    rescue BillingServiceError
      raise
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise BillingServiceError.new("Billing service timeout", :timeout)
    rescue JSON::ParserError => e
      raise BillingServiceError.new("Invalid JSON response from billing service", :parse_error)
    rescue StandardError => e
      raise BillingServiceError.new("Network error connecting to billing service: #{e.message}", :network_error)
    end

    def handle_response(response, user_id)
      Rails.logger.debug "BillingService response for user #{user_id}: #{response.code} - #{response.body}"

      case response.code.to_i
      when 200
        parsed_response = JSON.parse(response.body)
        Rails.logger.debug "BillingService parsed response: #{parsed_response}"
        parsed_response["subscription_status"]
      when 401
        raise BillingServiceError.new("Unauthorized access to billing service", :unauthorized)
      when 404
        handle_not_found_error(user_id)
      when 503
        raise BillingServiceError.new("Billing service temporarily unavailable", :service_unavailable)
      when 500, 502, 504
        raise BillingServiceError.new("Billing service error", :service_unavailable)
      else
        raise BillingServiceError.new("Unexpected billing service response: #{response.code}", :unexpected_error)
      end
    end

    # Business rule: User ID=5 and others <= 100 are intermittent failures
    # User ID > 100 are true not found errors
    def handle_not_found_error(user_id)
      if user_id.to_i > 100
        raise BillingServiceError.new("User not found in billing system", :not_found)
      else
        raise BillingServiceError.new("Intermittent billing service failure", :intermittent_failure)
      end
    end

    def base_url
      ENV["BILLING_SERVICE_BASE_URL"] ||
      Rails.application.credentials.billing_service&.dig(:base_url) ||
      "https://interviews-accounts.elevateapp.com/api/v1"
    end

    def jwt_token
      ENV["BILLING_SERVICE_JWT_TOKEN"] ||
      Rails.application.credentials.billing_service&.dig(:jwt_token) ||
      raise_missing_config_error("BILLING_SERVICE_JWT_TOKEN")
    end

    def cache_expiration_time
      hours = (ENV["BILLING_SERVICE_CACHE_EXPIRATION_HOURS"] ||
               Rails.application.credentials.billing_service&.dig(:cache_expiration_hours) ||
               24).to_i
      hours.hours
    end

    def read_timeout
      (ENV["BILLING_SERVICE_TIMEOUT_SECONDS"] ||
       Rails.application.credentials.billing_service&.dig(:timeout_seconds) ||
       10).to_i
    end

    def open_timeout
      (ENV["BILLING_SERVICE_OPEN_TIMEOUT_SECONDS"] ||
       Rails.application.credentials.billing_service&.dig(:open_timeout_seconds) ||
       5).to_i
    end

    private

    def raise_missing_config_error(env_var)
      raise BillingServiceError.new(
        "Missing required environment variable: #{env_var}. Check your .env file or Rails credentials.",
        :configuration_error
      )
    end
  end

  class BillingServiceError < StandardError
    attr_reader :error_type

    def initialize(message, error_type = :unknown)
      super(message)
      @error_type = error_type
    end
  end
end
