#!/bin/bash

# Helper functions for modern-shell tests

# Function to check if something is NOT present
check_not() {
    local test_name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        check "$test_name" false
    else
        check "$test_name" true
    fi
}

# Function to check if a pattern is NOT in a file
check_not_in_file() {
    local test_name="$1"
    local pattern="$2"
    local file="$3"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        check "$test_name" false
    else
        check "$test_name" true
    fi
}