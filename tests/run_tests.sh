#!/bin/sh
# Test runner script for ai-rizz

# Exit on error
set -e

# Store the original directory
ORIG_DIR="$(pwd)"

# Get the project root directory (parent of the tests directory)
get_project_root() {
  # Detect where this script is running from and find project root
  script_dir="$(dirname "$0")"
  
  # If in tests directory, go up one level
  if [ "$(basename "$script_dir")" = "tests" ]; then
    cd "$script_dir/.." || exit 1
  elif [ -d "./tests" ]; then
    # Already in project root
    :
  else
    echo "Error: Cannot determine project root directory" >&2
    exit 1
  fi
  
  # Return the absolute path to project root
  pwd
}

# Find all test files (relative to the tests directory)
find_tests() {
  find "$PROJECT_ROOT/tests" -name "*.test.sh" | sort
}

# Run a test file
run_test() {
  test_file="$1"
  echo "==== Running test: ${test_file#$PROJECT_ROOT/tests/} ===="
  
  # Run from project root for consistency
  cd "$PROJECT_ROOT" || exit 1
  
  # Set path to ai-rizz script to ensure all tests can find it
  AI_RIZZ_PATH="$PROJECT_ROOT/ai-rizz"
  export AI_RIZZ_PATH
  
  if sh "$test_file"; then
    echo "==== PASS: ${test_file#$PROJECT_ROOT/tests/} ===="
    return 0
  else
    echo "==== FAIL: ${test_file#$PROJECT_ROOT/tests/} ===="
    return 1
  fi
}

# Main
# Find the project root directory
PROJECT_ROOT="$(get_project_root)"
echo "Running ai-rizz tests from: $PROJECT_ROOT"

# Verify ai-rizz script exists
if [ ! -f "$PROJECT_ROOT/ai-rizz" ]; then
  echo "ERROR: Cannot find ai-rizz script at $PROJECT_ROOT/ai-rizz" >&2
  exit 1
fi

failed=0
total=0

for test_file in $(find_tests); do
  total=$((total + 1))
  if ! run_test "$test_file"; then
    failed=$((failed + 1))
  fi
  echo
done

# Return to the original directory
cd "$ORIG_DIR" || exit 1

echo "Test results: $((total - failed))/$total passed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi

exit 0 