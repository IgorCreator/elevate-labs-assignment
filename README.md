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
rails db:migrate
```

### 3. Seed Test Data (Optional)

Load sample users and game events for testing:

```bash
rails db:seed
```

**Test Users Created:**

- `alice@example.com` - Active player (6 games)
- `bob@example.com` - Moderate player (3 games)
- `charlie@example.com` - Occasional player (2 games)
- **Password for all**: `password123!`

**Sample Data Includes:**

- 11+ game events across all 5 valid games
- Various timestamps (1 hour ago to 1 month ago)
- Realistic usage patterns for testing

### 4. Running the Application

```bash
# Start the server
rails server

# The API will be available at http://localhost:3000
```

### 5. Testing

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

### Game Events (Phase 2)

- `POST /api/user/game_events` - Submit game completion

**Request Format:**

```json
{
  "game_event": {
    "game_name": "Brevity",
    "type": "COMPLETED",
    "occurred_at": "2025-01-01T00:00:00.000Z"
  }
}
```

**Response Format:**

```json
{
  "message": "Game event created successfully",
  "game_event": {
    "id": 123,
    "game_name": "Brevity",
    "type": "COMPLETED",
    "occurred_at": "2025-01-01T00:00:00.000Z",
    "created_at": "2025-01-01T00:00:05.000Z"
  }
}
```

### User Data

- `GET /api/user` - Get user details, stats, and subscription status

### Admin (Phase 5)

- `/admin/*` - Admin interface and CRUD operations

## Valid Game Names

The API accepts the following game names:

- Brevity
- Wordbend
- Retention
- Focus
- Name Recall

## Quick API Testing

Using seed data for quick testing:

```bash
# Login as Alice (most active user)
curl -X POST http://localhost:3000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "password123!"
  }'

# Use the returned token for authenticated requests
curl -X POST http://localhost:3000/api/user/game_events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "game_event": {
      "game_name": "Focus",
      "type": "COMPLETED",
      "occurred_at": "2025-01-21T10:00:00.000Z"
    }
  }'
```

## Key Design Decisions

### Security

- **Password Security**: Using bcrypt for password hashing with salt
- **Token Authentication**: JWT tokens with 12-hour expiration
- **Rate Limiting**: Protection against brute force attacks on login (planned)
- **CORS**: Configured for mobile app cross-origin requests

### Architecture

- **API-Only Mode**: Optimized for mobile client consumption
- **PostgreSQL**: Reliable ACID compliance for user data
- **Redis Caching**: Fast subscription status retrieval (planned)
- **External API Integration**: Graceful handling of billing service (planned)

### Database Design

- **User Model**: Handles authentication with secure password storage
- **GameEvent Model**: Tracks game completions with validation
  - Uses `event_type` column (renamed from `type` to avoid Rails STI conflicts)
  - Validates game names against predefined list
  - Validates timestamps (no future dates, reasonable past limit of 5 years)
  - Proper indexing for query performance

### API Design

- **Nested Parameters**: Follows assignment specification with `game_event` wrapper
- **Consistent Error Handling**: Standardized JSON error responses
- **Status Codes**: Proper HTTP status codes (201 for creation, 422 for validation errors, 401 for auth)
- **JSON Content-Type**: All responses use JSON

### Testing Strategy

- **RSpec**: Comprehensive test suite with request/model/integration specs
- **FactoryBot**: Consistent test data generation with traits for different scenarios
- **Shoulda Matchers**: Clean, readable model validation tests
- **Test Coverage**: Full coverage of validations, edge cases, and error scenarios
- **Test Database**: Isolated test environment

## Phase Implementation Status

### Phase 1 - Authentication ✅

- User signup and login endpoints
- JWT token generation and validation
- Secure password storage with bcrypt
- Authentication middleware for protected routes

### Phase 2 - Game Event Ingestion ✅

- GameEvent model with comprehensive validations
- POST endpoint for game completion events
- Support for nested JSON payload format
- Comprehensive test coverage including edge cases
- Database optimizations with proper indexing

### Phase 3 - User Stats (Planned)

- GET endpoint for user details and stats
- Total games played calculation
- Per-game statistics

### Phase 4 - Subscription Status (Planned)

- External billing service integration
- Subscription status caching with Redis
- Graceful error handling for service failures

### Phase 5 - Admin Interface (Planned)

- Admin authentication system
- CRUD operations for users and game events
- Admin dashboard and reporting

## Environment Configuration

The application uses Rails encrypted credentials. The `config/master.key` is committed for development convenience.

## External Service Integration

- **Billing Service**: `https://interviews-accounts.elevateapp.com` (planned)
- **Caching Strategy**: Redis for subscription status (planned)
- **Error Handling**: Graceful degradation when external services fail (planned)

## Development Notes

- CORS is configured permissively for development (`origins '*'`)
- In production, specify actual mobile app origins
- Database migrations handle column renaming to avoid Rails STI conflicts
- Comprehensive validation covers business rules and edge cases
- Seed data is idempotent - safe to run multiple times

## Project Structure

```
app/
├── controllers/     # API controllers
│   └── api/        # Versioned API endpoints
├── models/         # ActiveRecord models
├── services/       # Business logic services (JWT)
└── jobs/          # Background jobs
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

- [x] **Phase 0**: Project Setup
- [x] **Phase 1**: Sign-up and Authentication
- [x] **Phase 2**: Game Completion Ingestion
- [ ] **Phase 3**: User Details and Stats
- [ ] **Phase 4**: User Subscription Status
- [ ] **Phase 5**: Admin UI & Endpoints
