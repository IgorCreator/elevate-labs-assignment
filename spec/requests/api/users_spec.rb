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

    context "with valid authentication" do
      context "user with no game events" do
        it "returns user details with zero stats" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("user")

          user_data = json_response["user"]
          expect(user_data["id"]).to eq(user.id)
          expect(user_data["email"]).to eq(user.email)
          expect(user_data["stats"]["total_games_played"]).to eq(0)
          expect(user_data["stats"]["games"]).to eq({})
        end
      end

      context "user with game events" do
        before do
          create(:game_event, user: user, game_name: "Brevity", event_type: "COMPLETED")
          create(:game_event, user: user, game_name: "Brevity", event_type: "COMPLETED")
          create(:game_event, user: user, game_name: "Focus", event_type: "COMPLETED")
          create(:game_event, user: user, game_name: "Wordbend", event_type: "COMPLETED")
        end

        it "returns user details with calculated stats" do
          get "/api/user", headers: auth_headers

          expect(response).to have_http_status(:ok)

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
        end

        it "only counts COMPLETED event types" do
          other_user = create(:user)
          create(:game_event, user: other_user, game_name: "Brevity", event_type: "COMPLETED")

          get "/api/user", headers: auth_headers

          json_response = JSON.parse(response.body)
          user_data = json_response["user"]

          expect(user_data["stats"]["total_games_played"]).to eq(4)
        end
      end

      context "user with mixed game data" do
        before do
          create(:game_event, :brevity_game, user: user)
          create(:game_event, :focus_game, user: user)
          create(:game_event, :recent, user: user, game_name: "Retention")
          create(:game_event, :older, user: user, game_name: "Name Recall")
        end

        it "calculates stats correctly across all games" do
          get "/api/user", headers: auth_headers

          json_response = JSON.parse(response.body)
          stats = json_response["user"]["stats"]

          expect(stats["total_games_played"]).to eq(4)
          expect(stats["games"]).to include(
            "Brevity" => 1,
            "Focus" => 1,
            "Retention" => 1,
            "Name Recall" => 1
          )
        end
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
        expired_token = JWT.encode(payload, JwtService::SECRET_KEY, 'HS256')

        get "/api/user", headers: { "Authorization" => "Bearer #{expired_token}" }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid or expired token")
      end

      it "handles user not found scenario" do
        non_existent_user_id = User.maximum(:id).to_i + 1
        payload = { user_id: non_existent_user_id }
        token_for_deleted_user = JWT.encode(payload, JwtService::SECRET_KEY, 'HS256')

        get "/api/user", headers: { "Authorization" => "Bearer #{token_for_deleted_user}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
