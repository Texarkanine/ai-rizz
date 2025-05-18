#!/bin/sh
# Common test utilities for shunit2 tests

# Global variables for test environment
MANIFEST_FILE="test_manifest.inf"
SOURCE_REPO="test_repo"
TARGET_DIR="test_target"
SHARED_DIR="shared"
CONFIG_DIR="$HOME/.config/ai-rizz"

# Create a temporary test directory and set up test environment
setUp() {
  # Create a temporary test directory
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR" || fail "Failed to change to test directory"
  
  # Set REPO_DIR to point to the test repo
  REPO_DIR="$TEST_DIR/$SOURCE_REPO"
  
  # Create repo directory structure
  mkdir -p "$REPO_DIR/rules"
  mkdir -p "$REPO_DIR/rulesets/ruleset1"
  mkdir -p "$REPO_DIR/rulesets/ruleset2"
  
  # Create rule files
  echo "Rule 1 content" > "$REPO_DIR/rules/rule1.mdc"
  echo "Rule 2 content" > "$REPO_DIR/rules/rule2.mdc"
  echo "Rule 3 content" > "$REPO_DIR/rules/rule3.mdc"
  
  # Create ruleset symlinks
  ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/ruleset1/rule1.mdc"
  ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/ruleset1/rule2.mdc"
  ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/ruleset2/rule2.mdc"
  ln -sf "$REPO_DIR/rules/rule3.mdc" "$REPO_DIR/rulesets/ruleset2/rule3.mdc"
  
  # Create target directory
  mkdir -p "$TARGET_DIR/$SHARED_DIR"
  
  # Initialize manifest with source repo and target dir
  echo "$SOURCE_REPO	$TARGET_DIR" > "$MANIFEST_FILE"
}

# Clean up test environment
tearDown() {
  # Return to original directory before removing test directory
  cd / || fail "Failed to return to root directory"
  
  # Remove test directory and all contents
  rm -rf "$TEST_DIR"
}

# Mock git_sync function for testing
git_sync() {
  return 0  # Do nothing in testing environment
}

# Read and validate manifest file
# Sets: SOURCE_REPO, TARGET_DIR, MANIFEST_ENTRIES
read_manifest() {
  if [ ! -f "$MANIFEST_FILE" ]; then
    fail "Manifest file '$MANIFEST_FILE' not found"
  fi
  
  # Read first line to get source repo and target dir
  read -r first_line < "$MANIFEST_FILE"
  
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
  MANIFEST_ENTRIES=$(echo "$MANIFEST_ENTRIES" | grep -v "^$entry$" || true)
  
  return 0
}

# Utility function to check if a file exists
assert_file_exists() {
  assertTrue "File should exist: $1" "[ -f '$1' ]"
}

# Utility function to check if a file does not exist
assert_file_not_exists() {
  assertFalse "File should not exist: $1" "[ -f '$1' ]"
}

# Utility function to check if a string equals expected value
assert_equals() {
  assertEquals "$3" "$1" "$2"
}

# Source the ai-rizz script - only use this in test files that need to test the actual implementation
source_ai_rizz() {
  # Find the correct path to ai-rizz
  AI_RIZZ_PATH="${AI_RIZZ_PATH:-../../ai-rizz}"
  
  # Override functions that interact with the real system
  git_sync() { return 0; }
  
  # Source the script
  # shellcheck disable=SC1090
  . "$AI_RIZZ_PATH"
} 