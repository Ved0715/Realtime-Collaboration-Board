#!/bin/bash

# Realtime Collaboration Board - Notes API Tests
# Tests all notes CRUD endpoints

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
echo "  Notes API Tests"
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

# Test 1: Create a room first (needed for note tests)
echo -e "${YELLOW}Test 1: Create a Test Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Room for Notes",
    "description": "Testing sticky notes functionality"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "\"name\":\"Test Room for Notes\""; then
    print_result 0 "Test room created successfully"
    ROOM_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "Room ID: $ROOM_ID"
else
    print_result 1 "Test room creation failed"
    exit 1
fi
echo ""

# Test 2: Create a sticky note in the room
echo -e "${YELLOW}Test 2: Create a Sticky Note in Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/notes" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is my first sticky note!",
    "position_x": 100.5,
    "position_y": 200.5,
    "color": "#FFEB3B"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "This is my first sticky note!"; then
    print_result 0 "Note created successfully"
    NOTE_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "Note ID: $NOTE_ID"
else
    print_result 1 "Note creation failed"
fi
echo ""

# Test 3: Create note without authentication
echo -e "${YELLOW}Test 3: Create Note Without Authentication${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/notes" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Unauthorized note",
    "position_x": 50,
    "position_y": 50,
    "color": "#FF5722"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Not authenticated"; then
    print_result 0 "Unauthenticated note creation blocked correctly"
else
    print_result 1 "Unauthenticated note creation not blocked"
fi
echo ""

# Test 4: Create note in non-existent room
echo -e "${YELLOW}Test 4: Create Note in Non-existent Room${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/99999/notes" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Note in non-existent room",
    "position_x": 10,
    "position_y": 10,
    "color": "#4CAF50"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Room not found"; then
    print_result 0 "Non-existent room handled correctly"
else
    print_result 1 "Non-existent room not handled correctly"
fi
echo ""

# Test 5: Create note with invalid color format
echo -e "${YELLOW}Test 5: Create Note with Invalid Color${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/notes" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Note with bad color",
    "position_x": 10,
    "position_y": 10,
    "color": "invalid"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "validation_error\|String should match pattern"; then
    print_result 0 "Invalid color format rejected correctly"
else
    print_result 1 "Invalid color format not rejected"
fi
echo ""

# Test 6: Create another note
echo -e "${YELLOW}Test 6: Create Second Note${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/rooms/$ROOM_ID/notes" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is my second sticky note!",
    "position_x": 300,
    "position_y": 400,
    "color": "#E91E63"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "This is my second sticky note!"; then
    print_result 0 "Second note created successfully"
    NOTE_ID_2=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
else
    print_result 1 "Second note creation failed"
fi
echo ""

# Test 7: Get all notes in room
echo -e "${YELLOW}Test 7: Get All Notes in Room${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/$ROOM_ID/notes" \
  -H "Authorization: Bearer $TOKEN")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "This is my first sticky note!"; then
    print_result 0 "Retrieved notes list successfully"
else
    print_result 1 "Failed to retrieve notes list"
fi
echo ""

# Test 8: Get notes without authentication
echo -e "${YELLOW}Test 8: Get Notes Without Authentication${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/rooms/$ROOM_ID/notes")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Not authenticated"; then
    print_result 0 "Unauthenticated request blocked correctly"
else
    print_result 1 "Unauthenticated request not blocked"
fi
echo ""

# Test 9: Get specific note by ID
echo -e "${YELLOW}Test 9: Get Specific Note by ID${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/notes/$NOTE_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "\"id\":$NOTE_ID"; then
        print_result 0 "Retrieved specific note successfully"
    else
        print_result 1 "Failed to retrieve specific note"
    fi
else
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 10: Get non-existent note
echo -e "${YELLOW}Test 10: Get Non-existent Note${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/notes/99999" \
  -H "Authorization: Bearer $TOKEN")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "not found"; then
    print_result 0 "Non-existent note handled correctly"
else
    print_result 1 "Non-existent note not handled correctly"
fi
echo ""

# Test 11: Update note content
echo -e "${YELLOW}Test 11: Update Note Content${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/notes/$NOTE_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "content": "Updated note content"
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Updated note content"; then
        print_result 0 "Note content updated successfully"
    else
        print_result 1 "Note content update failed"
    fi
else
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 12: Update note position
echo -e "${YELLOW}Test 12: Update Note Position${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/notes/$NOTE_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "position_x": 500,
        "position_y": 600
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "\"position_x\":500"; then
        print_result 0 "Note position updated successfully"
    else
        print_result 1 "Note position update failed"
    fi
else
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 13: Update note color
echo -e "${YELLOW}Test 13: Update Note Color${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/notes/$NOTE_ID" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "color": "#2196F3"
      }')

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "#2196F3"; then
        print_result 0 "Note color updated successfully"
    else
        print_result 1 "Note color update failed"
    fi
else
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 14: Update note without authentication
echo -e "${YELLOW}Test 14: Update Note Without Authentication${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -X PATCH "$BASE_URL/notes/$NOTE_ID" \
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
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 15: Delete note
echo -e "${YELLOW}Test 15: Delete Note${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$BASE_URL/notes/$NOTE_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "HTTP_STATUS:204"; then
        print_result 0 "Note deleted successfully"
    else
        print_result 1 "Note deletion failed"
    fi
else
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 16: Verify note is deleted
echo -e "${YELLOW}Test 16: Verify Note is Deleted${NC}"
if [ -n "$NOTE_ID" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/notes/$NOTE_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "not found"; then
        print_result 0 "Note successfully deleted and verified"
    else
        print_result 1 "Note still exists after deletion"
    fi
else
    print_result 1 "No note ID available for test"
fi
echo ""

# Test 17: Delete note without authentication
echo -e "${YELLOW}Test 17: Delete Note Without Authentication${NC}"
if [ -n "$NOTE_ID_2" ]; then
    RESPONSE=$(curl -s -X DELETE "$BASE_URL/notes/$NOTE_ID_2")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "Not authenticated"; then
        print_result 0 "Unauthorized deletion blocked correctly"
    else
        print_result 1 "Unauthorized deletion not blocked"
    fi
else
    print_result 1 "No note ID available for test"
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
