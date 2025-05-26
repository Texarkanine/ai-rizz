#!/bin/sh
# Common test utilities for shunit2 tests

# Global variables for test environment
MANIFEST_FILE="test_manifest.inf"
SOURCE_REPO="test_repo"
TARGET_DIR="test_target"
SHARED_DIR="shared"
CONFIG_DIR="$HOME/.config/ai-rizz"

# New manifest file constants for dual-mode testing
COMMIT_MANIFEST_FILE="ai-rizz.inf"
LOCAL_MANIFEST_FILE="ai-rizz.local.inf"

# New directory constants  
LOCAL_DIR="local"

# New glyph constants for testing
COMMITTED_GLYPH="●"
LOCAL_GLYPH="◐"
UNINSTALLED_GLYPH="○"

# Create a temporary test directory and set up test environment
setUp() {
  # Create a temporary test directory
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR" || fail "Failed to change to test directory"
  
  # Reset ai-rizz state to ensure clean state between tests
  if command -v reset_ai_rizz_state >/dev/null 2>&1; then
    reset_ai_rizz_state
  fi
  
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
  
  # Initialize test_repo as a git repository
  cd "$REPO_DIR" || fail "Failed to change to repo directory"
  git init . >/dev/null 2>&1
  git add . >/dev/null 2>&1
  git commit -m "Initial commit" >/dev/null 2>&1
  cd "$TEST_DIR" || fail "Failed to change back to test directory"
  
  # Create target directory
  mkdir -p "$TARGET_DIR/$SHARED_DIR"
  
  # Initialize current directory as git repo for testing
  git init . >/dev/null 2>&1
  git config user.email "test@example.com" >/dev/null 2>&1
  git config user.name "Test User" >/dev/null 2>&1
  
  # Create initial git structure
  mkdir -p .git/info
  touch .git/info/exclude
  
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
  # Return success silently
  return 0
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

# Mode detection utilities
assert_local_mode_exists() {
    assertTrue "Local manifest should exist" "[ -f '$LOCAL_MANIFEST_FILE' ]"
    assertTrue "Local directory should exist" "[ -d '$TARGET_DIR/$LOCAL_DIR' ]"
}

assert_commit_mode_exists() {
    assertTrue "Commit manifest should exist" "[ -f '$COMMIT_MANIFEST_FILE' ]"  
    assertTrue "Commit directory should exist" "[ -d '$TARGET_DIR/$SHARED_DIR' ]"
}

assert_no_modes_exist() {
    assertFalse "Local manifest should not exist" "[ -f '$LOCAL_MANIFEST_FILE' ]"
    assertFalse "Commit manifest should not exist" "[ -f '$COMMIT_MANIFEST_FILE' ]"
}

# Git exclude testing utilities
assert_git_exclude_contains() {
    assertTrue "Git exclude should contain $1" "grep -q '^$1$' .git/info/exclude"
}

assert_git_exclude_not_contains() {
    assertFalse "Git exclude should not contain $1" "grep -q '^$1$' .git/info/exclude"
}

# Legacy repository setup for migration testing
setup_legacy_local_repo() {
    # Create old-style local mode setup
    echo "$SOURCE_REPO	$TARGET_DIR" > "$COMMIT_MANIFEST_FILE"
    echo "rules/rule1.mdc" >> "$COMMIT_MANIFEST_FILE"
    mkdir -p "$TARGET_DIR/$SHARED_DIR"
    cp "$REPO_DIR/rules/rule1.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # Add to git exclude to simulate legacy local mode
    mkdir -p .git/info
    echo "$COMMIT_MANIFEST_FILE" > .git/info/exclude
    echo "$TARGET_DIR/$SHARED_DIR" >> .git/info/exclude
}

setup_legacy_commit_repo() {
    # Create old-style commit mode setup  
    echo "$SOURCE_REPO	$TARGET_DIR" > "$COMMIT_MANIFEST_FILE"
    echo "rules/rule1.mdc" >> "$COMMIT_MANIFEST_FILE"
    mkdir -p "$TARGET_DIR/$SHARED_DIR"
    cp "$REPO_DIR/rules/rule1.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # No git exclude entries = commit mode
}

# Reset ai-rizz global state (call after sourcing to ensure clean state)
reset_ai_rizz_state() {
  # Reset mode detection state
  HAS_LOCAL_MODE=false
  HAS_COMMIT_MODE=false
  
  # Reset cached metadata
  COMMIT_SOURCE_REPO=""
  LOCAL_SOURCE_REPO=""
  COMMIT_TARGET_DIR=""
  LOCAL_TARGET_DIR=""
}

# Source the ai-rizz script - use this in test files to test the actual implementation
source_ai_rizz() {
  # Save original global variables that we need to restore after sourcing
  _TEST_MANIFEST_FILE="$MANIFEST_FILE"
  _TEST_SOURCE_REPO="$SOURCE_REPO"
  _TEST_TARGET_DIR="$TARGET_DIR"
  _TEST_REPO_DIR="$REPO_DIR"
  
  # Mock git operations silently
  git_sync() { return 0; }
  
  # Override git command with silent function that always succeeds
  git() { return 0; }
  
  # Find path to ai-rizz script using best available method
  # 1. Use AI_RIZZ_PATH from environment if provided
  # 2. Try project root paths (run_tests.sh runs tests from project root)
  # 3. Try relative paths from test directory
  if [ -n "$AI_RIZZ_PATH" ] && [ -f "$AI_RIZZ_PATH" ]; then
    :  # AI_RIZZ_PATH is already set and valid
  elif [ -f "./ai-rizz" ]; then
    AI_RIZZ_PATH="./ai-rizz"
  elif [ -f "$(dirname "$0")/../ai-rizz" ]; then
    AI_RIZZ_PATH="$(dirname "$0")/../ai-rizz"
  elif [ -f "$(dirname "$0")/../../ai-rizz" ]; then
    AI_RIZZ_PATH="$(dirname "$0")/../../ai-rizz"
  else
    echo "ERROR: Cannot find ai-rizz script" >&2
    return 1
  fi
  
  echo "Sourcing ai-rizz from: $AI_RIZZ_PATH" >&2
  
  # Source the script to get the real implementations
  # shellcheck disable=SC1090
  . "$AI_RIZZ_PATH"
  
  # Restore test environment variables
  MANIFEST_FILE="$_TEST_MANIFEST_FILE"
  SOURCE_REPO="$_TEST_SOURCE_REPO"
  TARGET_DIR="$_TEST_TARGET_DIR"
  REPO_DIR="$_TEST_REPO_DIR"
  
  # Reset ai-rizz state to ensure clean state between tests
  reset_ai_rizz_state
} 