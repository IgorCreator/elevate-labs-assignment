#!/usr/bin/env ruby

# Standalone script to test Users API functionality
#
# HOW TO RUN:
# ===========
# 1. Start the Rails server: rails server
# 2. In another terminal, run one of these commands:
#
# EXAMPLES:
#   ruby script/test_users_api.rb api      # Test API endpoints via HTTP
#   ruby script/test_users_api.rb direct   # Test services directly (no server needed)
#   ruby script/test_users_api.rb          # Test both methods
#
# PREREQUISITES:
# - Rails server running (for 'api' or 'both' modes)
# - Database with test users (IDs: 1, 2, 3, 4, 5, 99, 500)
# - Billing service configured

require_relative '../config/environment'

class UsersApiTester
  def initialize
    @test_user_ids = [ 1, 2, 3, 4, 5, 99, 500 ]
  end

  def run_tests(test_type = 'both')
    case test_type.downcase
    when 'api'
      test_api_calls
    when 'direct'
      test_direct_calls
    when 'both'
      test_api_calls
      puts "\n" + "=" * 80
      test_direct_calls
    else
      puts "❌ Invalid test type. Use: api, direct, or both"
      exit 1
    end
  end

  private

  def test_api_calls
    puts "\n🧪 Testing All Users - API Responses with Billing Data"
    puts "=" * 70

    User.where(id: @test_user_ids).order(:id).each do |user|
      test_single_user_api(user)
    end

    puts "\n" + "=" * 70
    puts "✅ API Testing Complete! Check responses above."
    puts "Expected: IDs 1,3,10,20 = success | ID 5 = 503 error | ID 500 = 404 error"
  end

  def test_direct_calls
    puts "\n🧪 Testing All Users - Direct Controller Calls"
    puts "=" * 70

    User.where(id: @test_user_ids).order(:id).each do |user|
      test_single_user_direct(user)
    end

    puts "\n" + "=" * 70
    puts "✅ Direct Testing Complete!"
  end

  def test_single_user_api(user)
    token = JwtService.generate_token(user)
    expected = get_expected_result(user.id)

    puts "\n👤 USER ID #{user.id} (#{user.email})"
    puts "Expected: #{expected}"
    puts "-" * 50

    begin
      uri = URI("http://localhost:3000/api/user")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"

      response = http.request(request)

      puts "Status: #{response.code} #{response.message}"

      begin
        parsed_response = JSON.parse(response.body)
        puts JSON.pretty_generate(parsed_response)
      rescue JSON::ParserError
        puts "Raw Response: #{response.body}"
      end

    rescue => e
      puts "❌ Network Error: #{e.message}"
    end
  end

  def test_single_user_direct(user)
    expected = get_expected_result(user.id)

    puts "\n👤 USER ID #{user.id} (#{user.email})"
    puts "Expected: #{expected}"
    puts "-" * 50

    begin
      stats = UserStatsService.calculate(user)
      subscription_status = BillingService.get_subscription_status(user.id)

      result = {
        user: {
          id: user.id,
          email: user.email,
          stats: stats,
          subscription_status: subscription_status
        }
      }

      puts "Status: 200 OK"
      puts JSON.pretty_generate(result)

    rescue BillingService::BillingServiceError => e
      error_response = case e.error_type
      when :not_found
        { error: "Service temporarily unavailable, internal team notified" }
      when :intermittent_failure, :service_unavailable, :timeout
        { error: "Service temporarily unavailable, internal team notified" }
      else
        { error: "Service temporarily unavailable, internal team notified" }
      end

      status_code = case e.error_type
      when :not_found then "404"
      else "503"
      end

      puts "Status: #{status_code}"
      puts JSON.pretty_generate(error_response)

    rescue => e
      puts "❌ Error: #{e.message}"
      puts e.backtrace.first(3)
    end
  end

  def get_expected_result(user_id)
    case user_id
    when 5 then "503 - Intermittent Failure"
    when (101..) then "404 - Not Found"
    else "200 - Active/Expired"
    end
  end
end

# Main execution
if __FILE__ == $0
  test_type = ARGV.first || 'both'

  puts "🚀 Starting Users API Test Suite"
  puts "Test Type: #{test_type}"
  puts "Time: #{Time.current}"

  begin
    tester = UsersApiTester.new
    tester.run_tests(test_type)
  rescue => e
    puts "❌ Fatal Error: #{e.message}"
    puts e.backtrace.first(5)
    exit 1
  end

  puts "\n🎉 All tests completed successfully!"
end
