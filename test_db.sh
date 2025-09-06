#!/bin/bash

# test_db.sh - Enhanced with string length test
DB_EXEC="./db"

# Colors and counters (same as before)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
START_TIME=$(date +%s.%N)

run_test() {
    local test_name="$1"
    local input="$2"
    local expected="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    actual=$(echo -e "$input" | $DB_EXEC 2>/dev/null)
    
    if [ "$actual" = "$expected" ]; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected: $expected" >> /tmp/test_failures.tmp
        echo "Actual: $actual" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Function to test maximum string lengths
test_max_string_length() {
    local test_name="allows inserting strings that are the maximum length"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Generate maximum length strings
    long_username=$(printf 'a%.0s' {1..32})    # 32 'a's
    long_email=$(printf 'a%.0s' {1..255})      # 255 'a's
    
    # Build the test input
    commands="insert 1 ${long_username} ${long_email}\nselect\n.exit"
    
    # Expected output
    expected="db > Executed.
db > (1, ${long_username}, ${long_email})
Executed.
db > "
    
    # Run the test
    actual=$(echo -e "$commands" | $DB_EXEC 2>/dev/null)
    
    if [ "$actual" = "$expected" ]; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected username length: 32, email length: 255" >> /tmp/test_failures.tmp
        echo "Expected: $expected" >> /tmp/test_failures.tmp
        echo "Actual: $actual" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Table full test function (from previous example)
test_table_full() {
    local test_name="prints error message when table is full"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    commands=""
    for i in $(seq 1 1401); do
        commands="${commands}insert $i user$i person$i@example.com\n"
    done
    commands="${commands}.exit"
    
    output=$(echo -e "$commands" | $DB_EXEC 2>/dev/null)
    second_last_line=$(echo "$output" | tail -n 2 | head -n 1)
    
    if [ "$second_last_line" = "db > Error: Table full." ]; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected second-to-last line: 'db > Error: Table full.'" >> /tmp/test_failures.tmp
        echo "Actual second-to-last line: '$second_last_line'" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Clear previous failure log
> /tmp/test_failures.tmp

echo "Running database tests..."

# Test 1: Basic functionality
run_test "inserts and retrieves a row" \
    "insert 1 user1 person1@example.com\nselect\n.exit" \
    "db > Executed.
db > (1, user1, person1@example.com)
Executed.
db > "

# Test 2: Maximum string lengths
test_max_string_length

# Test 3: Table full scenario
test_table_full

echo ""

# Summary output (same as before)
END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo "Failures:"
    cat /tmp/test_failures.tmp
    rm /tmp/test_failures.tmp
fi

echo ""
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}Finished in ${DURATION} seconds${NC}"
    echo -e "${GREEN}$TOTAL_TESTS examples, 0 failures${NC}"
else
    echo -e "${RED}Finished in ${DURATION} seconds${NC}"
    echo -e "${RED}$TOTAL_TESTS examples, $FAILED_TESTS failures${NC}"
fi

exit $FAILED_TESTS
