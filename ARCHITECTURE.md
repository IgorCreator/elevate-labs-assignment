# Architecture Documentation

Technical design and implementation details for the Elevate Labs backend application.

## System Overview

The application is built as a Rails API with an admin interface, designed to handle user game events and subscription management. It follows a service-oriented architecture with clear separation of concerns.

## Technology Stack

### Core Technologies

- **Ruby on Rails 7.1**: Web framework
- **PostgreSQL**: Primary database
- **Redis**: Caching layer
- **JWT**: API authentication
- **bcrypt**: Password hashing

### Development Tools

- **RSpec**: Testing framework
- **RuboCop**: Code linting
- **FactoryBot**: Test data factories
- **Brakeman**: Security analysis

## Architecture Patterns

### Service-Oriented Architecture

The application uses service objects to encapsulate business logic:

```
app/services/
├── billing_service.rb          # External billing integration
├── jwt_service.rb              # JWT token management
├── response_formatter.rb       # API response formatting
├── user_stats_service.rb       # User statistics calculation
└── logging/                    # Logging services
    ├── base_logger_service.rb
    ├── admin_activity_logger_service.rb
    └── api_logger_service.rb
```

### Layered Architecture

- **Controllers**: Handle HTTP requests and responses
- **Services**: Business logic and external integrations
- **Models**: Data persistence and validation
- **Views**: Admin interface presentation

## Data Models

### User Model

```ruby
class User < ApplicationRecord
  has_many :game_events, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, format: { with: /\A.*[!@#$%^&*].*\z/ }

  has_secure_password
end
```

**Key Features:**

- Email/password authentication with bcrypt
- Email format validation
- Password complexity requirements
- One-to-many relationship with game events

### GameEvent Model

```ruby
class GameEvent < ApplicationRecord
  belongs_to :user

  validates :game_name, presence: true, inclusion: { in: SUPPORTED_GAMES }
  validates :event_type, presence: true, inclusion: { in: ['COMPLETED'] }
  validates :occurred_at, presence: true
end
```

**Key Features:**

- Belongs to user relationship
- Game name validation against supported games
- Event type restricted to 'COMPLETED'
- Timestamp tracking

## Authentication Architecture

### Dual Authentication System

#### API Authentication (JWT)

- **Purpose**: Secure API access for mobile clients
- **Implementation**: JWT tokens with HS256 algorithm
- **Token Structure**: User ID, email, issued at, expiration
- **Security**: Configurable expiration, signature verification

```ruby
class JwtService
  def self.generate_token(user)
    JWT.encode(
      {
        user_id: user.id,
        email: user.email,
        iat: Time.current.to_i,
        exp: expiration_time.to_i
      },
      secret_key,
      'HS256'
    )
  end
end
```

#### Admin Authentication (Session-based)

- **Purpose**: Web-based admin interface access
- **Implementation**: Rails sessions with secure cookies
- **Access Control**: Admin users (ID 1 or email contains "admin")
- **Security**: Session timeout, secure cookie configuration

```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin_authentication

  private

  def require_admin_authentication
    unless current_admin_user
      redirect_to admin_login_path
    end
  end
end
```

## External Service Integration

### Billing Service Integration

#### Service Design

```ruby
class BillingService
  def self.get_subscription_status(user_id)
    cache_key = "billing_status_#{user_id}"

    # Try cache first
    cached_status = Rails.cache.read(cache_key)
    return cached_status if cached_status

    # Fetch from external service
    response = fetch_from_billing_service(user_id)

    # Cache successful response
    Rails.cache.write(cache_key, response, expires_in: cache_expiration)

    response
  rescue BillingServiceError => e
    # Return cached data on failure
    Rails.cache.read(cache_key) || raise(e)
  end
end
```

#### Error Handling Strategy

- **Graceful Degradation**: API continues functioning without subscription data
- **Caching**: Redis cache with 1-hour expiration
- **Fallback**: Return cached data on service failures
- **Error Types**: Not found, unauthorized, intermittent failures, timeouts

#### Test Scenarios

- **User ID 5**: Simulates intermittent failures
- **User ID > 100**: Returns not found errors
- **Other Users**: Normal responses

## Caching Strategy

### Multi-Level Caching

#### Redis Caching

- **Purpose**: External service responses
- **Implementation**: Rails.cache with Redis backend
- **Expiration**: Configurable (default: 1 hour)
- **Key Pattern**: `billing_status_#{user_id}`

#### Application Caching

- **Purpose**: Frequently accessed data
- **Implementation**: Rails fragment caching
- **Scope**: User statistics, game event counts

### Cache Management

```ruby
# Cache invalidation
Rails.cache.delete("billing_status_#{user_id}")

# Cache warming
User.find_each do |user|
  BillingService.get_subscription_status(user.id)
end
```

## API Design

### RESTful Endpoints

#### User Management

- `POST /api/user` - User registration
- `POST /api/sessions` - User login
- `GET /api/user` - User profile and statistics

#### Game Events

- `POST /api/user/game_events` - Create game event

### Response Formatting

```ruby
class ResponseFormatter
  def self.user_success(user, include_token: false)
    response = {
      user: {
        id: user.id,
        email: user.email
      }
    }

    response[:token] = JwtService.generate_token(user) if include_token
    response
  end
end
```

### Error Handling

```ruby
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_errors
  rescue_from BillingService::BillingServiceError, with: :render_billing_error

  private

  def render_validation_errors(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end
end
```

## Security Implementation

### Input Validation

- **Strong Parameters**: Whitelist allowed parameters
- **Model Validations**: Data integrity constraints
- **SQL Injection Protection**: Parameterized queries
- **XSS Protection**: Content Security Policy

### Password Security

```ruby
class User < ApplicationRecord
  has_secure_password

  validates :password,
    presence: true,
    length: { minimum: 8 },
    format: { with: /\A.*[!@#$%^&*].*\z/, message: "must include a symbol" }
end
```

### JWT Security

- **Algorithm**: HS256 (HMAC with SHA-256)
- **Secret Key**: Environment variable or Rails credentials
- **Expiration**: Configurable (default: 12 hours)
- **Claims**: User ID, email, timestamps

## Logging and Monitoring

### Logging Architecture

```ruby
module Logging
  class BaseLoggerService
    def self.log_entry(cache_key, entry, max_entries, log_type)
      # Store in cache
      logs = Rails.cache.read(cache_key) || []
      logs.unshift(entry)
      logs = logs.first(max_entries)
      Rails.cache.write(cache_key, logs, expires_in: 24.hours)

      # Log to Rails logger
      Rails.logger.info("#{log_type}: #{entry}")
    end
  end
end
```

### Log Types

- **Admin Activity**: User management actions
- **API Requests**: API endpoint usage
- **Error Logging**: Exception tracking
- **Performance**: Response time monitoring

## Database Design

### Schema Design

```sql
-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  password_digest VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Game events table
CREATE TABLE game_events (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  game_name VARCHAR NOT NULL,
  event_type VARCHAR NOT NULL,
  occurred_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Indexes

- **Users**: Email index for authentication
- **Game Events**: User ID index for queries
- **Game Events**: Composite index on (user_id, occurred_at)

### Data Integrity

- **Foreign Keys**: Enforce referential integrity
- **Constraints**: NOT NULL, UNIQUE constraints
- **Validations**: Application-level validations

## Performance Optimization

### Database Optimization

- **Eager Loading**: Prevent N+1 queries
- **Indexes**: Optimize query performance
- **Pagination**: Handle large datasets

### Caching Strategy

- **Redis**: External service responses
- **Application**: Frequently accessed data
- **HTTP**: API response caching

### Query Optimization

```ruby
# Eager loading example
User.includes(:game_events).find(user_id)

# Pagination example
User.page(params[:page]).per(25)

# Optimized statistics
User.joins(:game_events)
    .group(:id)
    .select('users.*, COUNT(game_events.id) as event_count')
```

## Testing Strategy

### Test Pyramid

- **Unit Tests**: Models, services, helpers
- **Integration Tests**: Controllers, API endpoints
- **End-to-End Tests**: Complete user flows

### Test Coverage

```ruby
# Model tests
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
  end
end

# API tests
RSpec.describe 'API::Users', type: :request do
  describe 'POST /api/user' do
    it 'creates a new user' do
      post '/api/user', params: { email: 'test@example.com', password: 'password123!' }
      expect(response).to have_http_status(:created)
    end
  end
end
```

## Deployment Architecture

### Environment Configuration

```bash
# Development
RAILS_ENV=development
DATABASE_URL=postgresql://localhost/elevate_labs_development
REDIS_URL=redis://localhost:6379

# Production
RAILS_ENV=production
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://host:port
JWT_SECRET_KEY=production_secret_key
```

### Infrastructure Requirements

- **Web Server**: Puma application server
- **Database**: PostgreSQL with connection pooling
- **Cache**: Redis for session and data caching
- **Load Balancer**: For horizontal scaling

## Scalability Considerations

### Horizontal Scaling

- **Stateless Design**: No server-side state
- **Database Sharding**: User-based sharding strategy
- **Cache Distribution**: Redis cluster for high availability

### Performance Monitoring

- **Response Times**: API endpoint performance
- **Database Queries**: Query optimization
- **Cache Hit Rates**: Cache effectiveness
- **Error Rates**: System reliability

## Future Enhancements

### Planned Features

- **Real-time Notifications**: WebSocket integration
- **Advanced Analytics**: User behavior tracking
- **Multi-tenancy**: Support for multiple organizations
- **API Versioning**: Backward compatibility

### Technical Improvements

- **GraphQL**: Alternative to REST API
- **Microservices**: Service decomposition
- **Event Sourcing**: Audit trail improvements
- **Machine Learning**: Predictive analytics

## Conclusion

The Elevate Labs backend application follows modern Rails best practices with a focus on:

- **Security**: Comprehensive authentication and authorization
- **Performance**: Multi-level caching and optimization
- **Maintainability**: Clear separation of concerns
- **Scalability**: Stateless design and horizontal scaling
- **Reliability**: Robust error handling and monitoring

The architecture supports the current requirements while providing a solid foundation for future enhancements and scaling.
