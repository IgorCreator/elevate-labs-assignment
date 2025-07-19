# Project Task Checklist & History

This file tracks all atomic tasks for the Elevate Labs Backend Assignment. Each task is a single, measurable action. Check off tasks as you complete them. Use this as a living document to guide implementation and document your process.

---

## Elevate Labs Game List (for validation)

The following games and categories are used for validation and admin UI:

**Categories:**

- Writing
- Vocabulary
- Speaking
- Reading
- Memory
- Math
- Concentration/Focus

**Example Games:**

- Brevity (Writing)
- Wordbend (Vocabulary/Logic)
- Retention (Memory)
- Focus (Concentration)
- Name Recall (Memory)
- Others: (to be expanded as needed from Elevate’s 40+ games)

---

## [ ] 0. Project Setup

- [ ] 0.1 Initialize new Rails project (API mode, Ruby 3.3.5)
- [ ] 0.2 Commit credentials/configuration files (e.g., `config/master.key` or `.env`)
- [ ] 0.3 Document how to obtain and use credentials for local development
- [ ] 0.4 Set up PostgreSQL (or preferred DB)
- [ ] 0.5 Configure RSpec for testing
- [ ] 0.6 Set up FactoryBot and Faker for test data
- [ ] 0.7 Configure Rubocop or other linter
- [ ] 0.8 Add gems for authentication (e.g., bcrypt, JWT)
- [ ] 0.9 Set up dotenv or credentials for secrets
- [ ] 0.10 Create initial README with setup instructions
- [ ] 0.11 Add CORS configuration if needed for mobile app (optional)
- [ ] 0.12 Set up Redis for caching subscription status
- [ ] 0.13 Set up admin authentication (e.g., Devise or custom solution)

---

## [ ] 1. Phase 1 - Sign-up and Authentication

- [ ] 1.1 Generate User model with email and password_digest
- [ ] 1.2 Add migration for users table
- [ ] 1.3 Add validations for email (case-insensitive uniqueness, format) and password (min 8 chars, must include symbol)
- [ ] 1.4 Implement password hashing (bcrypt): following best practices for security
- [ ] 1.5 Create signup endpoint: `POST /api/user`
- [ ] 1.6 Parse and validate JSON payload for signup
- [ ] 1.7 Return 201 Created on success, with user info (no password)
- [ ] 1.8 Create login endpoint: `POST /api/sessions`
- [ ] 1.9 Authenticate user credentials and return JWT token
- [ ] 1.10 Implement JWT token generation and signing (12h expiration)
- [ ] 1.11 Restrict subsequent API requests to authenticated users (JWT auth filter)
- [ ] 1.12 Handle authentication errors (invalid credentials, missing token)
- [ ] 1.13 Ensure all API responses use JSON content type
- [ ] 1.14 Implement rate limiting and brute-force protection on login endpoint
- [ ] 1.15 Protect against SQL injection and excessive retries
- [ ] 1.16 Implement token invalidation (logout endpoint)
- [ ] 1.17 Assume HTTPS for all endpoints (document in README)
- [ ] 1.18 Update README with key design decisions and brief architectural/implementation explanations for Phase 1

---

## [ ] 2. Phase 2 - Game Completion Ingestion

- [ ] 2.1 Generate GameEvent model (user_id, game_name, type, occurred_at)
- [ ] 2.2 Add migration for game_events table
- [ ] 2.3 Add validation for type (only accept "COMPLETED")
- [ ] 2.4 Maintain a list of valid game names (see above)
- [ ] 2.5 Validate occurred_at (not in future, reasonable past)
- [ ] 2.6 Create endpoint: `POST /api/user/game_events`
- [ ] 2.7 Parse and validate JSON payload for game event
- [ ] 2.8 Associate game event with authenticated user
- [ ] 2.9 Return appropriate response (201 Created or error)
- [ ] 2.10 Update README with key design decisions and brief architectural/implementation explanations for Phase 2

---

## [ ] 3. Phase 3 - User Details and Stats

- [ ] 3.1 Create endpoint: `GET /api/user`
- [ ] 3.2 Return user details (id, email)
- [ ] 3.3 Calculate and return user stats: total_games_played and per-game stats (only count COMPLETED events)
- [ ] 3.4 Ensure endpoint is JWT-protected
- [ ] 3.5 Handle errors (unauthorized, user not found)
- [ ] 3.6 Update README with key design decisions and brief architectural/implementation explanations for Phase 3

---

## [ ] 4. Phase 4 - User Subscription Status

- [ ] 4.1 Integrate with external billing service (GET https://interviews-accounts.elevateapp.com/api/v1/users/:user_id/billing)
- [ ] 4.2 Add JWT authentication header to external request
- [ ] 4.3 Handle intermittent failures (user_id=5, user_id>100 returns not_found)
- [ ] 4.4 Parse and return subscription_status in user details response
- [ ] 4.5 Handle and log errors from billing service gracefully; return error to client if service unavailable ("Service temporarily unavailable, internal team notified")
- [ ] 4.6 Cache subscription status using Redis
- [ ] 4.7 Update README with key design decisions and brief architectural/implementation explanations for Phase 4

---

## [ ] 5. Phase 5 - Admin UI & Endpoints

- [ ] 5.1 Implement /admin authentication and session management
- [ ] 5.2 Create basic /admin UI (Rails views or React, etc.)
- [ ] 5.3 Admin CRUD for users (list, create, update, delete)
- [ ] 5.4 Admin CRUD for game events (list, create, update, delete)
- [ ] 5.5 Admin CRUD for game names/categories (if needed)
- [ ] 5.6 Admin view for user stats and subscription status
- [ ] 5.7 Admin view for API logs/errors
- [ ] 5.8 Add tests for admin endpoints and UI
- [ ] 5.9 Update README with admin UI/endpoint design decisions

---

## [ ] 6. Design Decisions & Documentation

- [ ] 6.1 Document authentication approach (JWT, password hashing, expiration, logout, admin auth)
- [ ] 6.2 Document API structure and endpoints (including /admin)
- [ ] 6.3 Explain error handling strategy (including billing service errors)
- [ ] 6.4 Note any security considerations (e.g., password storage, token expiry, rate limiting, SQL injection protection, admin access)
- [ ] 6.5 Document external service integration (billing, Redis caching)
- [ ] 6.6 Add comments in code for key design decisions

---

## [ ] 7. Testing Checklist

- [ ] 7.1 Write model specs (User, GameEvent)
- [ ] 7.2 Write request specs for all endpoints
- [ ] 7.3 Test authentication (valid/invalid tokens, login/signup, token expiration, logout, admin auth)
- [ ] 7.4 Test game event ingestion (valid/invalid payloads, valid/invalid game names, occurred_at validation)
- [ ] 7.5 Test user stats calculation (total and per-game)
- [ ] 7.6 Test subscription status integration (success, not_found, intermittent failure, caching)
- [ ] 7.7 Test admin UI and endpoints (CRUD, access control)
- [ ] 7.8 Add factories for test data
- [ ] 7.9 Run all tests and ensure green
- [ ] 7.10 Manual API testing (curl/Postman)
- [ ] 7.11 Review test coverage and edge cases
- [ ] 7.12 Measure and report test coverage

---

## [ ] 8. Final Review & Polish

- [ ] 8.1 Review code for clarity and maintainability
- [ ] 8.2 Ensure all checkboxes are addressed
- [ ] 8.3 Update README with final instructions and notes
- [ ] 8.4 Clean up unused files and code
- [ ] 8.5 Final commit and push

---

## [ ] 9. Potential Improvements (Future Work)

- [ ] 9.1 Add API versioning
- [ ] 9.2 Expand stats to include more metrics
- [ ] 9.3 Add user update and delete endpoints (API)
- [ ] 9.4 Enhance security (e.g., 2FA, advanced rate limiting)
- [ ] 9.5 Improve error response structure and documentation
- [ ] 9.6 Add admin endpoints for managing games and users
- [ ] 9.7 Add more robust logging and monitoring
- [ ] 9.8 Support for additional authentication providers (OAuth, etc.)
