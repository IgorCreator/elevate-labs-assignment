# API Documentation

Complete reference for the Elevate Labs API endpoints.

## Authentication

All API endpoints (except registration and login) require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Endpoints Overview

| Method | Endpoint                | Description          | Auth Required |
| ------ | ----------------------- | -------------------- | ------------- |
| POST   | `/api/user`             | User registration    | No            |
| POST   | `/api/sessions`         | User login           | No            |
| GET    | `/api/user`             | User profile & stats | Yes           |
| POST   | `/api/user/game_events` | Create game event    | Yes           |

## Detailed Endpoint Reference

### User Registration

**Endpoint**: `POST /api/user`
**Content-Type**: `application/json`
**Authentication**: Not required

**Request Body**:

```json
{
  "email": "user@example.com",
  "password": "password123!"
}
```

**Success Response** (201 Created):

```json
{
  "user": {
    "id": 123,
    "email": "user@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Error Response** (422 Unprocessable Entity):

```json
{
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 8 characters)"
  ]
}
```

### User Login

**Endpoint**: `POST /api/sessions`
**Content-Type**: `application/json`
**Authentication**: Not required

**Request Body**:

```json
{
  "email": "user@example.com",
  "password": "password123!"
}
```

**Success Response** (200 OK):

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Error Response** (401 Unauthorized):

```json
{
  "error": "Invalid email or password"
}
```

### Get User Profile

**Endpoint**: `GET /api/user`
**Authentication**: Required (JWT token)

**Success Response** (200 OK):

```json
{
  "user": {
    "id": 123,
    "email": "user@example.com",
    "stats": {
      "total_games_played": 5,
      "games": {
        "Brevity": 3,
        "Focus": 2
      }
    },
    "subscription_status": "active"
  }
}
```

**Error Response** (401 Unauthorized):

```json
{
  "error": "Missing authorization token"
}
```

**Error Response** (503 Service Unavailable):

```json
{
  "error": "Service temporarily unavailable, internal team notified"
}
```

### Create Game Event

**Endpoint**: `POST /api/user/game_events`
**Content-Type**: `application/json`
**Authentication**: Required (JWT token)

**Request Body**:

```json
{
  "game_event": {
    "game_name": "Brevity",
    "type": "COMPLETED",
    "occurred_at": "2024-01-15T10:30:00Z"
  }
}
```

**Success Response** (201 Created):

```json
{
  "message": "Game event created successfully",
  "game_event": {
    "id": 456,
    "user_id": 123,
    "game_name": "Brevity",
    "event_type": "COMPLETED",
    "occurred_at": "2024-01-15T10:30:00Z"
  }
}
```

**Error Response** (422 Unprocessable Entity):

```json
{
  "errors": [
    "Game name is not included in the list",
    "Event type must be COMPLETED"
  ]
}
```

**Error Response** (400 Bad Request):

```json
{
  "error": "Missing required parameter: game_event"
}
```

## Error Handling

### Standard Error Format

```json
{
  "error": "Human-readable error message"
}
```

### Validation Errors

```json
{
  "errors": ["Field-specific error messages"]
}
```

### HTTP Status Codes

| Status | Usage                | Description                    |
| ------ | -------------------- | ------------------------------ |
| 200    | Success              | Request completed successfully |
| 201    | Created              | Resource created successfully  |
| 400    | Bad Request          | Invalid request format         |
| 401    | Unauthorized         | Authentication required/failed |
| 404    | Not Found            | Resource not found             |
| 422    | Unprocessable Entity | Validation errors              |
| 503    | Service Unavailable  | External service unavailable   |

## Data Models

### User

```json
{
  "id": 123,
  "email": "user@example.com",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### Game Event

```json
{
  "id": 456,
  "user_id": 123,
  "game_name": "Brevity",
  "event_type": "COMPLETED",
  "occurred_at": "2024-01-15T10:30:00Z",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### User Statistics

```json
{
  "total_games_played": 5,
  "games": {
    "Brevity": 3,
    "Focus": 2
  }
}
```

## Supported Games

- **Brevity** (Writing)
- **Wordbend** (Vocabulary/Logic)
- **Retention** (Memory)
- **Focus** (Concentration)
- **Name Recall** (Memory)

## Testing Examples

### Complete API Flow

```bash
# 1. Register user
curl -X POST http://localhost:3000/api/user \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123!"}' | jq

# 2. Login
curl -X POST http://localhost:3000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123!"}' | jq

# 3. Get profile (replace TOKEN)
curl -X GET http://localhost:3000/api/user \
  -H "Authorization: Bearer TOKEN" | jq

# 4. Create game event (replace TOKEN)
curl -X POST http://localhost:3000/api/user/game_events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"game_event": {"game_name": "Wordbend", "type": "COMPLETED", "occurred_at": "2025-01-22T10:00:00.000Z"}}' | jq
```

### Error Testing

```bash
# Test invalid credentials
curl -X POST http://localhost:3000/api/sessions \
  -H "Content-Type: application/json" \
  -d '{"email": "wrong@example.com", "password": "wrong"}' | jq

# Test missing token
curl -X GET http://localhost:3000/api/user | jq

# Test invalid game event
curl -X POST http://localhost:3000/api/user/game_events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"game_event": {"game_name": "InvalidGame", "type": "COMPLETED"}}' | jq
```
