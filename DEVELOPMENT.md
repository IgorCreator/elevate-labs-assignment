# Development Guide

Complete guide for setting up and developing the Elevate Labs backend application.

## Prerequisites

### Required Software

- **Ruby 3.3.5** (recommended)
- **PostgreSQL** (database)
- **Redis** (caching)
- **Git** (version control)

### Installation

#### macOS

```bash
# Install Ruby with rbenv
brew install rbenv
rbenv install 3.3.5
rbenv global 3.3.5

# Install PostgreSQL
brew install postgresql
brew services start postgresql

# Install Redis
brew install redis
brew services start redis
```

#### Ubuntu/Debian

```bash
# Install Ruby dependencies
sudo apt-get update
sudo apt-get install ruby ruby-dev build-essential

# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Install Redis
sudo apt-get install redis-server
```

## Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd elevate-labs_assignment
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Environment Configuration

Create a `.env` file in the root directory:

```bash
# JWT Configuration
JWT_EXPIRATION_HOURS=12

# Billing Service Configuration
BILLING_SERVICE_BASE_URL=https://interviews-accounts.elevateapp.com/api/v1
BILLING_SERVICE_JWT_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJiaWxsaW5nIiwiaWF0IjoxNzQzMDg1NDk5LCJleHAiOm51bGwsImF1ZCI6Ind3dy5leGFtcGxlLmNvbSIsInN1YiI6ImJpbGxpbmdfY2xpZW50In0.aRwnR_QP6AlOv_JanMkbhwe9ACDcJc5184pXdR0ksXg
BILLING_SERVICE_CACHE_EXPIRATION_HOURS=1
BILLING_SERVICE_TIMEOUT_SECONDS=5
BILLING_SERVICE_OPEN_TIMEOUT_SECONDS=5
```

### 4. Database Setup

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed initial data
rails db:seed
```

### 5. Start Services

```bash
# Start Rails server
rails server

# Start Redis (if not running as service)
redis-server

# Start PostgreSQL (if not running as service)
pg_ctl -D /usr/local/var/postgres start
```

## Development Workflow

### Code Quality

#### Linting

The project uses RuboCop for code quality and style consistency:

```bash
# Run linter on all files
bundle exec rubocop

# Run linter with detailed output
bundle exec rubocop --format progress --display-cop-names

# Auto-fix simple issues
bundle exec rubocop -a

# Check specific file or directory
bundle exec rubocop app/controllers/
bundle exec rubocop app/models/
```

#### Code Style Guidelines

- **Ruby Style**: Follows Ruby Style Guide and RuboCop defaults
- **Rails Conventions**: Adheres to Rails best practices
- **Consistent Formatting**: 2-space indentation, trailing commas
- **Naming Conventions**: snake_case for methods/variables, PascalCase for classes
- **Documentation**: YARD-style comments for complex methods

### Testing

#### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests with coverage
COVERAGE=true bundle exec rspec

# Run tests in parallel
bundle exec parallel_rspec spec/
```

#### Test Structure

```
spec/
├── models/           # Model tests
├── controllers/      # Controller tests
├── services/         # Service tests
├── requests/         # API request tests
├── factories/        # Test data factories
└── support/          # Test helpers
```

#### Writing Tests

```ruby
# Example model test
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe 'associations' do
    it { should have_many(:game_events) }
  end
end
```

### API Testing

#### Manual Testing

```bash
# Test API endpoints
ruby script/test_users_api.rb

# Test specific scenarios
ruby script/test_users_api.rb api
ruby script/test_users_api.rb direct
```

#### Automated Testing

```bash
# Run API request tests
bundle exec rspec spec/requests/

# Test specific endpoint
bundle exec rspec spec/requests/api/users_spec.rb
```

### Database Management

#### Migrations

```bash
# Generate new migration
rails generate migration AddFieldToTable

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback

# Reset database
rails db:reset
```

#### Seeds

```bash
# Run seeds
rails db:seed

# Reset and seed
rails db:reset
```

### Caching

#### Redis Operations

```bash
# Connect to Redis CLI
redis-cli

# Check cache keys
redis-cli keys "*"

# Clear cache
redis-cli flushall
```

#### Cache Management

```bash
# Clear Rails cache
rails runner "Rails.cache.clear"

# Check cache status
rails runner "puts Rails.cache.exist?('test_key')"
```

## Architecture

### Project Structure

```
app/
├── controllers/      # API and admin controllers
│   ├── api/         # API endpoints
│   └── admin/       # Admin interface
├── models/          # ActiveRecord models
├── services/        # Business logic services
│   └── logging/     # Logging services
├── views/           # Admin interface views
└── assets/          # CSS, JS, images
```

### Key Components

#### Services

- **JWTService**: Token generation and validation
- **BillingService**: External billing API integration
- **UserStatsService**: User statistics calculation
- **ResponseFormatter**: Consistent API responses
- **Logging Services**: Activity and API logging

#### Models

- **User**: User authentication and profile
- **GameEvent**: Game completion tracking

#### Controllers

- **API Controllers**: Handle API requests with JWT auth
- **Admin Controllers**: Handle admin interface with session auth

## Security

### Authentication

- **JWT Tokens**: For API authentication
- **Session Cookies**: For admin interface
- **bcrypt**: Password hashing
- **Strong Parameters**: Input validation

### Data Protection

- **SQL Injection**: Parameterized queries
- **XSS Protection**: Content Security Policy
- **CSRF Protection**: Cross-site request forgery
- **Input Validation**: Model and controller validation

## Performance

### Caching Strategy

- **Redis**: For subscription status caching
- **Rails Cache**: For application data
- **HTTP Caching**: For API responses

### Database Optimization

- **Indexes**: On frequently queried fields
- **Eager Loading**: To prevent N+1 queries
- **Pagination**: For large datasets

## Monitoring

### Logging

- **Rails Logs**: Application logs
- **Admin Activity**: Admin action logging
- **API Requests**: API call logging
- **Error Tracking**: Exception logging

### Health Checks

```bash
# Check application status
curl http://localhost:3000/health

# Check database connectivity
rails runner "puts ActiveRecord::Base.connection.active?"

# Check Redis connectivity
rails runner "puts Rails.cache.write('test', 'value')"
```

## Docker Setup

### Prerequisites

- **Docker** and **Docker Compose** installed
- **Rails master key** (found in `config/credentials.yml.enc` or generate with `rails credentials:edit`)

### Quick Start

1. **Set up environment variables:**

   ```bash
   # Copy the example environment file
   cp .env.example .env

   # Edit .env and set your Rails master key
   # You can find your master key in config/credentials.yml.enc
   # or generate a new one with: rails credentials:edit
   ```

2. **Build and start containers:**

   ```bash
   docker-compose up --build
   ```

3. **Set up the database (first time only):**

   ```bash
   # In a new terminal
   docker compose exec web rails db:schema:load
   docker compose exec web rails db:seed
   ```

4. **Access the application:**
   ```bash
   open http://localhost:3000
   ```

### Environment Variables

The following environment variables can be set in your `.env` file:

```bash
# Required for production mode
RAILS_MASTER_KEY=your_rails_master_key_here

# Database configuration (optional - defaults used in docker-compose.yml)
DATABASE_URL=postgres://elevate_labs_assignment:password123@db:5432/elevate_labs_assignment_production
ELEVATE_LABS_ASSIGNMENT_DATABASE_PASSWORD=password123
DATABASE_HOST=db
DATABASE_PORT=5432

# JWT secret (optional - will be generated if not provided)
JWT_SECRET_KEY=your_JWT_SECRET_KEY_here

# Billing service configuration (optional - for testing)
BILLING_SERVICE_URL=https://billing-service.elevate.com
BILLING_SERVICE_API_KEY=your_billing_service_api_key_here
```

### Docker Commands

```bash
# Start services
docker-compose up

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f web

# Stop services
docker-compose down

# Rebuild containers
docker-compose up --build

# Access Rails console
docker compose exec web rails console

# Run database commands
docker compose exec web rails db:migrate
docker compose exec web rails db:seed

# Run tests
docker compose exec web bundle exec rspec
```

### Security Notes

- **Never commit your actual `RAILS_MASTER_KEY`** to version control
- The `.env` file is already in `.gitignore` to prevent accidental commits
- Use `.env.example` as a template for required environment variables

## Deployment

### Environment Variables

```bash
# Production environment variables
RAILS_ENV=production
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://host:port
JWT_SECRET_KEY=your_secret_key
```

### Database Setup

```bash
# Production database setup
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

## Troubleshooting

### Common Issues

#### Database Connection

```bash
# Check PostgreSQL status
brew services list | grep postgresql

# Restart PostgreSQL
brew services restart postgresql
```

#### Redis Connection

```bash
# Check Redis status
brew services list | grep redis

# Restart Redis
brew services restart redis
```

#### Gem Issues

```bash
# Update gems
bundle update

# Reinstall gems
bundle install --force
```

### Debugging

#### Rails Console

```bash
# Start Rails console
rails console

# Debug specific models
User.find(1)
GameEvent.where(user_id: 1)
```

#### Logs

```bash
# View Rails logs
tail -f log/development.log

# View specific log levels
tail -f log/development.log | grep ERROR
```

## Contributing

### Code Review Process

1. **Create Feature Branch**: `git checkout -b feature/new-feature`
2. **Write Tests**: Ensure all new code is tested
3. **Run Linter**: `bundle exec rubocop`
4. **Run Tests**: `bundle exec rspec`
5. **Submit Pull Request**: With clear description

### Commit Guidelines

- **Conventional Commits**: Use conventional commit format
- **Descriptive Messages**: Clear, concise commit messages
- **Atomic Commits**: One logical change per commit

### Code Standards

- **RuboCop Compliance**: All code must pass linting
- **Test Coverage**: Maintain high test coverage
- **Documentation**: Document complex logic
- **Security**: Follow security best practices
