class JwtService
  class << self
    def generate_token(user)
      encode({
        user_id: user.id,
        email: user.email,
        iat: Time.current.to_i
      })
    end

    def encode(payload)
      payload[:exp] = expiration_time.to_i
      JWT.encode(payload, secret_key, algorithm)
    end

    def decode(token)
      decoded = JWT.decode(token, secret_key, true, { algorithm: algorithm })
      HashWithIndifferentAccess.new(decoded[0])
    rescue JWT::ExpiredSignature
      Rails.logger.info("JWT token expired")
      nil
    rescue JWT::DecodeError => e
      Rails.logger.info("JWT decode error: #{e.message}")
      nil
    end

    private

    def secret_key
      ENV["JWT_SECRET_KEY"] || Rails.application.credentials.secret_key_base
    end

    def expiration_time
      hours = (ENV["JWT_EXPIRATION_HOURS"] ||
               Rails.application.credentials.jwt&.dig(:expiration_hours) ||
               12).to_i
      hours.hours.from_now
    end

    def algorithm
      "HS256"
    end
  end
end
