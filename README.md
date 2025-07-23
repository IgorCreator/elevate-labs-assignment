# Elevate Labs Backend Assignment

A Rails API application for managing user game events and subscriptions, with an admin interface for data management.

## 🚀 Quick Start

### Prerequisites

- Ruby 3.3.5
- PostgreSQL
- Redis (for caching)

### Setup

1. **Clone and install dependencies:**

   ```bash
   bundle install
   ```

2. **Set up database:**

   ```bash
   rails db:create db:migrate db:seed
   ```

3. **Start the server:**

   ```bash
   rails server
   ```

4. **Access the application:**
   - **API**: http://localhost:3000/api
   - **Admin**: http://localhost:3000/admin/login

### Admin Access

- **Email**: admin@elevate.com
- **Password**: Admin123!

## 📋 Features

### API Endpoints

- **User Registration**: `POST /api/user`
- **User Login**: `POST /api/sessions`
- **User Profile**: `GET /api/user`
- **Game Events**: `POST /api/user/game_events`

### Admin Interface

- **Dashboard**: Overview and statistics
- **User Management**: Create, edit, delete users
- **Game Events**: Manage game activities
- **Activity Logs**: Monitor system activity

## 🧪 Testing

### Quick API Testing with cURL

#### Manual Testing

```bash
# 1. Register a new user
curl -X POST http://localhost:3000/api/user \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123!"}' | jq

# 2. Login and get token
curl -X POST http://localhost:3000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123!"}' | jq

# 3. Get user profile (replace YOUR_TOKEN)
curl -X GET http://localhost:3000/api/user \
  -H "Authorization: Bearer YOUR_TOKEN" | jq

# 4. Create game event (replace YOUR_TOKEN)
curl -X POST http://localhost:3000/api/user/game_events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"game_event": {"game_name": "Wordbend", "type": "COMPLETED", "occurred_at": "2025-01-22T10:00:00.000Z"}}' | jq
```

### Automated Testing

```bash
# Run all tests
bundle exec rspec

# Test API endpoints
ruby script/test_users_api.rb

# Run linter
bundle exec rubocop
```

For comprehensive API testing with curl use:

```bash
# Run the complete test suite
./script/test_with_curl.sh
```

**Requirements:**

- `jq` for JSON formatting: `brew install jq` (macOS)
- `rails server` running on `http://localhost:3000`
- Seeded users from `rails db:seed`

## 📚 Documentation

- **[API Documentation](API_DOCUMENTATION.md)** - Complete API reference
- **[Admin Guide](ADMIN_GUIDE.md)** - Admin interface usage with screenshots
- **[Development Guide](DEVELOPMENT.md)** - Setup and development workflow
- **[Architecture](ARCHITECTURE.md)** - Technical design and decisions
- **[Screenshots](docs/screenshots/)** - Admin interface visual documentation

## 🔧 Environment Variables

Create a `.env` file with:

```bash
JWT_EXPIRATION_HOURS=12
BILLING_SERVICE_BASE_URL=https://interviews-accounts.elevateapp.com/api/v1
BILLING_SERVICE_JWT_TOKEN=your_jwt_token
BILLING_SERVICE_CACHE_EXPIRATION_HOURS=1
BILLING_SERVICE_TIMEOUT_SECONDS=5
BILLING_SERVICE_OPEN_TIMEOUT_SECONDS=5
```

## 🎯 Key Features

- **JWT Authentication** for API security
- **External Billing Integration** with caching and error handling
- **Admin Interface** for data management
- **Activity Logging** for audit trails
- **Comprehensive Testing** with RSpec
- **Code Quality** with RuboCop linting

## 📖 Assignment Phases

This project implements all required phases from the assignment:

- ✅ **Phase 1**: User registration and authentication
- ✅ **Phase 2**: Game completion ingestion
- ✅ **Phase 3**: User details and statistics
- ✅ **Phase 4**: Subscription status integration
- ✅ **Phase 5**: Admin interface
- ✅ **Phase 6**: Code quality and documentation

For detailed step-by-step implementation, see [README_TASKS_TRACKING.md](README_TASKS_TRACKING.md).
