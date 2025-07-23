# Scripts Directory

This directory contains utility scripts for testing and development.

## test_users_api.rb

A standalone script to test the Users API functionality. This script can test both HTTP API calls and direct service calls.

### Usage

```bash
# Test both API and direct calls (default)
ruby script/test_users_api.rb

# Test only HTTP API calls (requires server running on localhost:3000)
ruby script/test_users_api.rb api

# Test only direct service calls (no server required)
ruby script/test_users_api.rb direct

# Test both methods
ruby script/test_users_api.rb both
```

### What it tests

The script tests the following user IDs: `[1, 2, 3, 4, 5, 99, 500 ]`

Expected results:

- **IDs 1, 3, 10, 20**: Should return 200 OK with user data
- **ID 5**: Should return 503 error (intermittent failure simulation)
- **ID 500**: Should return 404 error (not found)

### Prerequisites

- Rails environment loaded (database, models, services)
- For API testing: Rails server running on `localhost:3000`
- For direct testing: No server required

### Output

The script provides detailed output showing:

- Expected vs actual results
- HTTP status codes
- JSON responses
- Error messages and stack traces

This is useful for:

- Manual testing during development
- Debugging API responses
- Verifying billing service integration
- Testing error handling scenarios
