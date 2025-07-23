#!/usr/bin/env ruby
# Script to fix database sequences that are out of sync
require_relative '../config/environment'

puts "🔧 Fixing Database Sequences"
puts "=" * 40

# Fix users sequence
puts "\n1. Fixing users sequence..."
max_user_id = User.maximum(:id) || 0
ActiveRecord::Base.connection.execute("SELECT setval('users_id_seq', #{max_user_id});")
puts "   ✅ Users sequence set to: #{max_user_id}"

# Fix game_events sequence
puts "\n2. Fixing game_events sequence..."
max_game_event_id = GameEvent.maximum(:id) || 0
ActiveRecord::Base.connection.execute("SELECT setval('game_events_id_seq', #{max_game_event_id});")
puts "   ✅ Game events sequence set to: #{max_game_event_id}"

# Verify the fixes
puts "\n3. Verifying sequences..."
users_seq = ActiveRecord::Base.connection.execute("SELECT last_value FROM users_id_seq;").first['last_value']
game_events_seq = ActiveRecord::Base.connection.execute("SELECT last_value FROM game_events_id_seq;").first['last_value']

puts "   Users sequence: #{users_seq}"
puts "   Game events sequence: #{game_events_seq}"

puts "\n" + "=" * 40
puts "🎯 Sequences fixed successfully!"
puts "   Next user ID will be: #{users_seq + 1}"
puts "   Next game event ID will be: #{game_events_seq + 1}"
