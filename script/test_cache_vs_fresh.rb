#!/usr/bin/env ruby
# Test script to demonstrate cache vs fresh calls
require_relative '../config/environment'

puts "🔍 Testing Cache vs Fresh Calls for User ID 5"
puts "=" * 60

user_id = 5

puts "\n1. First, let's clear any existing cache:"
cache_key = "subscription_status:#{user_id}"
Rails.cache.delete(cache_key)
puts "   🗑️  Cache cleared"

puts "\n2. Making a fresh call (should show current status):"
begin
  result = BillingService.fetch_from_billing_service(user_id)
  puts "   ✅ Fresh call result: #{result}"
rescue => e
  puts "   ❌ Fresh call error: #{e.message}"
end

puts "\n3. Making a cached call (should use cache if available):"
begin
  result = BillingService.get_subscription_status(user_id)
  puts "   ✅ Cached call result: #{result}"
rescue => e
  puts "   ❌ Cached call error: #{e.message}"
end

puts "\n4. Making another fresh call (should show current status again):"
begin
  result = BillingService.fetch_from_billing_service(user_id)
  puts "   ✅ Fresh call result: #{result}"
rescue => e
  puts "   ❌ Fresh call error: #{e.message}"
end

puts "\n5. Making another cached call (should use same cached value):"
begin
  result = BillingService.get_subscription_status(user_id)
  puts "   ✅ Cached call result: #{result}"
rescue => e
  puts "   ❌ Cached call error: #{e.message}"
end

puts "\n6. Checking what's in cache:"
cached_value = Rails.cache.read(cache_key)
if cached_value
  puts "   📦 Cached value: #{cached_value}"
else
  puts "   📭 No cached value found"
end

puts "\n" + "=" * 60
puts "🎯 Summary:"
puts "   - Fresh calls (🔄 Update button): Always make network request"
puts "   - Cached calls (normal display): Use cache if available"
puts "   - Clear Cache button (🗑️): Removes cached value"
puts "   - User ID 5 should show intermittent failures in fresh calls"
puts "\n" + "=" * 60
