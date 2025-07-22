# Usage: load 'lib/test_users_api.rb'; test_all_users

def test_all_users
  require "net/http"
  require "json"

  puts "\n🧪 Testing All Users - API Responses with Billing Data"
  puts "=" * 70

  User.where(id: [ 1, 3, 5, 10, 20, 500 ]).order(:id).each do |user|
    token = JwtService.generate_token(user)
    expected = case user.id
    when 5 then "503 - Intermittent Failure"
    when (101..) then "404 - Not Found"
    else "200 - Active/Expired"
    end

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

  puts "\n" + "=" * 70
  puts "✅ Testing Complete! Check responses above."
  puts "Expected: IDs 1,3,10,20 = success | ID 5 = 503 error | ID 500 = 404 error"
end

def test_all_users_direct
  puts "\n🧪 Testing All Users - Direct Controller Calls"
  puts "=" * 70

  User.where(id: [ 1, 3, 5, 10, 20, 500 ]).order(:id).each do |user|
    expected = case user.id
    when 5 then "503 - Intermittent Failure"
    when (101..) then "404 - Not Found"
    else "200 - Active/Expired"
    end

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

  puts "\n" + "=" * 70
  puts "✅ Direct Testing Complete!"
end
