#!/bin/bash

# Realtime Collaboration Board - Messages API Tests
# Tests all messages CRUD endpoints

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
echo "  Messages API Tests"
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

# Test 1: Create a room first (needed for message tests)
echo -e "${YELLOW}Test 1: Create a Test Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Room for Messages",
    "description": "Testing message functionality"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "\"name\":\"Test Room for Messages\""; then
    print_result 0 "Test room created successfully"
    ROOM_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "Room ID: $ROOM_ID"
else
    print_result 1 "Test room creation failed"
    exit 1
fi
echo ""

# Test 2: Create a message in the room
echo -e "${YELLOW}Test 2: Create a Message in Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello, this is my first message!"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Hello, this is my first message!"; then
    print_result 0 "Message created successfully"
    MESSAGE_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "Message ID: $MESSAGE_ID"
else
    print_result 1 "Message creation failed"
fi
echo ""

# Test 3: Create message without authentication
echo -e "${YELLOW}Test 3: Create Message Without Authentication${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/messages" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Unauthorized message"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Not authenticated"; then
    print_result 0 "Unauthenticated message creation blocked correctly"
else
    print_result 1 "Unauthenticated message creation not blocked"
fi
echo ""

# Test 4: Create message in non-existent room
echo -e "${YELLOW}Test 4: Create Message in Non-existent Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/99999/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Message in non-existent room"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Room not found"; then
    print_result 0 "Non-existent room handled correctly"
else
    print_result 1 "Non-existent room not handled correctly"
fi
echo ""

# Test 5: Create another message
echo -e "${YELLOW}Test 5: Create Second Message${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is my second message!"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "This is my second message!"; then
    print_result 0 "Second message created successfully"
    MESSAGE_ID_2=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
else
    print_result 1 "Second message creation failed"
fi
echo ""

# Test 6: Get all messages in room
echo -e "${YELLOW}Test 6: Get All Messages in Room${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/$ROOM_ID/messages" \
  -H "Authorization: Bearer $TOKEN")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Hello, this is my first message!"; then
    print_result 0 "Retrieved messages list successfully"
else
    print_result 1 "Failed to retrieve messages list"
fi
echo ""

# Test 7: Get messages without authentication
echo -e "${YELLOW}Test 7: Get Messages Without Authentication${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/$ROOM_ID/messages")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Not authenticated"; then
    print_result 0 "Unauthenticated request blocked correctly"
else
    print_result 1 "Unauthenticated request not blocked"
fi
echo ""

# Test 8: Get specific message by ID
echo -e "${YELLOW}Test 8: Get Specific Message by ID${NC}"
if [ -n "$MESSAGE_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/messages/$MESSAGE_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "\"id\":$MESSAGE_ID"; then
        print_result 0 "Retrieved specific message successfully"
    else
        print_result 1 "Failed to retrieve specific message"
    fi
else
    print_result 1 "No message ID available for test"
fi
echo ""

# Test 9: Get non-existent message
echo -e "${YELLOW}Test 9: Get Non-existent Message${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/messages/99999" \
  -H "Authorization: Bearer $TOKEN")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "not found"; then
    print_result 0 "Non-existent message handled correctly"
else
    print_result 1 "Non-existent message not handled correctly"
fi
echo ""

# Test 10: Update message
echo -e "${YELLOW}Test 10: Update Message${NC}"
if [ -n "$MESSAGE_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/messages/$MESSAGE_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "content": "Updated message content"
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Updated message content"; then
        print_result 0 "Message updated successfully"
    else
        print_result 1 "Message update failed"
    fi
else
    print_result 1 "No message ID available for test"
fi
echo ""

# Test 11: Update message without authentication
echo -e "${YELLOW}Test 11: Update Message Without Authentication${NC}"
if [ -n "$MESSAGE_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/messages/$MESSAGE_ID" \
      -H "Content-Type: application/json" \
      -d '{
        "content": "Unauthorized update"
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Not authenticated"; then
        print_result 0 "Unauthorized update blocked correctly"
    else
        print_result 1 "Unauthorized update not blocked"
    fi
else
    print_result 1 "No message ID available for test"
fi
echo ""

# Test 12: Delete message
echo -e "${YELLOW}Test 12: Delete Message${NC}"
if [ -n "$MESSAGE_ID" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$BASE_URL/messages/$MESSAGE_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "HTTP_STATUS:204"; then
        print_result 0 "Message deleted successfully"
    else
        print_result 1 "Message deletion failed"
    fi
else
    print_result 1 "No message ID available for test"
fi
echo ""

# Test 13: Verify message is deleted
echo -e "${YELLOW}Test 13: Verify Message is Deleted${NC}"
if [ -n "$MESSAGE_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/messages/$MESSAGE_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "not found"; then
        print_result 0 "Message successfully deleted and verified"
    else
        print_result 1 "Message still exists after deletion"
    fi
else
    print_result 1 "No message ID available for test"
fi
echo ""

# Test 14: Delete message without authentication
echo -e "${YELLOW}Test 14: Delete Message Without Authentication${NC}"
if [ -n "$MESSAGE_ID_2" ]; then
    RESPONSE=$(curl -s -X DELETE "$BASE_URL/messages/$MESSAGE_ID_2")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Not authenticated"; then
        print_result 0 "Unauthorized deletion blocked correctly"
    else
        print_result 1 "Unauthorized deletion not blocked"
    fi
else
    print_result 1 "No message ID available for test"
fi
echo ""

# Cleanup: Delete the test room
echo -e "${YELLOW}Cleanup: Delete Test Room${NC}"
if [ -n "$ROOM_ID" ]; then
    curl -s -X DELETE "$BASE_URL/rooms/$ROOM_ID" \
      -H "Authorization: Bearer $TOKEN" > /dev/null
    echo "Test room deleted"
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
