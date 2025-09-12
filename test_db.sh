#!/bin/bash

# test_db.sh - Enhanced with database file management
DB_EXEC="./db"
DB_FILE="test.db"

# Colors and counters
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
START_TIME=$(date +%s.%N)

# Function equivalent to Ruby's before block
before_each_test() {
    rm -rf "$DB_FILE"
}

# Function equivalent to Ruby's run_script
run_script() {
    local commands=("$@")
    local input=""
    
    # Build input string from commands array
    for cmd in "${commands[@]}"; do
        input="${input}${cmd}\n"
    done
    
    # Run database with file parameter and capture output
    echo -e "$input" | $DB_EXEC "$DB_FILE" 2>/dev/null
}

# Function to compare arrays (like Ruby's match_array)
arrays_match() {
    local -n actual_ref=$1
    local -n expected_ref=$2
    
    # Sort both arrays and compare
    local actual_sorted=($(printf '%s\n' "${actual_ref[@]}" | sort))
    local expected_sorted=($(printf '%s\n' "${expected_ref[@]}" | sort))
    
    [[ "${actual_sorted[*]}" == "${expected_sorted[*]}" ]]
}

# Test 1: Basic functionality
test_basic() {
    before_each_test  # Clean up before test
    local test_name="inserts and retrieves a row"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local commands=("insert 1 user1 person1@example.com" "select" ".exit")
    local output
    output=$(run_script "${commands[@]}")
    
    IFS=$'\n' read -rd '' -a actual_lines <<< "$output"
    local expected=("db > Executed." "db > (1, user1, person1@example.com)" "Executed." "db > ")
    
    if arrays_match actual_lines expected; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected: ${expected[*]}" >> /tmp/test_failures.tmp
        echo "Actual: ${actual_lines[*]}" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Test 2: Maximum string lengths
test_max_strings() {
    before_each_test  # Clean up before test
    local test_name="allows inserting strings that are the maximum length"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local long_username=$(printf 'a%.0s' {1..32})
    local long_email=$(printf 'a%.0s' {1..255})
    
    local commands=("insert 1 ${long_username} ${long_email}" "select" ".exit")
    local output
    output=$(run_script "${commands[@]}")
    
    IFS=$'\n' read -rd '' -a actual_lines <<< "$output"
    local expected=("db > Executed." "db > (1, ${long_username}, ${long_email})" "Executed." "db > ")
    
    if arrays_match actual_lines expected; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected: ${expected[*]}" >> /tmp/test_failures.tmp
        echo "Actual: ${actual_lines[*]}" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Test 3: String too long
test_string_too_long() {
    before_each_test  # Clean up before test
    local test_name="prints error message if strings are too long"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local long_username=$(printf 'a%.0s' {1..33})
    local long_email=$(printf 'a%.0s' {1..256})
    
    local commands=("insert 1 ${long_username} ${long_email}" "select" ".exit")
    local output
    output=$(run_script "${commands[@]}")
    
    IFS=$'\n' read -rd '' -a actual_lines <<< "$output"
    local expected=("db > String is too long." "db > Executed." "db > ")
    
    if arrays_match actual_lines expected; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected: ${expected[*]}" >> /tmp/test_failures.tmp
        echo "Actual: ${actual_lines[*]}" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Test 4: Negative ID
test_negative_id() {
    before_each_test  # Clean up before test
    local test_name="prints an error message if id is negative"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local commands=("insert -1 cstack foo@bar.com" "select" ".exit")
    local output
    output=$(run_script "${commands[@]}")
    
    IFS=$'\n' read -rd '' -a actual_lines <<< "$output"
    local expected=("db > ID must be positive." "db > Executed." "db > ")
    
    if arrays_match actual_lines expected; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected: ${expected[*]}" >> /tmp/test_failures.tmp
        echo "Actual: ${actual_lines[*]}" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Test 5: Data persistence
test_persistence() {
    before_each_test  # Clean up before test
    local test_name="keeps data after closing connection"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # First connection: insert data and exit
    local commands1=("insert 1 user1 person1@example.com" ".exit")
    local output1
    output1=$(run_script "${commands1[@]}")
    
    IFS=$'\n' read -rd '' -a result1 <<< "$output1"
    local expected1=("db > Executed." "db > ")
    
    # Check first result
    if ! arrays_match result1 expected1; then
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name (part 1: insert)" >> /tmp/test_failures.tmp
        echo "Expected: ${expected1[*]}" >> /tmp/test_failures.tmp
        echo "Actual: ${result1[*]}" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
        return
    fi
    
    # Second connection: select data and verify it's still there
    # DON'T clean up the database file between these calls!
    local commands2=("select" ".exit")
    local output2
    output2=$(run_script "${commands2[@]}")
    
    IFS=$'\n' read -rd '' -a result2 <<< "$output2"
    local expected2=("db > (1, user1, person1@example.com)" "Executed." "db > ")
    
    # Check second result
    if arrays_match result2 expected2; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name (part 2: select after reconnect)" >> /tmp/test_failures.tmp
        echo "Expected: ${expected2[*]}" >> /tmp/test_failures.tmp
        echo "Actual: ${result2[*]}" >> /tmp/test_failures.tmp
        echo "First insert result was: ${result1[*]}" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Test 6: Table full
test_table_full() {
    before_each_test  # Clean up before test
    local test_name="prints error message when table is full"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Generate commands array like Ruby (1..1401).map
    local commands=()
    for i in $(seq 1 1401); do
        commands+=("insert $i user$i person$i@example.com")
    done
    commands+=(".exit")
    
    local output
    output=$(run_script "${commands[@]}")
    
    IFS=$'\n' read -rd '' -a result_lines <<< "$output"
    
    # Check second-to-last element (like Ruby result[-2])
    local second_last_index=$((${#result_lines[@]} - 2))
    if [[ $second_last_index -ge 0 && "${result_lines[$second_last_index]}" == "db > Error: Table full." ]]; then
        echo -n "."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -n "F"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        echo "" >> /tmp/test_failures.tmp
        echo "FAILURE: $test_name" >> /tmp/test_failures.tmp
        echo "Expected second-to-last: 'db > Error: Table full.'" >> /tmp/test_failures.tmp
        echo "Actual second-to-last: '${result_lines[$second_last_index]}'" >> /tmp/test_failures.tmp
        echo "---" >> /tmp/test_failures.tmp
    fi
}

# Clear previous failure log
> /tmp/test_failures.tmp

echo "Running database tests..."

# Run all tests (like Ruby describe block)
test_basic
test_max_strings  
test_string_too_long
test_negative_id
test_persistence
test_table_full

echo ""

# Summary output
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

# Clean up test database file at the end
rm -rf "$DB_FILE"

exit $FAILED_TESTS
