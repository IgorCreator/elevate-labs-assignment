require 'rails_helper'

RSpec.describe "Api::Sessions", type: :request do
  describe "POST /api/sessions" do
    let!(:user) { create(:user, email: "test@example.com", password: "SecurePass123!") }

    context "with valid credentials" do
      it "returns 200 status" do
        post "/api/sessions", params: {
          email: "test@example.com",
          password: "SecurePass123!"
        }

        expect(response).to have_http_status(:ok)
      end

      it "returns JWT token and user data" do
        post "/api/sessions", params: {
          email: "test@example.com",
          password: "SecurePass123!"
        }

        json_response = JSON.parse(response.body)

        expect(json_response).to have_key("token")
        expect(json_response).to have_key("user")

        expect(json_response["user"]).to include(
          "id" => user.id,
          "email" => "test@example.com"
        )

        expect(json_response["token"]).to be_present
      end

      it "works with case-insensitive email" do
        post "/api/sessions", params: {
          email: "TEST@EXAMPLE.COM",
          password: "SecurePass123!"
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["user"]["email"]).to eq("test@example.com")
      end

      it "works with email containing whitespace" do
        post "/api/sessions", params: {
          email: "  test@example.com  ",
          password: "SecurePass123!"
        }

        expect(response).to have_http_status(:ok)
      end

      it "generates a valid JWT token" do
        post "/api/sessions", params: {
          email: "test@example.com",
          password: "SecurePass123!"
        }

        json_response = JSON.parse(response.body)
        token = json_response["token"]

        decoded_token = JwtService.decode(token)
        expect(decoded_token).to be_present
        expect(decoded_token[:user_id]).to eq(user.id)
        expect(decoded_token[:email]).to eq("test@example.com")
      end
    end

    context "with invalid credentials" do
      it "returns 401 for non-existent email" do
        post "/api/sessions", params: {
          email: "nonexistent@example.com",
          password: "SecurePass123!"
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid email or password")
      end

      it "returns 401 for incorrect password" do
        post "/api/sessions", params: {
          email: "test@example.com",
          password: "WrongPassword!"
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid email or password")
      end

      it "returns 401 for missing email" do
        post "/api/sessions", params: {
          password: "SecurePass123!"
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid email or password")
      end

      it "returns 401 for missing password" do
        post "/api/sessions", params: {
          email: "test@example.com"
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid email or password")
      end
    end

    context "security considerations" do
      it "doesn't reveal whether email exists or password is wrong" do
        # Test with non-existent email
        post "/api/sessions", params: {
          email: "nonexistent@example.com",
          password: "SecurePass123!"
        }

        non_existent_response = JSON.parse(response.body)

        # Test with existing email but wrong password
        post "/api/sessions", params: {
          email: "test@example.com",
          password: "WrongPassword!"
        }

        wrong_password_response = JSON.parse(response.body)

        # Both should return the same error message
        expect(non_existent_response["error"]).to eq(wrong_password_response["error"])
      end
    end
  end
end
