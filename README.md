# Elevate Labs Backend Assignment

A Rails API application for managing user game events and subscriptions, with an admin interface for data management.

## Features

### API Endpoints

- **User Registration**: `POST /api/user`
- **User Login**: `POST /api/sessions`
- **User Profile**: `GET /api/user`
- **Game Events**: `POST /api/user/game_events`

### Admin Interface

- **Admin Login**: `GET /admin/login`
- **Admin Dashboard**: `GET /admin`
- **User Management**: `GET /admin/users`
- **Game Events Management**: `GET /admin/game_events`
- **Statistics**: `GET /admin/stats`
- **Activity Logs**: `GET /admin/logs`

## Quick Start

### Prerequisites

- Ruby 3.3.5
- PostgreSQL
- Redis (for caching)

### Setup

1. Clone the repository
2. Install dependencies: `bundle install`
3. Set up database: `rails db:create db:migrate db:seed`
4. Start the server: `rails server`

### Admin Access

- **URL**: http://localhost:3000/admin/login
- **Email**: admin@elevate.com
- **Password**: Admin123!

## API Documentation

### Authentication

All API endpoints (except registration and login) require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### User Registration

```bash
POST /api/user
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123!"
}
```

### User Login

```bash
POST /api/sessions
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123!"
}
```

### Create Game Event

```bash
POST /api/user/game_events
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
    "game_name": "Brevity",
  "event_type": "COMPLETED",
  "occurred_at": "2024-01-15T10:30:00Z"
}
```

### Get User Profile

```bash
GET /api/user
Authorization: Bearer <jwt_token>
```

## Admin Interface

The admin interface provides a web-based UI for managing users, game events, and viewing statistics.

### Features

- **Dashboard**: Overview of users, game events, and recent activity
- **User Management**: Create, edit, delete, and view user details
- **Game Events Management**: Manage game events with filtering and search
- **Statistics**: Detailed user and game statistics
- **Activity Logs**: Recent user registrations and game events

### Admin Authentication

- Simple session-based authentication
- Admin access granted to users with ID 1 or email containing "admin"
- Secure logout functionality

## External Services

### Billing Service Integration

- Integrates with external billing API for subscription status
- Caches responses in Redis for performance
- Handles service failures gracefully

### Supported Games

- Brevity (Writing)
- Wordbend (Vocabulary/Logic)
- Retention (Memory)
- Focus (Concentration)
- Name Recall (Memory)

## Testing

### API Testing

```bash
# Test API endpoints
ruby script/test_users_api.rb

# Test admin interface
ruby script/test_admin_interface.rb
```

### Create Admin User

```bash
ruby script/create_admin_user.rb
```

## Architecture

### Models

- **User**: Email/password authentication with bcrypt
- **GameEvent**: Tracks user game activities with validation

### Services

- **JWTService**: JWT token generation and validation
- **BillingService**: External billing API integration
- **UserStatsService**: User statistics calculation
- **ResponseFormatter**: Consistent API response formatting

### Controllers

- **API Controllers**: Handle API requests with JWT authentication
- **Admin Controllers**: Handle admin interface with session authentication

## Security Features

- Password hashing with bcrypt
- JWT token authentication for API
- Session-based authentication for admin
- Input validation and sanitization
- CORS configuration
- SQL injection protection

## Development

### Environment Variables

Create a `.env` file with:

```
JWT_EXPIRATION_HOURS=12
BILLING_SERVICE_BASE_URL=https://interviews-accounts.elevateapp.com/api/v1
BILLING_SERVICE_JWT_TOKEN=your_jwt_token
BILLING_SERVICE_CACHE_EXPIRATION_HOURS=1
BILLING_SERVICE_TIMEOUT_SECONDS=5
BILLING_SERVICE_OPEN_TIMEOUT_SECONDS=5
```

### Database

- PostgreSQL for data persistence
- Redis for caching subscription status

## Phase 5 Implementation Summary

Phase 5 successfully implemented a complete admin interface with:

1. **Admin Authentication System**

   - Session-based authentication
   - Login/logout functionality
   - Access control for admin routes

2. **Admin Dashboard**

   - Overview statistics (users, game events, recent activity)
   - Navigation to all admin sections

3. **User Management**

   - List all users with pagination
   - Create, edit, and delete users
   - View user details with game statistics
   - Search and filter functionality

4. **Game Events Management**

   - List all game events with filtering
   - Create, edit, and delete game events
   - Filter by game name and user

5. **Statistics and Logs**

   - Detailed user statistics with subscription status
   - Activity logs showing recent registrations and game events
   - Game and event type statistics

6. **Responsive Design**
   - Modern, clean UI with CSS styling
   - Mobile-friendly responsive design
   - Consistent navigation and layout

The admin interface is now fully functional and provides comprehensive management capabilities for the Elevate Labs application.
