#!/bin/zsh

# Elevate Labs API Test Script
# Tests complete API flow including special cases for user IDs 5 and 500

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:3000"
API_URL="${BASE_URL}/api"
TEST_EMAIL="test_$(date +%s)@example.com"
TEST_PASSWORD="password123!"

# Test user IDs for special cases (from seeds.rb)
SPECIAL_USER_5="user005@example.com"
SPECIAL_USER_500="user500@example.com"

# Temporary files
TOKEN_FILE="/tmp/elevate_test_token.txt"
USER_ID_FILE="/tmp/elevate_user_id.txt"
TOKEN_5_FILE="/tmp/elevate_test_token_5.txt"
TOKEN_500_FILE="/tmp/elevate_test_token_500.txt"

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if server is running
check_server() {
    print_header "Checking Server Status"

    if curl -s "${BASE_URL}" > /dev/null 2>&1; then
        print_success "Server is running at ${BASE_URL}"
    else
        print_error "Server is not running at ${BASE_URL}"
        print_info "Please start the server with: rails server"
        exit 1
    fi
}

# Clean up temporary files
cleanup() {
    rm -f "$TOKEN_FILE" "$USER_ID_FILE" "$TOKEN_5_FILE" "$TOKEN_500_FILE"
}



# Test user registration
test_user_registration() {
    print_header "Testing User Registration"

    local response=$(curl -s -X POST "${API_URL}/user" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${TEST_EMAIL}\",
            \"password\": \"${TEST_PASSWORD}\"
        }")

    echo "Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    # Extract token and user ID
    local token=$(echo "$response" | jq -r '.token // empty')
    local user_id=$(echo "$response" | jq -r '.user.id // empty')

    if [[ -n "$token" && -n "$user_id" ]]; then
        print_success "User registered successfully"
        echo "$token" > "$TOKEN_FILE"
        echo "$user_id" > "$USER_ID_FILE"
        print_info "User ID: $user_id"
        print_info "Token saved for subsequent requests"
    else
        print_error "User registration failed"
        echo "$response"
        exit 1
    fi
}

# Test user login
test_user_login() {
    print_header "Testing User Login"

    local response=$(curl -s -X POST "${API_URL}/sessions" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${TEST_EMAIL}\",
            \"password\": \"${TEST_PASSWORD}\"
        }")

    echo "Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    local token=$(echo "$response" | jq -r '.token // empty')

    if [[ -n "$token" ]]; then
        print_success "User login successful"
        echo "$token" > "$TOKEN_FILE"
        print_info "New token saved"
    else
        print_error "User login failed"
        echo "$response"
        exit 1
    fi
}

# Test get user profile
test_user_profile() {
    print_header "Testing Get User Profile"

    local token=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")

    if [[ -z "$token" ]]; then
        print_error "No token available"
        return 1
    fi

    local response=$(curl -s -X GET "${API_URL}/user" \
        -H "Authorization: Bearer ${token}")

    echo "Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    local user_id=$(echo "$response" | jq -r '.user.id // empty')
    local subscription_status=$(echo "$response" | jq -r '.user.subscription_status // empty')

    if [[ -n "$user_id" ]]; then
        print_success "User profile retrieved successfully"
        print_info "User ID: $user_id"
        print_info "Subscription Status: $subscription_status"
    else
        print_error "Failed to retrieve user profile"
        echo "$response"
        return 1
    fi
}

# Test create game event
test_create_game_event() {
    print_header "Testing Create Game Event"

    local token=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")

    if [[ -z "$token" ]]; then
        print_error "No token available"
        return 1
    fi

    local game_name="$1"
    local occurred_at="$2"

    local response=$(curl -s -X POST "${API_URL}/user/game_events" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${token}" \
        -d "{
            \"game_event\": {
                \"game_name\": \"${game_name}\",
                \"type\": \"COMPLETED\",
                \"occurred_at\": \"${occurred_at}\"
            }
        }")

    echo "Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    local event_id=$(echo "$response" | jq -r '.game_event.id // empty')

    if [[ -n "$event_id" ]]; then
        print_success "Game event created successfully"
        print_info "Event ID: $event_id"
        print_info "Game: $game_name"
    else
        print_error "Failed to create game event"
        echo "$response"
        return 1
    fi
}

# Test special user ID 5 (intermittent failures)
test_user_id_5() {
    print_header "Testing User ID 5 (Intermittent Failures)"

    # Login as user ID 5 (already exists from seeds.rb)
    print_info "Logging in as user ID 5..."
    local response=$(curl -s -X POST "${API_URL}/sessions" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${SPECIAL_USER_5}\",
            \"password\": \"${TEST_PASSWORD}\"
        }")

    echo "Login Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    local token=$(echo "$response" | jq -r '.token // empty')

    if [[ -n "$token" ]]; then
        print_success "Login successful for user ID 5"
        echo "$token" > "$TOKEN_5_FILE"

        # Test multiple profile retrievals to demonstrate intermittent failures
        print_info "Testing multiple profile retrievals for user ID 5 (intermittent failures)..."

                for i in {1..5}; do
            print_info "Attempt $i/5:"

            # Clear cache before each request to force fresh billing service call
            print_info "Clearing cache for user ID 5..."
            rails runner "Rails.cache.delete('subscription_status:5')" 2>/dev/null

            local profile_response=$(curl -s -X GET "${API_URL}/user" \
                -H "Authorization: Bearer ${token}")

            echo "Profile Response:"
            echo "$profile_response" | jq '.' 2>/dev/null || echo "$profile_response"

            local error=$(echo "$profile_response" | jq -r '.error // empty')
            local subscription_status=$(echo "$profile_response" | jq -r '.user.subscription_status // empty')

            if [[ -n "$error" ]]; then
                print_warning "Attempt $i: Expected error - $error"
            else
                print_success "Attempt $i: Profile retrieved successfully"
                print_info "Subscription Status: $subscription_status"
            fi

            # Small delay between requests to see the intermittent nature
            if [[ $i -lt 5 ]]; then
                sleep 1
            fi
        done

        print_info "User ID 5 demonstrates intermittent billing service failures"
    else
        print_error "Failed to login as user ID 5"
        echo "$response"
    fi
}

# Test special user ID 500 (not found)
test_user_id_500() {
    print_header "Testing User ID 500 (Not Found)"

    # Login as user ID 500 (already exists from seeds.rb)
    print_info "Logging in as user ID 500..."
    local response=$(curl -s -X POST "${API_URL}/sessions" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${SPECIAL_USER_500}\",
            \"password\": \"${TEST_PASSWORD}\"
        }")

    echo "Login Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    local token=$(echo "$response" | jq -r '.token // empty')

    if [[ -n "$token" ]]; then
        print_success "Login successful for user ID 500"
        echo "$token" > "$TOKEN_500_FILE"

        # Test profile retrieval (should trigger "not found" billing service error)
        print_info "Testing profile retrieval for user ID 500..."
        local profile_response=$(curl -s -X GET "${API_URL}/user" \
            -H "Authorization: Bearer ${token}")

        echo "Profile Response:"
        echo "$profile_response" | jq '.' 2>/dev/null || echo "$profile_response"

        local error=$(echo "$profile_response" | jq -r '.error // empty')
        local subscription_status=$(echo "$profile_response" | jq -r '.user.subscription_status // empty')

        if [[ -n "$error" ]]; then
            print_warning "Expected error for user ID 500: $error"
        else
            print_success "Profile retrieved for user ID 500"
            print_info "Subscription Status: $subscription_status"
        fi
    else
        print_error "Failed to login as user ID 500"
        echo "$response"
    fi
}

# Test multiple game events
test_multiple_game_events() {
    print_header "Testing Multiple Game Events"

    local games=("Brevity" "Wordbend" "Retention" "Focus" "Name Recall")
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    for game in "${games[@]}"; do
        print_info "Creating game event for: $game"
        test_create_game_event "$game" "$current_time"
        sleep 1  # Small delay between requests
    done
}

# Test error cases
test_error_cases() {
    print_header "Testing Error Cases"

    # Test invalid login
    print_info "Testing invalid login..."
    local response=$(curl -s -X POST "${API_URL}/sessions" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "invalid@example.com",
            "password": "wrongpassword"
        }')

    echo "Invalid Login Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    # Test missing token
    print_info "Testing request without token..."
    local response=$(curl -s -X GET "${API_URL}/user")

    echo "No Token Response:"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"

    # Test invalid game event
    print_info "Testing invalid game event..."
    local token=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")

    if [[ -n "$token" ]]; then
        local response=$(curl -s -X POST "${API_URL}/user/game_events" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${token}" \
            -d '{
                "game_event": {
                    "game_name": "InvalidGame",
                    "type": "COMPLETED",
                    "occurred_at": "2025-01-22T10:00:00.000Z"
                }
            }')

        echo "Invalid Game Response:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    fi
}

# Main test flow
main() {
    print_header "Elevate Labs API Test Suite"
    print_info "Base URL: ${BASE_URL}"
    print_info "Test Email: ${TEST_EMAIL}"
    print_info "Time: $(date)"
    print_info "Platform: macOS"

    # Set up cleanup on exit
    trap cleanup EXIT

    # Run tests
    check_server
    test_user_registration
    test_user_login
    test_user_profile
    test_multiple_game_events
    test_user_profile  # Check profile again after creating events
    test_user_id_5
    test_user_id_500
    test_error_cases

    print_header "Test Summary"
    print_success "All tests completed!"
    print_info "Test user created: ${TEST_EMAIL}"
    print_info "Special users tested: ${SPECIAL_USER_5} (ID: 5), ${SPECIAL_USER_500} (ID: 500)"
    print_info "Check the admin interface to see the created data"
    print_info "Admin URL: ${BASE_URL}/admin/login"
    print_info "Check logs for billing service interactions"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed"
    print_info "Install with: brew install jq"
    exit 1
fi

# Check if Rails is available
if ! command -v rails &> /dev/null; then
    print_error "Rails is required but not available"
    print_info "Make sure you're in the Rails project directory"
    exit 1
fi

# Run main function
main "$@"
