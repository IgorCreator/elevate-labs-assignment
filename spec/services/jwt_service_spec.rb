require 'rails_helper'

RSpec.describe JwtService do
  let(:user) { create(:user) }
  let(:test_payload) { { user_id: user.id, email: user.email } }

  describe '.encode' do
    it 'encodes a payload into a JWT token' do
      token = JwtService.encode(test_payload)
      expect(token).to be_present
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'adds expiration time to payload' do
      token = JwtService.encode(test_payload)
      decoded = JwtService.decode(token)

      expect(decoded[:exp]).to be_present
      expect(decoded[:exp]).to be > Time.current.to_i
    end
  end

  describe '.decode' do
    context 'with valid token' do
      let(:token) { JwtService.encode(test_payload) }

      it 'decodes a valid JWT token' do
        decoded = JwtService.decode(token)

        expect(decoded).to be_present
        expect(decoded[:user_id]).to eq(user.id)
        expect(decoded[:email]).to eq(user.email)
      end

      it 'returns HashWithIndifferentAccess' do
        decoded = JwtService.decode(token)

        expect(decoded).to be_a(HashWithIndifferentAccess)
        expect(decoded['user_id']).to eq(user.id)  # String key access
        expect(decoded[:user_id]).to eq(user.id)   # Symbol key access
      end
    end

    context 'with invalid token' do
      it 'returns nil for invalid token format' do
        invalid_token = "invalid.token.format"
        decoded = JwtService.decode(invalid_token)

        expect(decoded).to be_nil
      end

      it 'returns nil for token with wrong secret' do
        # Generate token with different secret
        wrong_token = JWT.encode(test_payload, 'wrong_secret', 'HS256')
        decoded = JwtService.decode(wrong_token)

        expect(decoded).to be_nil
      end

      it 'returns nil for expired token' do
        # Create expired token
        expired_payload = test_payload.merge(exp: 1.hour.ago.to_i)
        expired_token = JWT.encode(expired_payload, JwtService.send(:secret_key), 'HS256')

        decoded = JwtService.decode(expired_token)
        expect(decoded).to be_nil
      end

      it 'logs appropriate error messages' do
        allow(Rails.logger).to receive(:info)

        # Test expired token
        expired_payload = test_payload.merge(exp: 1.hour.ago.to_i)
        expired_token = JWT.encode(expired_payload, JwtService.send(:secret_key), 'HS256')
        JwtService.decode(expired_token)

        expect(Rails.logger).to have_received(:info).with("JWT token expired")

        # Test invalid token
        JwtService.decode("invalid.token")
        expect(Rails.logger).to have_received(:info).with(/JWT decode error/)
      end
    end
  end

  describe '.generate_token' do
    it 'generates a token for a user' do
      token = JwtService.generate_token(user)

      expect(token).to be_present
      decoded = JwtService.decode(token)

      expect(decoded[:user_id]).to eq(user.id)
      expect(decoded[:email]).to eq(user.email)
      expect(decoded[:iat]).to be_present
    end

        it 'includes issued at time' do
      current_time = Time.current.to_i
      token = JwtService.generate_token(user)
      decoded = JwtService.decode(token)

      # Allow for small time difference during test execution
      expect(decoded[:iat]).to be_within(2).of(current_time)
    end

    it 'generates different tokens for the same user at different times' do
      token1 = JwtService.generate_token(user)
      sleep 1  # Wait 1 second to ensure different iat
      token2 = JwtService.generate_token(user)

      expect(token1).not_to eq(token2)
    end
  end

    describe 'token expiration' do
    it 'sets expiration to 12 hours from creation' do
      token = JwtService.generate_token(user)
      decoded = JwtService.decode(token)

      expected_exp = 12.hours.from_now.to_i
      # Allow for small time difference during test execution (within 10 seconds)
      expect(decoded[:exp]).to be_within(10).of(expected_exp)
    end
  end

  describe 'configuration' do
    it 'reads secret key from environment variables' do
      # Test with environment variable set
      allow(ENV).to receive(:[]).with('JWT_SECRET_KEY').and_return('env_secret_key')
      expect(JwtService.send(:secret_key)).to eq('env_secret_key')
    end

    it 'falls back to Rails credentials when ENV not set' do
      # Test fallback to Rails credentials
      allow(ENV).to receive(:[]).with('JWT_SECRET_KEY').and_return(nil)
      expect(JwtService.send(:secret_key)).to eq(Rails.application.credentials.secret_key_base)
    end

    it 'reads expiration hours from environment variables' do
      # Test with environment variable set
      allow(ENV).to receive(:[]).with('JWT_EXPIRATION_HOURS').and_return('24')
      expect(JwtService.send(:expiration_time)).to be_within(10.seconds).of(24.hours.from_now)
    end
  end
end
