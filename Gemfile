source "https://rubygems.org"

ruby "3.3.5"

gem "rails", "~> 8.0.2"
gem "sprockets-rails", ">= 2.0.0"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"

# Authentication & Security
gem "bcrypt", "~> 3.1.7"
gem "jwt"

# CORS
gem "rack-cors"

# Admin Interface
gem "kaminari"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "dotenv-rails" # Environment variable management
end

group :development do
  gem "web-console"
end
