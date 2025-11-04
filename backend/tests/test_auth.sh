#!/bin/bash

# Realtime Collaboration Board - Authentication API Tests
# Tests all authentication endpoints with various scenarios

BASE_URL="http://localhost:8000/api/auth"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASS=0
FAIL=0

echo "========================================="
echo "  Authentication API Tests"
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

# Test 1: Register with valid data
echo -e "${YELLOW}Test 1: Register New User (Valid Data)${NC}"
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser${TIMESTAMP}@example.com"
RESPONSE=$(curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"password123\",
    \"full_name\": \"Test User\"
  }")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "\"email\":\"${TEST_EMAIL}\""; then
    print_result 0 "User registration successful"
else
    print_result 1 "User registration failed"
fi
echo ""

# Test 2: Register with duplicate email
echo -e "${YELLOW}Test 2: Register with Duplicate Email${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"password456\",
    \"full_name\": \"Another User\"
  }")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "already registered"; then
    print_result 0 "Duplicate email validation works"
else
    print_result 1 "Duplicate email validation failed"
fi
echo ""

# Test 3: Register with short password (less than 8 chars)
echo -e "${YELLOW}Test 3: Register with Short Password${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shortpass@example.com",
    "password": "pass",
    "full_name": "Short Pass User"
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "at least 8 characters"; then
    print_result 0 "Password length validation works"
else
    print_result 1 "Password length validation failed"
fi
echo ""

# Test 4: Login with valid credentials (newly created user)
echo -e "${YELLOW}Test 4: Login with Valid Credentials${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${TEST_EMAIL}&password=password123")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "access_token"; then
    print_result 0 "Login successful with valid credentials"
    # Save token for later tests
    TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    echo "Token obtained: ${TOKEN:0:50}..."
else
    print_result 1 "Login failed with valid credentials"
fi
echo ""

# Test 5: Login with existing user (vedant@gmail.com)
echo -e "${YELLOW}Test 5: Login with Existing User (vedant@gmail.com)${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=vedant@gmail.com&password=Vedant@1234")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "access_token"; then
    print_result 0 "Login successful with existing user"
    EXISTING_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
else
    print_result 1 "Login failed with existing user"
fi
echo ""

# Test 6: Login with invalid password
echo -e "${YELLOW}Test 6: Login with Invalid Password${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${TEST_EMAIL}&password=wrongpassword")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Incorrect"; then
    print_result 0 "Invalid password rejected correctly"
else
    print_result 1 "Invalid password not rejected"
fi
echo ""

# Test 7: Login with non-existent email
echo -e "${YELLOW}Test 7: Login with Non-existent Email${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=nonexistent@example.com&password=password123")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Incorrect"; then
    print_result 0 "Non-existent email rejected correctly"
else
    print_result 1 "Non-existent email not rejected"
fi
echo ""

# Test 8: Access /me endpoint with valid token
echo -e "${YELLOW}Test 8: Access /me Endpoint (With Valid Token)${NC}"
if [ -n "$TOKEN" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL/me" \
      -H "Authorization: Bearer $TOKEN")

    echo "Response: $RESPONSE"

    if echo "$RESPONSE" | grep -q "${TEST_EMAIL}"; then
        print_result 0 "Protected route accessible with valid token"
    else
        print_result 1 "Protected route failed with valid token"
    fi
else
    print_result 1 "No token available for test"
fi
echo ""

# Test 9: Access /me endpoint without token
echo -e "${YELLOW}Test 9: Access /me Endpoint (Without Token)${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/me")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Not authenticated"; then
    print_result 0 "Protected route blocked without token"
else
    print_result 1 "Protected route not blocked without token"
fi
echo ""

# Test 10: Access /me endpoint with invalid token
echo -e "${YELLOW}Test 10: Access /me Endpoint (With Invalid Token)${NC}"
RESPONSE=$(curl -s -X GET "$BASE_URL/me" \
  -H "Authorization: Bearer invalid_token_12345")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "Could not validate"; then
    print_result 0 "Invalid token rejected correctly"
else
    print_result 1 "Invalid token not rejected"
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
