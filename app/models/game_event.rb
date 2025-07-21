class GameEvent < ApplicationRecord
  belongs_to :user

  VALID_GAME_NAMES = [
    "Brevity",
    "Wordbend",
    "Retention",
    "Focus",
    "Name Recall"
  ].freeze

  VALID_EVENT_TYPES = [ "COMPLETED" ].freeze

  validates :game_name, presence: true, inclusion: {
    in: VALID_GAME_NAMES,
    message: "%{value} is not a valid game name"
  }

  validates :event_type, presence: true, inclusion: {
    in: VALID_EVENT_TYPES,
    message: "%{value} is not a valid event type. Only 'COMPLETED' is allowed"
  }

  validates :occurred_at, presence: true
  validate :occurred_at_not_in_future
  validate :occurred_at_reasonable_past

  private

  def occurred_at_not_in_future
    return unless occurred_at.present?

    if occurred_at > Time.current
      errors.add(:occurred_at, "Game event #{event_type} can't be in future")
    end
  end

  def occurred_at_reasonable_past
    return unless occurred_at.present?

    five_years_ago = 5.years.ago
    if occurred_at < five_years_ago
      errors.add(:occurred_at, "cannot be more than 5 years in the past")
    end
  end
end
