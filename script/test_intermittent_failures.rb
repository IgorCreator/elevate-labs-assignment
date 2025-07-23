#!/usr/bin/env ruby
# Test script to check for intermittent failures
require_relative '../config/environment'

puts "🔍 Testing Intermittent Failures for User ID 5"
puts "=" * 60

user_id = 5
num_tests = 10

puts "\nMaking #{num_tests} calls to billing service for user #{user_id}:"
puts "-" * 40

results = { success: 0, failure: 0, errors: {} }

num_tests.times do |i|
  print "Call #{i + 1}: "

  begin
    result = BillingService.fetch_from_billing_service(user_id)
    puts "✅ #{result}"
    results[:success] += 1
  rescue BillingService::BillingServiceError => e
    puts "❌ #{e.message} (#{e.error_type})"
    results[:failure] += 1
    results[:errors][e.error_type] ||= 0
    results[:errors][e.error_type] += 1
  rescue => e
    puts "💥 Unexpected error: #{e.class} - #{e.message}"
    results[:failure] += 1
  end

  # Small delay between calls
  sleep(0.1)
end

puts "\n" + "=" * 60
puts "📊 Results Summary:"
puts "   Total calls: #{num_tests}"
puts "   Success: #{results[:success]}"
puts "   Failures: #{results[:failure]}"
puts "   Success rate: #{(results[:success].to_f / num_tests * 100).round(1)}%"

if results[:errors].any?
  puts "\n   Error breakdown:"
  results[:errors].each do |error_type, count|
    puts "     #{error_type}: #{count}"
  end
end

puts "\n🎯 Expected behavior for user ID 5:"
puts "   - Should have intermittent failures"
puts "   - Should sometimes return 'expired'"
puts "   - Should sometimes return 'Service temporarily unavailable'"

puts "\n" + "=" * 60
