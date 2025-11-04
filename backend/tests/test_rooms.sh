#!/bin/bash

# Realtime Collaboration Board - Rooms API Tests
# Tests all rooms CRUD endpoints

BASE_URL="http://localhost:8000/api"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASS=0
FAIL=0

# Existing user credentials
USERNAME="vedant@gmail.com"
PASSWORD="Vedant@1234"

echo "========================================="
echo "  Rooms API Tests"
echo "========================================="
echo ""

# Helper function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAIL++))
    fi
}

# Test 0: Login to get token
echo -e "${YELLOW}Test 0: Login to Get Access Token${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${USERNAME}&password=${PASSWORD}")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "access_token"; then
    print_result 0 "Login successful"
    TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    echo "Token obtained: ${TOKEN:0:50}..."
else
    print_result 1 "Login failed - cannot continue with tests"
    exit 1
fi
echo ""

# Test 1: Create a new room
echo -e "${YELLOW}Test 1: Create a New Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Room - Project Alpha",
    "description": "A test room for our project"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "\"name\":\"Test Room - Project Alpha\""; then
    print_result 0 "Room created successfully"
    ROOM_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "Room ID: $ROOM_ID"
else
    print_result 1 "Room creation failed"
fi
echo ""

# Test 2: Create room without authentication
echo -e "${YELLOW}Test 2: Create Room Without Authentication${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Unauthorized Room",
    "description": "This should fail"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Not authenticated"; then
    print_result 0 "Unauthenticated request blocked correctly"
else
    print_result 1 "Unauthenticated request not blocked"
fi
echo ""

# Test 3: Get all rooms
echo -e "${YELLOW}Test 3: Get All Rooms${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/" \
  -H "Authorization: Bearer $TOKEN")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Test Room - Project Alpha"; then
    print_result 0 "Retrieved rooms list successfully"
else
    print_result 1 "Failed to retrieve rooms list"
fi
echo ""

# Test 4: Get specific room by ID
echo -e "${YELLOW}Test 4: Get Specific Room by ID${NC}"
if [ -n "$ROOM_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/$ROOM_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "\"id\":$ROOM_ID"; then
        print_result 0 "Retrieved specific room successfully"
    else
        print_result 1 "Failed to retrieve specific room"
    fi
else
    print_result 1 "No room ID available for test"
fi
echo ""

# Test 5: Get non-existent room
echo -e "${YELLOW}Test 5: Get Non-existent Room${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/99999" \
  -H "Authorization: Bearer $TOKEN")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "not found"; then
    print_result 0 "Non-existent room handled correctly"
else
    print_result 1 "Non-existent room not handled correctly"
fi
echo ""

# Test 6: Update room
echo -e "${YELLOW}Test 6: Update Room${NC}"
if [ -n "$ROOM_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/rooms/$ROOM_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Updated Test Room",
        "description": "Updated description"
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Updated Test Room"; then
        print_result 0 "Room updated successfully"
    else
        print_result 1 "Room update failed"
    fi
else
    print_result 1 "No room ID available for test"
fi
echo ""

# Test 7: Update room without authentication
echo -e "${YELLOW}Test 7: Update Room Without Authentication${NC}"
if [ -n "$ROOM_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/rooms/$ROOM_ID" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Unauthorized Update"
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Not authenticated"; then
        print_result 0 "Unauthorized update blocked correctly"
    else
        print_result 1 "Unauthorized update not blocked"
    fi
else
    print_result 1 "No room ID available for test"
fi
echo ""

# Test 8: Delete room
echo -e "${YELLOW}Test 8: Delete Room${NC}"
if [ -n "$ROOM_ID" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$BASE_URL/rooms/$ROOM_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "HTTP_STATUS:204"; then
        print_result 0 "Room deleted successfully"
    else
        print_result 1 "Room deletion failed"
    fi
else
    print_result 1 "No room ID available for test"
fi
echo ""

# Test 9: Verify room is deleted
echo -e "${YELLOW}Test 9: Verify Room is Deleted${NC}"
if [ -n "$ROOM_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/$ROOM_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "not found"; then
        print_result 0 "Room successfully deleted and verified"
    else
        print_result 1 "Room still exists after deletion"
    fi
else
    print_result 1 "No room ID available for test"
fi
echo ""

# Summary
echo "========================================="
echo "  Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo "Total: $((PASS + FAIL))"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi
