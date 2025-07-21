FactoryBot.define do
  factory :game_event do
    association :user
    game_name { GameEvent::VALID_GAME_NAMES.sample }
    event_type { "COMPLETED" }
    occurred_at { 1.day.ago }

    trait :recent do
      occurred_at { 1.hour.ago }
    end

    trait :older do
      occurred_at { 1.month.ago }
    end

    trait :brevity_game do
      game_name { "Brevity" }
    end

    trait :focus_game do
      game_name { "Focus" }
    end
  end
end
