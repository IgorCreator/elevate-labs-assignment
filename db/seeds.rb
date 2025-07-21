# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create test users
users = [
  {
    email: "alice@example.com",
    password: "password123!"
  },
  {
    email: "bob@example.com",
    password: "password123!"
  },
  {
    email: "charlie@example.com",
    password: "password123!"
  }
]

created_users = users.map do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.password = user_data[:password]
    u.password_confirmation = user_data[:password]
  end
  puts "✅ User: #{user.email}"
  user
end

# Create game events for realistic testing data
game_events_data = [
  # Alice's game history - active player
  { user: created_users[0], game_name: "Brevity", occurred_at: 1.hour.ago },
  { user: created_users[0], game_name: "Brevity", occurred_at: 3.hours.ago },
  { user: created_users[0], game_name: "Focus", occurred_at: 1.day.ago },
  { user: created_users[0], game_name: "Wordbend", occurred_at: 2.days.ago },
  { user: created_users[0], game_name: "Retention", occurred_at: 3.days.ago },
  { user: created_users[0], game_name: "Name Recall", occurred_at: 1.week.ago },

  # Bob's game history - moderate player
  { user: created_users[1], game_name: "Focus", occurred_at: 2.hours.ago },
  { user: created_users[1], game_name: "Brevity", occurred_at: 1.day.ago },
  { user: created_users[1], game_name: "Wordbend", occurred_at: 3.days.ago },

  # Charlie's game history - occasional player
  { user: created_users[2], game_name: "Retention", occurred_at: 5.days.ago },
  { user: created_users[2], game_name: "Name Recall", occurred_at: 1.month.ago }
]

game_events_data.each do |event_data|
  # Use a combination of user_id, game_name, and occurred_at to avoid duplicates
  game_event = GameEvent.find_or_create_by(
    user: event_data[:user],
    game_name: event_data[:game_name],
    occurred_at: event_data[:occurred_at]
  ) do |ge|
    ge.event_type = "COMPLETED"
  end

  puts "🎮 Game Event: #{event_data[:user].email} completed #{event_data[:game_name]}"
end

# Summary
puts "\n📊 Seed Summary:"
puts "Users created: #{User.count}"
puts "Game events created: #{GameEvent.count}"
puts "\nGame events by user:"
User.joins(:game_events).group('users.email').count('game_events.id').each do |email, count|
  puts "  #{email}: #{count} games"
end

puts "\nGame events by game:"
GameEvent.group(:game_name).count.each do |game, count|
  puts "  #{game}: #{count} completions"
end

puts "\n🎉 Seeding completed!"
