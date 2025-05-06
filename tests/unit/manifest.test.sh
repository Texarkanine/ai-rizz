#!/bin/sh
# Test script for manifest operations

# Create test directory
TEST_DIR="$(mktemp -d)"
cd "$TEST_DIR" || exit 1
echo "Running tests in $TEST_DIR"

# Set up our own versions of the functions to test
MANIFEST_FILE="test_manifest.inf"

# Create test versions of the functions directly
# Read and validate manifest file
# Sets: SOURCE_REPO, TARGET_DIR, MANIFEST_ENTRIES
read_manifest() {
  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "Error: Manifest file '$MANIFEST_FILE' not found" >&2
    exit 1
  fi
  
  # Read first line to get source repo and target dir
  read -r first_line < "$MANIFEST_FILE"
  
  # Check if it has the correct format (tab-separated)
  if ! echo "$first_line" | grep -q "	"; then
    echo "Error: Invalid manifest format: First line must be 'source_repo<tab>target_dir'" >&2
    exit 1
  fi
  
  # Extract the source repo and target dir
  SOURCE_REPO=$(echo "$first_line" | cut -f1)
  TARGET_DIR=$(echo "$first_line" | cut -f2)
  
  # Read the rest of the manifest file
  MANIFEST_ENTRIES=""
  while IFS= read -r line; do
    if [ -n "$line" ] && [ "$line" != "$first_line" ]; then
      MANIFEST_ENTRIES="$MANIFEST_ENTRIES
$line"
    fi
  done < "$MANIFEST_FILE"
  
  # Trim leading newline
  MANIFEST_ENTRIES=$(echo "$MANIFEST_ENTRIES" | sed '/./,$!d')
  
  return 0
}

# Write manifest file
write_manifest() {
  if [ -z "$SOURCE_REPO" ] || [ -z "$TARGET_DIR" ]; then
    echo "Error: SOURCE_REPO and TARGET_DIR must be set before writing manifest" >&2
    exit 1
  fi
  
  # Write the first line
  echo "$SOURCE_REPO	$TARGET_DIR" > "$MANIFEST_FILE"
  
  # Write the rest of the entries
  if [ -n "$MANIFEST_ENTRIES" ]; then
    echo "$MANIFEST_ENTRIES" >> "$MANIFEST_FILE"
  fi
  
  return 0
}

# Add entry to manifest
add_manifest_entry() {
  entry="$1"
  
  # Check if entry already exists
  if echo "$MANIFEST_ENTRIES" | grep -q "^$entry$"; then
    return 0  # Already exists, nothing to do
  fi
  
  # Add the entry
  if [ -z "$MANIFEST_ENTRIES" ]; then
    MANIFEST_ENTRIES="$entry"
  else
    MANIFEST_ENTRIES="$MANIFEST_ENTRIES
$entry"
  fi
  
  return 0
}

# Remove entry from manifest
remove_manifest_entry() {
  entry="$1"
  
  # Remove the entry
  MANIFEST_ENTRIES=$(echo "$MANIFEST_ENTRIES" | grep -v "^$entry$")
  
  return 0
}

# Set up test functions
run_test() {
  test_name="$1"
  echo "==== Test: $test_name ===="
  shift
  if "$@"; then
    echo "PASS: $test_name"
    return 0
  else
    echo "FAIL: $test_name"
    return 1
  fi
}

assert_equals() {
  expected="$1"
  actual="$2"
  message="$3"
  
  if [ "$expected" = "$actual" ]; then
    return 0
  else
    echo "Assertion failed: $message"
    echo "Expected: '$expected'"
    echo "Actual  : '$actual'"
    return 1
  fi
}

# Test cases

test_write_manifest() {
  # Set up
  rm -f "$MANIFEST_FILE"
  
  # Test
  SOURCE_REPO="https://github.com/example/rules.git"
  TARGET_DIR=".cursor/rules"
  MANIFEST_ENTRIES="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  
  # Run the function
  write_manifest
  
  # Verify
  expected="https://github.com/example/rules.git	.cursor/rules
rules/foo.mdc
rules/bar.mdc
rulesets/code"
  actual=$(cat "$MANIFEST_FILE")
  
  assert_equals "$expected" "$actual" "Manifest file has correct content"
}

test_read_manifest() {
  # Set up
  cat > "$MANIFEST_FILE" << EOF
https://github.com/example/rules.git	.cursor/rules
rules/foo.mdc
rules/bar.mdc
rulesets/code
EOF
  
  # Run the function
  read_manifest
  
  # Verify
  assert_equals "https://github.com/example/rules.git" "$SOURCE_REPO" "SOURCE_REPO is set correctly"
  assert_equals ".cursor/rules" "$TARGET_DIR" "TARGET_DIR is set correctly"
  expected="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  assert_equals "$expected" "$MANIFEST_ENTRIES" "MANIFEST_ENTRIES is set correctly"
}

test_add_manifest_entry() {
  # Set up
  MANIFEST_ENTRIES="rules/foo.mdc
rules/bar.mdc"
  
  # Run the function
  add_manifest_entry "rulesets/code"
  
  # Verify
  expected="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  assert_equals "$expected" "$MANIFEST_ENTRIES" "Entry was added correctly"
  
  # Test duplicate
  add_manifest_entry "rules/foo.mdc"
  assert_equals "$expected" "$MANIFEST_ENTRIES" "Duplicate entry was not added"
}

test_remove_manifest_entry() {
  # Set up
  MANIFEST_ENTRIES="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  
  # Run the function
  remove_manifest_entry "rules/bar.mdc"
  
  # Verify
  expected="rules/foo.mdc
rulesets/code"
  assert_equals "$expected" "$MANIFEST_ENTRIES" "Entry was removed correctly"
  
  # Test nonexistent
  remove_manifest_entry "nonexistent"
  assert_equals "$expected" "$MANIFEST_ENTRIES" "Nonexistent entry removal is a no-op"
}

# Run the tests
run_test "Write Manifest" test_write_manifest
run_test "Read Manifest" test_read_manifest
run_test "Add Manifest Entry" test_add_manifest_entry
run_test "Remove Manifest Entry" test_remove_manifest_entry

# Clean up
rm -rf "$TEST_DIR"
echo "Test complete" 