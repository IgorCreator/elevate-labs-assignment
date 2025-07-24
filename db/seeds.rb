# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create test users with specific IDs for billing service testing
# IDs 1, 3, 10, 20 → "active" or "expired" responses (normal billing)
# ID 5 → "intermittent failure" (503) from billing service
# ID 500 (> 100) → "not found" error (404) from billing service

test_users = [
  { id: 1, email: "user001@example.com", password: "password123!" },
  { id: 2, email: "user002@example.com", password: "password123!" },
  { id: 3, email: "user003@example.com", password: "password123!" },
  { id: 4, email: "user004@example.com", password: "password123!" },
  { id: 5, email: "user005@example.com", password: "password123!" },
  { id: 99, email: "user099@example.com", password: "password123!" },
  { id: 500, email: "user500@example.com", password: "password123!" }
]

created_users = test_users.map do |user_data|
  # Check if user already exists
  user = User.find_by(id: user_data[:id]) || User.find_by(email: user_data[:email])

  if user
    puts "✅ User already exists: ID #{user.id} - #{user.email}"
  else
    # Create user with specific ID
    user = User.new(
      email: user_data[:email],
      password: user_data[:password],
      password_confirmation: user_data[:password]
    )
    user.id = user_data[:id]
    user.save!
    puts "✅ Created User: ID #{user.id} - #{user.email}"
  end

  user
end

# Generate JWT tokens for easy testing
puts "\n🔑 JWT Tokens for Testing:"
created_users.each do |user|
  token = JwtService.generate_token(user)
  expected_behavior = case user.id
  when 5
                       "intermittent_failure (503)"
  when (101..)
                       "not_found (404)"
  else
                       "active/expired (200)"
  end
  puts "ID #{user.id.to_s.rjust(3)}: Bearer #{token}"
  puts "      Expected billing response: #{expected_behavior}"
end

# Create game events for realistic testing data
# Add some game events to test users for comprehensive testing
game_events_data = [
  # User ID 1 - Active player
  { user: created_users[0], game_name: "Brevity", occurred_at: 1.hour.ago },
  { user: created_users[0], game_name: "Brevity", occurred_at: 3.hours.ago },
  { user: created_users[0], game_name: "Focus", occurred_at: 1.day.ago },
  { user: created_users[0], game_name: "Wordbend", occurred_at: 2.days.ago },

  # User ID 3 - Moderate player
  { user: created_users[1], game_name: "Focus", occurred_at: 2.hours.ago },
  { user: created_users[1], game_name: "Brevity", occurred_at: 1.day.ago },

  # User ID 5 - Light player
  { user: created_users[2], game_name: "Retention", occurred_at: 5.days.ago },

  # User ID 500 - Test user for not_found scenario
  { user: created_users[5], game_name: "Name Recall", occurred_at: 1.week.ago }
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

puts "\n👤 Test Users for Billing Service:"
created_users.each do |user|
  game_count = user.game_events.count
  billing_scenario = case user.id
  when 5
                      "INTERMITTENT_FAILURE (503)"
  when (101..)
                      "NOT_FOUND (404)"
  else
                      "ACTIVE/EXPIRED (200)"
  end
  puts "  ID #{user.id.to_s.rjust(3)}: #{user.email} - #{game_count} games - #{billing_scenario}"
end

puts "\n🎮 Game events by game:"
GameEvent.group(:game_name).count.each do |game, count|
  puts "  #{game}: #{count} completions"
end

# Create admin user for admin interface
admin_user = User.find_by(email: 'admin@elevate.com')
if admin_user
  puts "✅ Admin user already exists: #{admin_user.email}"
else
  # Use ID 999 to avoid conflicts with test users
  admin_user = User.new(
    id: 6,
    email: 'admin@elevate.com',
    password: 'Admin123!',
    password_confirmation: 'Admin123!',
    admin: true
  )
  admin_user.save!
  puts "✅ Created Admin User: #{admin_user.email} (ID: #{admin_user.id})"
end

# Fix PostgreSQL sequences to prevent ID conflicts
def fix_sequences
  return unless ActiveRecord::Base.connection.adapter_name.downcase.include?('postgresql')

  # Fix users sequence
  existing_user_ids = User.pluck(:id).sort
  next_user_id = 1
  existing_user_ids.each { |id| break if id > next_user_id; next_user_id = id + 1 }
  ActiveRecord::Base.connection.execute("SELECT setval('users_id_seq', #{next_user_id}, false)")
  puts "🔧 Fixed users sequence to: #{next_user_id}"

  # Fix game_events sequence
  existing_event_ids = GameEvent.pluck(:id).sort
  next_event_id = 1
  existing_event_ids.each { |id| break if id > next_event_id; next_event_id = id + 1 }
  ActiveRecord::Base.connection.execute("SELECT setval('game_events_id_seq', #{next_event_id}, false)")
  puts "🔧 Fixed game_events sequence to: #{next_event_id}"
end

fix_sequences

puts "\n🧪 Ready for Testing!"
puts "Use the JWT tokens above to test different billing service error scenarios."
puts "🎉 Seeding completed!"
