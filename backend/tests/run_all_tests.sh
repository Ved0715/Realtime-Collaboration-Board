#!/bin/bash

# Realtime Collaboration Board - Run All API Tests

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Realtime Collaboration Board${NC}"
echo -e "${BLUE}  API Test Suite${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if server is running
echo -e "${YELLOW}Checking if server is running...${NC}"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is running${NC}"
else
    echo -e "${RED}✗ Server is not running!${NC}"
    echo -e "${YELLOW}Please start the server with: uvicorn app.main:app --reload${NC}"
    exit 1
fi
echo ""

# Make scripts executable
chmod +x tests/test_auth.sh
chmod +x tests/test_rooms.sh

# Track overall results
TOTAL_PASS=0
TOTAL_FAIL=0

# Run Authentication Tests
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Running Authentication Tests...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
./tests/test_auth.sh
AUTH_RESULT=$?
echo ""

# Run Rooms Tests
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Running Rooms Tests...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
./tests/test_rooms.sh
ROOMS_RESULT=$?
echo ""

# Overall Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Overall Test Results${NC}"
echo -e "${BLUE}=========================================${NC}"

if [ $AUTH_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Authentication Tests: PASSED${NC}"
else
    echo -e "${RED}✗ Authentication Tests: FAILED${NC}"
fi

if [ $ROOMS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Rooms Tests: PASSED${NC}"
else
    echo -e "${RED}✗ Rooms Tests: FAILED${NC}"
fi

echo ""

if [ $AUTH_RESULT -eq 0 ] && [ $ROOMS_RESULT -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ALL TESTS PASSED! ✓${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  SOME TESTS FAILED! ✗${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
