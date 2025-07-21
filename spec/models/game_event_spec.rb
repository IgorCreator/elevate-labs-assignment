require 'rails_helper'

RSpec.describe GameEvent, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:game_event, user: user) }

    it { should validate_presence_of(:game_name) }
    it { should validate_presence_of(:event_type) }
    it { should validate_presence_of(:occurred_at) }

    describe "game_name validation" do
      it "accepts valid game names" do
        GameEvent::VALID_GAME_NAMES.each do |game_name|
          game_event = build(:game_event, user: user, game_name: game_name)
          expect(game_event).to be_valid
        end
      end

      it "rejects invalid game names" do
        game_event = build(:game_event, user: user, game_name: "Invalid Game")
        expect(game_event).to_not be_valid
        expect(game_event.errors[:game_name]).to include("Invalid Game is not a valid game name")
      end
    end

    describe "event_type validation" do
      it "accepts COMPLETED event_type" do
        game_event = build(:game_event, user: user, event_type: "COMPLETED")
        expect(game_event).to be_valid
      end

      it "rejects invalid event_types" do
        game_event = build(:game_event, user: user, event_type: "STARTED")
        expect(game_event).to_not be_valid
        expect(game_event.errors[:event_type]).to include("STARTED is not a valid event type. Only 'COMPLETED' is allowed")
      end
    end

    describe "occurred_at validation" do
      it "accepts past dates" do
        game_event = build(:game_event, user: user, occurred_at: 1.day.ago)
        expect(game_event).to be_valid
      end

      it "rejects future dates" do
        game_event = build(:game_event, user: user, occurred_at: 1.day.from_now)
        expect(game_event).to_not be_valid
        expect(game_event.errors[:occurred_at]).to include("Game event COMPLETED can't be in future")
      end

      it "rejects dates too far in the past" do
        game_event = build(:game_event, user: user, occurred_at: 6.years.ago)
        expect(game_event).to_not be_valid
        expect(game_event.errors[:occurred_at]).to include("cannot be more than 5 years in the past")
      end

      it "accepts dates exactly 5 years ago" do
        game_event = build(:game_event, user: user, occurred_at: 5.years.ago + 1.day)
        expect(game_event).to be_valid
      end
    end
  end

  describe "constants" do
    it "has the correct valid game names" do
      expected_games = ["Brevity", "Wordbend", "Retention", "Focus", "Name Recall"]
      expect(GameEvent::VALID_GAME_NAMES).to eq(expected_games)
    end

    it "has the correct valid event types" do
      expect(GameEvent::VALID_EVENT_TYPES).to eq(["COMPLETED"])
    end
  end
end
