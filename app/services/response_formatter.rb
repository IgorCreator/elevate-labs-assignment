class ResponseFormatter
  SERVICE_UNAVAILABLE_MESSAGE = "Service temporarily unavailable, internal team notified".freeze

  def self.user_success(user, include_token: false, extra_data: {})
    response = {
      user: serialize_user(user, extra_data)
    }

    if include_token
      response[:token] = JwtService.generate_token(user)
    end

    response
  end

  def self.error(message, status = :unprocessable_entity)
    {
      json: { error: message },
      status: status
    }
  end

  def self.validation_errors(errors)
    {
      json: { errors: errors.full_messages },
      status: :unprocessable_entity
    }
  end

  def self.billing_error(error, user_id)
    Rails.logger.error "Failed to get subscription status for user #{user_id}: #{error.message}"

    case error.error_type
    when :not_found
      error("User subscription information not found", :not_found)
    when :unauthorized
      error("Billing service authentication failed", :service_unavailable)
    when :intermittent_failure, :timeout, :service_unavailable
      error(SERVICE_UNAVAILABLE_MESSAGE, :service_unavailable)
    else
      error(SERVICE_UNAVAILABLE_MESSAGE, :service_unavailable)
    end
  end

  private

  def self.serialize_user(user, extra_data = {})
    base_data = {
      id: user.id,
      email: user.email
    }

    base_data.merge!(extra_data)
    base_data
  end
end
