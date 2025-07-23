#!/usr/bin/env ruby

require_relative '../config/environment'

puts "🔧 Creating Admin User for Testing"
puts "=" * 40

# Check if admin user already exists
admin_user = User.find_by(email: 'admin@elevate.com')

if admin_user
  puts "✅ Admin user already exists: #{admin_user.email}"
else
  # Create admin user
  admin_user = User.new(
    email: 'admin@elevate.com',
    password: 'Admin123!',
    password_confirmation: 'Admin123!'
  )

  if admin_user.save
    puts "✅ Admin user created successfully: #{admin_user.email}"
    puts "   Password: Admin123!"
  else
    puts "❌ Failed to create admin user:"
    admin_user.errors.full_messages.each { |msg| puts "   - #{msg}" }
  end
end

puts "\n🎉 Admin user ready for testing!"
puts "You can now login to the admin interface at:"
puts "http://localhost:3000/admin"
puts "Email: admin@elevate.com"
puts "Password: Admin123!"
