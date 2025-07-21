FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "Password123!" }  # Meets requirements: 8+ chars with symbol
    password_confirmation { password }
  end
end
