class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || "fallback_secret_for_dev"
  EXPIRATION_TIME = 12.hours.from_now

  def self.encode(payload)
    payload[:exp] = EXPIRATION_TIME.to_i
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    begin
      decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })
      HashWithIndifferentAccess.new(decoded[0])
    rescue JWT::ExpiredSignature
      Rails.logger.info("JWT token expired")
      nil
    rescue JWT::DecodeError => e
      Rails.logger.info("JWT decode error: #{e.message}")
      nil
    end
  end

  def self.generate_token(user)
    encode({
      user_id: user.id,
      email: user.email,
      iat: Time.current.to_i
    })
  end
end
