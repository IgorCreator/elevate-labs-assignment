require 'rails_helper'

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
end
