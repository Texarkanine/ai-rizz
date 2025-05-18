#!/bin/sh
# Test runner script for ai-rizz

# Exit on error
set -e

# Find all test files
find_tests() {
  find tests -name "*.test.sh" | sort
}

# Run a test file
run_test() {
  test_file="$1"
  echo "==== Running test: $test_file ===="
  if sh "$test_file"; then
    echo "==== PASS: $test_file ===="
    return 0
  else
    echo "==== FAIL: $test_file ===="
    return 1
  fi
}

# Main
echo "Running ai-rizz tests..."
failed=0
total=0

for test_file in $(find_tests); do
  total=$((total + 1))
  if ! run_test "$test_file"; then
    failed=$((failed + 1))
  fi
  echo
done

echo "Test results: $((total - failed))/$total passed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi

exit 0 