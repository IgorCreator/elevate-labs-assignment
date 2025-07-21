require 'rails_helper'

RSpec.describe "Api::GameEvents", type: :request do
  let(:user) { create(:user) }
  let(:token) { JwtService.generate_token(user) }
  let(:headers) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  describe "POST /api/user/game_events" do
    let(:valid_params) do
      {
        game_event: {
          game_name: "Brevity",
          type: "COMPLETED",
          occurred_at: 1.day.ago.iso8601
        }
      }
    end

    context "with valid authentication" do
      context "with valid parameters" do
        it "creates a game event successfully" do
          expect {
            post "/api/user/game_events", params: valid_params.to_json, headers: headers
          }.to change(GameEvent, :count).by(1)

          expect(response).to have_http_status(:created)

          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Game event created successfully")
          expect(json_response["game_event"]["game_name"]).to eq("Brevity")
          expect(json_response["game_event"]["type"]).to eq("COMPLETED")
          expect(json_response["game_event"]).to have_key("id")
          expect(json_response["game_event"]).to have_key("occurred_at")
          expect(json_response["game_event"]).to have_key("created_at")
        end

        it "associates the game event with the authenticated user" do
          post "/api/user/game_events", params: valid_params.to_json, headers: headers

          game_event = GameEvent.last
          expect(game_event.user).to eq(user)
          expect(game_event.event_type).to eq("COMPLETED")
        end

        GameEvent::VALID_GAME_NAMES.each do |game_name|
          it "accepts valid game name: #{game_name}" do
            params = { game_event: valid_params[:game_event].merge(game_name: game_name) }
            post "/api/user/game_events", params: params.to_json, headers: headers

            expect(response).to have_http_status(:created)
            json_response = JSON.parse(response.body)
            expect(json_response["game_event"]["game_name"]).to eq(game_name)
          end
        end
      end

      context "with invalid parameters" do
        it "returns validation errors for invalid game name" do
          invalid_params = { game_event: valid_params[:game_event].merge(game_name: "Invalid Game") }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Game name Invalid Game is not a valid game name")
        end

        it "returns validation errors for invalid type" do
          invalid_params = { game_event: valid_params[:game_event].merge(type: "STARTED") }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Event type STARTED is not a valid event type. Only 'COMPLETED' is allowed")
        end

        it "returns validation errors for future occurred_at" do
          invalid_params = { game_event: valid_params[:game_event].merge(occurred_at: 1.day.from_now.iso8601) }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Occurred at Game event COMPLETED can't be in future")
        end

        it "returns validation errors for occurred_at too far in the past" do
          invalid_params = { game_event: valid_params[:game_event].merge(occurred_at: 6.years.ago.iso8601) }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Occurred at cannot be more than 5 years in the past")
        end

        it "returns validation errors for missing game_name" do
          invalid_params = { game_event: valid_params[:game_event].except(:game_name) }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Game name can't be blank")
        end

        it "returns validation errors for missing type" do
          invalid_params = { game_event: valid_params[:game_event].except(:type) }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Event type can't be blank")
        end

        it "returns validation errors for missing occurred_at" do
          invalid_params = { game_event: valid_params[:game_event].except(:occurred_at) }

          post "/api/user/game_events", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Occurred at can't be blank")
        end

        it "returns error for missing game_event wrapper" do
          post "/api/user/game_events", params: valid_params[:game_event].to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to_not be_empty
        end
      end
    end

    context "without authentication" do
      it "returns unauthorized when no token is provided" do
        post "/api/user/game_events", params: valid_params.to_json, headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing authorization token")
      end

      it "returns unauthorized when token is invalid" do
        invalid_headers = { "Authorization" => "Bearer invalid_token", "Content-Type" => "application/json" }
        post "/api/user/game_events", params: valid_params.to_json, headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid or expired token")
      end
    end

    context "edge cases" do
      it "handles occurred_at exactly at the 5-year boundary" do
        boundary_params = { game_event: valid_params[:game_event].merge(occurred_at: (5.years.ago + 1.day).iso8601) }

        post "/api/user/game_events", params: boundary_params.to_json, headers: headers

        expect(response).to have_http_status(:created)
      end

      it "handles occurred_at exactly at current time boundary" do
        boundary_params = { game_event: valid_params[:game_event].merge(occurred_at: 1.minute.ago.iso8601) }

        post "/api/user/game_events", params: boundary_params.to_json, headers: headers

        expect(response).to have_http_status(:created)
      end
    end
  end
end
