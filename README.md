# Elevate Labs Backend Assignment

A RESTful backend API for a mobile game completion tracking application. Built with Ruby on Rails in API mode.

## Project Overview

This backend supports a mobile app that allows users to:

- Sign up and authenticate securely
- Submit game completion events
- View personal stats and subscription status
- Access admin functionality for content management

## Requirements

- Ruby 3.3.5
- Rails 8.0.2
- PostgreSQL 14+
- Redis (for caching subscription status)

## Setup Instructions

### 1. Clone and Setup

```bash
# Navigate to project directory
cd elevate-labs_assignment

# Ensure correct Ruby version
rbenv local 3.3.5
ruby -v  # Should show 3.3.5

# Install dependencies
bundle install
```

### 2. Database Setup

```bash
# Start PostgreSQL (if using Homebrew)
brew services start postgresql@14

# Create and setup databases
rails db:setup
rails db:migrate  # (will be needed after creating migrations)
```

### 3. Running the Application

```bash
# Start the server
rails server

# The API will be available at http://localhost:3000
```

### 4. Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# With coverage report
bundle exec rspec --format documentation
```

## API Endpoints

### Authentication

- `POST /api/user` - User signup
- `POST /api/sessions` - User login

### Game Events

- `POST /api/user/game_events` - Submit game completion

### User Data

- `GET /api/user` - Get user details, stats, and subscription status

### Admin (Phase 5)

- `/admin/*` - Admin interface and CRUD operations

## Key Design Decisions

### Security

- **Password Security**: Using bcrypt for password hashing with salt
- **Token Authentication**: JWT tokens with 12-hour expiration
- **Rate Limiting**: Protection against brute force attacks on login
- **CORS**: Configured for mobile app cross-origin requests

### Architecture

- **API-Only Mode**: Optimized for mobile client consumption
- **PostgreSQL**: Reliable ACID compliance for user data
- **Redis Caching**: Fast subscription status retrieval
- **External API Integration**: Graceful handling of billing service

### Testing Strategy

- **RSpec**: Comprehensive test suite with request/model/integration specs
- **FactoryBot**: Consistent test data generation
- **Test Database**: Isolated test environment

## Environment Configuration

The application uses Rails encrypted credentials. The `config/master.key` is committed for development convenience.

## External Service Integration

- **Billing Service**: `https://interviews-accounts.elevateapp.com`
- **Caching Strategy**: Redis for subscription status (24h refresh cycle)
- **Error Handling**: Graceful degradation when external services fail

## Development Notes

- CORS is configured permissively for development (`origins '*'`)
- In production, specify actual mobile app origins
- Database migrations will be created as models are developed
- Admin authentication will be implemented in Phase 5

## Project Structure

```
app/
├── controllers/     # API controllers
├── models/         # ActiveRecord models
└── services/       # Business logic services
config/
├── routes.rb       # API routes
└── initializers/   # Configuration
spec/
├── factories/      # Test data factories
├── models/         # Model specs
├── requests/       # API endpoint specs
└── support/        # Test helpers
```

## Implementation Phases

- [x] Phase 0: Project Setup
- [ ] Phase 1: Sign-up and Authentication
- [ ] Phase 2: Game Completion Ingestion
- [ ] Phase 3: User Details and Stats
- [ ] Phase 4: User Subscription Status
- [ ] Phase 5: Admin UI & Endpoints
