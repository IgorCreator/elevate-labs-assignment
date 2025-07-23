#!/usr/bin/env ruby
# Script to test billing service for user ID 5
require_relative '../config/environment'

puts "🔍 Testing Billing Service for User ID 5"
puts "=" * 50

user_id = 5

puts "\n1. Testing cached call (normal get_subscription_status):"
begin
  status = BillingService.get_subscription_status(user_id)
  puts "   ✅ Cached status: #{status}"
rescue => e
  puts "   ❌ Cached error: #{e.class} - #{e.message}"
end

puts "\n2. Testing fresh call (bypass cache):"
begin
  status = BillingService.fetch_from_billing_service(user_id)
  puts "   ✅ Fresh status: #{status}"
rescue => e
  puts "   ❌ Fresh error: #{e.class} - #{e.message}"
  if e.respond_to?(:error_type)
    puts "   Error type: #{e.error_type}"
  end
end

puts "\n3. Checking cache status:"
cache_key = "subscription_status:#{user_id}"
cached_value = Rails.cache.read(cache_key)
if cached_value
  puts "   📦 Cached value: #{cached_value}"
else
  puts "   📭 No cached value found"
end

puts "\n4. Clearing cache and testing again:"
Rails.cache.delete(cache_key)
puts "   🗑️  Cache cleared"

begin
  status = BillingService.get_subscription_status(user_id)
  puts "   ✅ After cache clear: #{status}"
rescue => e
  puts "   ❌ After cache clear error: #{e.class} - #{e.message}"
end

puts "\n" + "=" * 50
puts "�� Test completed!"
