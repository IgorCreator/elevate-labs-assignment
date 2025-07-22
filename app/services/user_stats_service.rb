class UserStatsService
  def self.calculate(user)
    completed_events = user.game_events.where(event_type: GameEvent::VALID_EVENT_TYPES)

    {
      total_games_played: completed_events.count,
      games: calculate_per_game_stats(completed_events)
    }
  end

  private

  def self.calculate_per_game_stats(game_events)
    game_events.group(:game_name).count
  end
end
