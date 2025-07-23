#!/usr/bin/env ruby
# Detailed debug script for billing service
require_relative '../config/environment'

puts "🔍 Detailed Billing Service Debug for User ID 5"
puts "=" * 60

user_id = 5

# Test the actual HTTP call
puts "\n1. Making direct HTTP call to billing service:"
uri = URI("#{BillingService.base_url}/users/#{user_id}/billing")
puts "   URL: #{uri}"

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.open_timeout = BillingService.open_timeout
http.read_timeout = BillingService.read_timeout

request = Net::HTTP::Get.new(uri)
request["Authorization"] = "Bearer #{BillingService.jwt_token}"
request["Content-Type"] = "application/json"

puts "   Making request..."
response = http.request(request)
puts "   Response Code: #{response.code} (#{response.code.class})"
puts "   Response Body: #{response.body}"
puts "   Response Headers: #{response.to_hash}"

puts "\n2. Testing BillingService.fetch_from_billing_service with detailed logging:"
Rails.logger.level = Logger::DEBUG
begin
  result = BillingService.fetch_from_billing_service(user_id)
  puts "   ✅ Result: #{result}"
rescue => e
  puts "   ❌ Error: #{e.class} - #{e.message}"
  if e.respond_to?(:error_type)
    puts "   Error type: #{e.error_type}"
  end
  puts "   Backtrace: #{e.backtrace.first(3).join("\n   ")}"
end

puts "\n3. Testing BillingService.get_subscription_status:"
begin
  result = BillingService.get_subscription_status(user_id)
  puts "   ✅ Result: #{result}"
rescue => e
  puts "   ❌ Error: #{e.class} - #{e.message}"
  if e.respond_to?(:error_type)
    puts "   Error type: #{e.error_type}"
  end
end

puts "\n" + "=" * 60
puts "🎯 Debug completed!"
