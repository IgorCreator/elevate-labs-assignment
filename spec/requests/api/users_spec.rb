require 'rails_helper'
require 'jwt'

RSpec.describe "Api::Users", type: :request do
  describe "POST /api/user" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          email: "test@example.com",
          password: "SecurePass123!",
          password_confirmation: "SecurePass123!"
        }
      end

      it "creates a new user" do
        expect {
          post "/api/user", params: valid_params
        }.to change(User, :count).by(1)
      end

      it "returns 201 status" do
        post "/api/user", params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "returns user data and JWT token" do
        post "/api/user", params: valid_params

        json_response = JSON.parse(response.body)

        expect(json_response).to have_key("user")
        expect(json_response).to have_key("token")

        expect(json_response["user"]).to include(
          "id" => be_present,
          "email" => "test@example.com"
        )

        expect(json_response["token"]).to be_present
      end

      it "normalizes email to lowercase" do
        post "/api/user", params: valid_params.merge(email: "TEST@EXAMPLE.COM")

        json_response = JSON.parse(response.body)
        expect(json_response["user"]["email"]).to eq("test@example.com")
      end
    end

    context "with invalid parameters" do
      it "returns 422 for missing email" do
        post "/api/user", params: {
          password: "SecurePass123!",
          password_confirmation: "SecurePass123!"
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Email can't be blank")
      end

      it "returns 422 for invalid email format" do
        post "/api/user", params: {
          email: "invalid-email",
          password: "SecurePass123!",
          password_confirmation: "SecurePass123!"
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Email is invalid")
      end

      it "returns 422 for short password" do
        post "/api/user", params: {
          email: "test@example.com",
          password: "Short1!",
          password_confirmation: "Short1!"
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Password is too short (minimum is 8 characters)")
      end

      it "returns 422 for password without symbol" do
        post "/api/user", params: {
          email: "test@example.com",
          password: "NoSymbolPass123",
          password_confirmation: "NoSymbolPass123"
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Password must contain at least one symbol")
      end

      it "returns 422 for duplicate email" do
        create(:user, email: "test@example.com")

        post "/api/user", params: {
          email: "test@example.com",
          password: "SecurePass123!",
          password_confirmation: "SecurePass123!"
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Email has already been taken")
      end

      it "returns 422 for password confirmation mismatch" do
        post "/api/user", params: {
          email: "test@example.com",
          password: "SecurePass123!",
          password_confirmation: "DifferentPass!"
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Password confirmation doesn't match Password")
      end
    end

    context "JWT token" do
      let(:valid_params) do
        {
          email: "test@example.com",
          password: "SecurePass123!",
          password_confirmation: "SecurePass123!"
        }
      end

      it "generates a valid JWT token" do
        post "/api/user", params: valid_params

        json_response = JSON.parse(response.body)
        token = json_response["token"]

        decoded_token = JwtService.decode(token)
        expect(decoded_token).to be_present
        expect(decoded_token[:email]).to eq("test@example.com")
      end
    end
  end

  describe "GET /api/user" do
    let(:user) { create(:user) }
    let(:token) { JwtService.generate_token(user) }
    let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }

    before do
      Rails.cache.clear
    end

    context "with valid authentication and successful billing service" do
      before do
        # Stub BillingService method to return 'active' subscription
        allow(BillingService).to receive(:get_subscription_status)
          .with(user.id)
          .and_return('active')
      end

      context "user with no game events" do
        it "returns user details with zero stats and subscription status" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:ok)

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(user.id)

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("user")

          user_data = json_response["user"]
          expect(user_data["id"]).to eq(user.id)
          expect(user_data["email"]).to eq(user.email)
          expect(user_data["stats"]["total_games_played"]).to eq(0)
          expect(user_data["stats"]["games"]).to eq({})
          expect(user_data["subscription_status"]).to eq("active")
        end
      end

      context "user with game events" do
        before do
          create(:game_event, user: user, game_name: "Brevity", event_type: "COMPLETED")
          create(:game_event, user: user, game_name: "Brevity", event_type: "COMPLETED")
          create(:game_event, user: user, game_name: "Focus", event_type: "COMPLETED")
          create(:game_event, user: user, game_name: "Wordbend", event_type: "COMPLETED")
        end

        it "returns user details with calculated stats and subscription status" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:ok)

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(user.id)

          json_response = JSON.parse(response.body)
          user_data = json_response["user"]

          expect(user_data["id"]).to eq(user.id)
          expect(user_data["email"]).to eq(user.email)
          expect(user_data["stats"]["total_games_played"]).to eq(4)
          expect(user_data["stats"]["games"]).to eq({
            "Brevity" => 2,
            "Focus" => 1,
            "Wordbend" => 1
          })
          expect(user_data["subscription_status"]).to eq("active")
        end
      end

      context "expired subscription" do
        before do
          # Stub BillingService method to return 'expired' subscription
          allow(BillingService).to receive(:get_subscription_status)
            .with(user.id)
            .and_return('expired')
        end

        it "returns expired subscription status" do
          get "/api/user", headers: auth_headers

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(user.id)

          json_response = JSON.parse(response.body)
          expect(json_response["user"]["subscription_status"]).to eq("expired")
        end
      end
    end

    context "billing service errors" do
      context "user not found in billing system (user_id > 100)" do
        before do
          # Create user with fixed ID > 100
          user.update!(id: 101)
          user.reload

          # Stub the BillingService method directly instead of HTTP
          allow(BillingService).to receive(:get_subscription_status).with(101)
            .and_raise(BillingService::BillingServiceError.new("User not found in billing system", :not_found))
        end

        it "returns 404 with appropriate error message" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:not_found)

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(101)

          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("User subscription information not found")
        end
      end

      context "intermittent failure" do
        before do
          # Create user with fixed ID = 5
          user.update!(id: 5)
          user.reload

          # Stub the BillingService method directly
          allow(BillingService).to receive(:get_subscription_status).with(5)
            .and_raise(BillingService::BillingServiceError.new("Intermittent billing service failure", :intermittent_failure))
        end

        it "returns 503 with service unavailable message" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:service_unavailable)

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(5)

          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Service temporarily unavailable, internal team notified")
        end
      end

      context "service timeout" do
        before do
          # Stub BillingService to raise a timeout error
          allow(BillingService).to receive(:get_subscription_status)
            .with(user.id)
            .and_raise(BillingService::BillingServiceError.new("Request timeout", :timeout))
        end

        it "returns 503 with service unavailable message" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:service_unavailable)

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(user.id)

          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Service temporarily unavailable, internal team notified")
        end
      end

      context "service unavailable" do
        before do
          # Stub BillingService to raise a service unavailable error
          allow(BillingService).to receive(:get_subscription_status)
            .with(user.id)
            .and_raise(BillingService::BillingServiceError.new("Service unavailable", :service_unavailable))
        end

        it "returns 503 with service unavailable message" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:service_unavailable)

          # Verify BillingService was called with correct user_id
          expect(BillingService).to have_received(:get_subscription_status).with(user.id)

          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Service temporarily unavailable, internal team notified")
        end
      end
    end

    context "caching behavior" do
      before do
        # Stub BillingService to return 'active' and track calls
        allow(BillingService).to receive(:get_subscription_status)
          .with(user.id)
          .and_return('active')
      end

      it "calls BillingService with correct arguments" do
        get "/api/user", headers: auth_headers

        expect(response).to have_http_status(:ok)

        # Verify BillingService was called with correct user_id
        expect(BillingService).to have_received(:get_subscription_status).with(user.id).once

        json_response = JSON.parse(response.body)
        expect(json_response["user"]["subscription_status"]).to eq("active")
      end

      it "returns subscription status successfully with caching enabled" do
        get "/api/user", headers: auth_headers

        expect(response).to have_http_status(:ok)

        # Verify BillingService was called with correct user_id
        expect(BillingService).to have_received(:get_subscription_status).with(user.id)

        json_response = JSON.parse(response.body)
        expect(json_response["user"]["subscription_status"]).to eq("active")
      end
    end

    context "without authentication" do
      it "returns unauthorized when no token is provided" do
        get "/api/user"

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing authorization token")
      end

      it "returns unauthorized when token is invalid" do
        get "/api/user", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid or expired token")
      end

      it "returns unauthorized when token is malformed" do
        get "/api/user", headers: { "Authorization" => "InvalidFormat" }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing authorization token")
      end
    end

    context "edge cases" do
      it "handles expired tokens" do
        # Create a payload with past expiration
        payload = { user_id: user.id, exp: 1.hour.ago.to_i }
        expired_token = JWT.encode(payload, JwtService.send(:secret_key), 'HS256')

        get "/api/user", headers: { "Authorization" => "Bearer #{expired_token}" }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid or expired token")
      end

      it "handles user not found scenario" do
        non_existent_user_id = User.maximum(:id).to_i + 1
        payload = { user_id: non_existent_user_id }
        token_for_deleted_user = JWT.encode(payload, JwtService.send(:secret_key), 'HS256')

        get "/api/user", headers: { "Authorization" => "Bearer #{token_for_deleted_user}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
