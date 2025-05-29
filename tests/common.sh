#!/bin/sh
# Common test utilities for shunit2 tests

# Global variables for test environment
TEST_MANIFEST_FILE="test_manifest.skbd"
TEST_SOURCE_REPO="test_repo"
TEST_TARGET_DIR="test_target"
TEST_SHARED_DIR="shared"
TEST_CONFIG_DIR="$HOME/.config/ai-rizz"

# New manifest file constants for dual-mode testing
TEST_COMMIT_MANIFEST_FILE="ai-rizz.skbd"
TEST_LOCAL_MANIFEST_FILE="ai-rizz.local.skbd"

# New directory constants  
TEST_LOCAL_DIR="local"

# Glyph constants will be sourced from ai-rizz script in integration tests

# Test verbosity control
VERBOSE_TESTS="${VERBOSE_TESTS:-false}"
TEST_QUIET_MODE="${TEST_QUIET_MODE:-true}"

# Controlled output functions
test_echo() {
	if [ "$VERBOSE_TESTS" = "true" ]; then
		echo "$@"
	fi
}

test_debug() {
	if [ "$VERBOSE_TESTS" = "true" ]; then
		echo "DEBUG: $*" >&2
	fi
}

test_info() {
	if [ "$VERBOSE_TESTS" = "true" ]; then
		echo "INFO: $*" >&2
	fi
}

# Always show critical messages (errors, failures)
test_error() {
	echo "ERROR: $*" >&2
}

test_fail() {
	echo "FAIL: $*" >&2
}

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
  REPO_DIR="$TEST_DIR/$TEST_SOURCE_REPO"
  
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
  mkdir -p "$TEST_TARGET_DIR/$TEST_SHARED_DIR"

  # Now create the "app" directory
  APP_DIR="${TEST_DIR}/app"
  mkdir -p "$APP_DIR"
  cd "$APP_DIR" || fail "Failed to change to app directory"
  
  # Initialize current directory as git repo for testing
  git init . >/dev/null 2>&1
  git config user.email "test@example.com" >/dev/null 2>&1
  git config user.name "Test User" >/dev/null 2>&1
  
  # Create initial git structure
  mkdir -p .git/info
  touch .git/info/exclude
  
  # Make initial commit to fully initialize the git repository
  echo "Test repository" > README.md
  git add README.md >/dev/null 2>&1
  git commit -m "Initial test setup" >/dev/null 2>&1
  
  # Initialize manifest with source repo and target dir
  echo "$TEST_SOURCE_REPO	$TEST_TARGET_DIR" > "$TEST_MANIFEST_FILE"
}

# Clean up test environment
tearDown() {
  # Return to original directory before removing test directory
  cd / || fail "Failed to return to root directory"
  
  # Remove test directory and all contents
  rm -rf "$TEST_DIR"
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

# Used to verify local mode git exclude management.
# Validates that the specified path has been added to or removed from .gitignore.
#
# Usage: assert_git_exclude_exists <path>
#        assert_git_exclude_not_exists <path>
#
# Arguments:
#   path - The relative path that should be present/absent in .gitignore
#
# Returns:
#   0 on success (assertion passed)
#   1 on failure (via fail function)
assert_git_exclude_exists() {
    path="$1"
    
    assertTrue "Git should be initialized" "[ -d .git ]"
    assertTrue ".gitignore should exist" "[ -f .gitignore ]"
    
    if ! grep -Fxq "$path" .gitignore; then
        fail ".gitignore should contain: $path"
    fi
}

assert_git_exclude_not_exists() {
    path="$1"
    
    # If .gitignore doesn't exist, path is definitely not excluded
    if [ ! -f .gitignore ]; then
        return 0
    fi
    
    if grep -Fxq "$path" .gitignore; then
        fail ".gitignore should not contain: $path"
    fi
}

# Reset ai-rizz global state (call after sourcing to ensure clean state)
reset_ai_rizz_state() {
  
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
  
  test_debug "Sourcing ai-rizz from: $AI_RIZZ_PATH"
  
  # Source the script to get the real implementations
  # shellcheck disable=SC1090
  . "$AI_RIZZ_PATH"
  
  # Restore test environment variables (CRITICAL: must override ai-rizz globals)
  MANIFEST_FILE="$_TEST_MANIFEST_FILE"
  SOURCE_REPO="$_TEST_SOURCE_REPO"
  TARGET_DIR="$_TEST_TARGET_DIR"
  REPO_DIR="$_TEST_REPO_DIR"
  
  # Override functions that interact with external systems for testing
  git_sync() {
    repo_url="$1"
    
    # Simulate failure for invalid URLs
    case "$repo_url" in
      invalid://*|*nonexistent*)
        warn "Failed to clone repository: $repo_url (repository unavailable or invalid URL)"
        return 1
        ;;
      *)
        # For valid URLs, just ensure the test repo directory exists
        if [ ! -d "$REPO_DIR" ]; then
          echo "ERROR: Test repo directory not found: $REPO_DIR" >&2
          return 1
        fi
        return 0
        ;;
    esac
  }
  
  # Reset ai-rizz state to ensure clean state between tests
  reset_ai_rizz_state
}

# ============================================================================
# INTEGRATION TEST UTILITIES
# ============================================================================

# Integration test environment variables
INTEGRATION_TEST_DIR=""
MOCK_REPO_DIR=""
ORIGINAL_PWD=""

# Set up isolated integration test environment
#
# Creates a completely isolated test environment with:
# - Temporary directory for test execution
# - Mock rule repository with realistic structure
# - Fresh git repository for testing
# - Proper environment isolation
#
# Globals:
#   INTEGRATION_TEST_DIR - Set to temporary test directory
#   MOCK_REPO_DIR - Set to mock repository directory
#   ORIGINAL_PWD - Set to original working directory
#   AI_RIZZ_PATH - Set to ai-rizz script path
#
# Arguments:
#   None
#
# Outputs:
#   None (sets up environment)
#
# Returns:
#   0 on success
#   1 on failure
#
setup_integration_test() {
    # Save original directory
    ORIGINAL_PWD="$(pwd)"
    
    # Create temporary test directory
    INTEGRATION_TEST_DIR="$(mktemp -d)"
    test_debug "Created integration test directory: $INTEGRATION_TEST_DIR"
    
    # Change to test directory
    cd "$INTEGRATION_TEST_DIR" || {
        test_error "Failed to change to integration test directory"
        return 1
    }
    
    # Create mock repository
    create_mock_repo || {
        test_error "Failed to create mock repository"
        return 1
    }
    
    # Initialize current directory as git repository
    git init . >/dev/null 2>&1 || {
        test_error "Failed to initialize git repository"
        return 1
    }
    
    # Configure git for testing
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    
    # Create initial git structure
    mkdir -p .git/info
    touch .git/info/exclude
    
    # Make initial commit to fully initialize the git repository
    echo "Integration test repository" > README.md
    git add README.md >/dev/null 2>&1
    git commit -m "Initial integration test setup" >/dev/null 2>&1
    
    # Set up ai-rizz path for integration tests
    if [ -z "$AI_RIZZ_PATH" ]; then
        # Try to find ai-rizz script relative to original directory
        if [ -f "$ORIGINAL_PWD/ai-rizz" ]; then
            AI_RIZZ_PATH="$ORIGINAL_PWD/ai-rizz"
        elif [ -f "$ORIGINAL_PWD/../ai-rizz" ]; then
            AI_RIZZ_PATH="$ORIGINAL_PWD/../ai-rizz"
        else
            test_error "Cannot find ai-rizz script for integration tests"
            return 1
        fi
    fi
    
    test_debug "Using ai-rizz script: $AI_RIZZ_PATH"
    
    return 0
}

# Clean up integration test environment
#
# Removes temporary test directory and restores original working directory.
# Safe to call multiple times.
#
# Globals:
#   INTEGRATION_TEST_DIR - Temporary test directory to remove
#   ORIGINAL_PWD - Original working directory to restore
#
# Arguments:
#   None
#
# Outputs:
#   None
#
# Returns:
#   0 always
#
teardown_integration_test() {
    # Return to original directory
    if [ -n "$ORIGINAL_PWD" ] && [ -d "$ORIGINAL_PWD" ]; then
        cd "$ORIGINAL_PWD" || test_error "Failed to return to original directory"
    fi
    
    # Remove test directory if it exists
    if [ -n "$INTEGRATION_TEST_DIR" ] && [ -d "$INTEGRATION_TEST_DIR" ]; then
        rm -rf "$INTEGRATION_TEST_DIR"
        test_debug "Cleaned up integration test directory: $INTEGRATION_TEST_DIR"
    fi
    
    # Reset environment variables
    INTEGRATION_TEST_DIR=""
    MOCK_REPO_DIR=""
    ORIGINAL_PWD=""
}

# Create mock rule repository for testing
#
# Creates a realistic rule repository structure with:
# - Individual rules with meaningful content
# - Rulesets with symlinks to rules
# - Git repository initialization
# - README documentation
#
# Globals:
#   MOCK_REPO_DIR - Set to mock repository directory path
#
# Arguments:
#   None
#
# Outputs:
#   None (creates directory structure)
#
# Returns:
#   0 on success
#   1 on failure
#
create_mock_repo() {
    MOCK_REPO_DIR="$INTEGRATION_TEST_DIR/mock_repo"
    
    # Create repository structure
    mkdir -p "$MOCK_REPO_DIR/rules"
    mkdir -p "$MOCK_REPO_DIR/rulesets/basic"
    mkdir -p "$MOCK_REPO_DIR/rulesets/advanced"
    mkdir -p "$MOCK_REPO_DIR/rulesets/team"
    
    # Create rule files with realistic content
    cat > "$MOCK_REPO_DIR/rules/rule1.mdc" << 'EOF'
# Basic Rule

This is a basic rule for testing purposes.

## Usage

Use this rule for basic functionality.
EOF

    cat > "$MOCK_REPO_DIR/rules/rule2.mdc" << 'EOF'
# Advanced Rule

This is an advanced rule with more complex functionality.

## Features

- Advanced feature 1
- Advanced feature 2
- Complex logic handling
EOF

    cat > "$MOCK_REPO_DIR/rules/rule3.mdc" << 'EOF'
# Specialized Rule

This rule handles specialized use cases.

## Specializations

- Edge case handling
- Performance optimization
- Error recovery
EOF

    cat > "$MOCK_REPO_DIR/rules/rule4.mdc" << 'EOF'
# Team Rule

This rule is designed for team collaboration.

## Team Features

- Shared conventions
- Collaboration patterns
- Code review guidelines
EOF

    # Create ruleset symlinks
    ln -sf "../../rules/rule1.mdc" "$MOCK_REPO_DIR/rulesets/basic/rule1.mdc"
    ln -sf "../../rules/rule2.mdc" "$MOCK_REPO_DIR/rulesets/basic/rule2.mdc"
    
    ln -sf "../../rules/rule2.mdc" "$MOCK_REPO_DIR/rulesets/advanced/rule2.mdc"
    ln -sf "../../rules/rule3.mdc" "$MOCK_REPO_DIR/rulesets/advanced/rule3.mdc"
    
    ln -sf "../../rules/rule3.mdc" "$MOCK_REPO_DIR/rulesets/team/rule3.mdc"
    ln -sf "../../rules/rule4.mdc" "$MOCK_REPO_DIR/rulesets/team/rule4.mdc"
    
    # Create repository documentation
    cat > "$MOCK_REPO_DIR/README.md" << 'EOF'
# Mock Rule Repository

This is a mock repository for ai-rizz integration testing.

## Structure

- `rules/` - Individual rule files
- `rulesets/` - Collections of related rules

## Rules

- `rule1.mdc` - Basic functionality
- `rule2.mdc` - Advanced features  
- `rule3.mdc` - Specialized use cases
- `rule4.mdc` - Team collaboration

## Rulesets

- `basic/` - Basic rules (rule1, rule2)
- `advanced/` - Advanced rules (rule2, rule3)
- `team/` - Team rules (rule3, rule4)
EOF

    # Initialize mock repository as git repository
    cd "$MOCK_REPO_DIR" || return 1
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    git add . >/dev/null 2>&1
    git commit -m "Initial mock repository" >/dev/null 2>&1
    
    # Return to test directory
    cd "$INTEGRATION_TEST_DIR" || return 1
    
    test_debug "Created mock repository: $MOCK_REPO_DIR"
    return 0
}

# Execute ai-rizz command with proper isolation and error handling
#
# Runs ai-rizz commands in the integration test environment with:
# - Timeout protection to prevent hanging tests
# - Exit code capture for verification
# - Output capture for analysis
# - Environment isolation
#
# Globals:
#   AI_RIZZ_PATH - Path to ai-rizz script
#
# Arguments:
#   $1 - Command to execute (e.g., "init", "add")
#   $@ - Additional arguments to pass to command
#
# Outputs:
#   Stdout: Command output (if any)
#   Stderr: Command errors (if any)
#
# Returns:
#   Exit code from ai-rizz command
#
run_ai_rizz() {
    if [ -z "$AI_RIZZ_PATH" ] || [ ! -f "$AI_RIZZ_PATH" ]; then
        test_error "AI_RIZZ_PATH not set or ai-rizz script not found"
        return 1
    fi
    
    test_debug "Running: ai-rizz $*"
    
    # Execute with timeout protection
    timeout 10s "$AI_RIZZ_PATH" "$@"
}

# Verify manifest file contains specific entry
#
# Checks that a manifest file contains the expected entry.
# Used to verify that add operations correctly update manifests.
#
# Arguments:
#   $1 - Path to manifest file
#   $2 - Entry to check for
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if entry found
#   1 if entry not found (via assertion failure)
#
assert_manifest_contains() {
    manifest_file="$1"
    entry="$2"
    
    assertTrue "Manifest file should exist: $manifest_file" "[ -f '$manifest_file' ]"
    assertTrue "Manifest should contain entry: $entry" "grep -q '^$entry$' '$manifest_file'"
}

# Verify manifest file does not contain specific entry
#
# Checks that a manifest file does not contain the specified entry.
# Used to verify that remove operations correctly update manifests.
#
# Arguments:
#   $1 - Path to manifest file
#   $2 - Entry to check for absence
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if entry not found
#   1 if entry found (via assertion failure)
#
assert_manifest_not_contains() {
    manifest_file="$1"
    entry="$2"
    
    if [ -f "$manifest_file" ]; then
        assertFalse "Manifest should not contain entry: $entry" "grep -q '^$entry$' '$manifest_file'"
    fi
}

# Verify git excludes specific path
#
# Checks that .git/info/exclude contains the specified path.
# Used to verify local mode git exclude management.
#
# Arguments:
#   $1 - Path that should be excluded
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if path is excluded
#   1 if path is not excluded (via assertion failure)
#
assert_git_excludes() {
    path="$1"
    
    assertTrue "Git exclude file should exist" "[ -f '.git/info/exclude' ]"
    assertTrue "Git should exclude path: $path" "grep -q '^$path$' '.git/info/exclude'"
}

# Verify git does not exclude specific path
#
# Checks that .git/info/exclude does not contain the specified path.
# Used to verify commit mode git tracking.
#
# Arguments:
#   $1 - Path that should not be excluded
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if path is not excluded
#   1 if path is excluded (via assertion failure)
#
assert_git_tracks() {
    path="$1"
    
    if [ -f ".git/info/exclude" ]; then
        assertFalse "Git should not exclude path: $path" "grep -q '^$path$' '.git/info/exclude'"
    fi
}

# Verify rule is deployed to target directory
#
# Checks that a rule file exists in the specified target directory.
# Used to verify that sync operations correctly deploy rules.
#
# Arguments:
#   $1 - Target directory path
#   $2 - Rule name (without .mdc extension)
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if rule is deployed
#   1 if rule is not deployed (via assertion failure)
#
assert_rule_deployed() {
    target_dir="$1"
    rule_name="$2"
    rule_file="$target_dir/$rule_name.mdc"
    
    assertTrue "Target directory should exist: $target_dir" "[ -d '$target_dir' ]"
    assertTrue "Rule should be deployed: $rule_file" "[ -f '$rule_file' ]"
}

# Verify rule is not deployed to target directory
#
# Checks that a rule file does not exist in the specified target directory.
# Used to verify that remove operations correctly clean up deployed rules.
#
# Arguments:
#   $1 - Target directory path
#   $2 - Rule name (without .mdc extension)
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if rule is not deployed
#   1 if rule is deployed (via assertion failure)
#
assert_rule_not_deployed() {
    target_dir="$1"
    rule_name="$2"
    rule_file="$target_dir/$rule_name.mdc"
    
    assertFalse "Rule should not be deployed: $rule_file" "[ -f '$rule_file' ]"
}

# Verify directory is empty or does not exist
#
# Checks that a directory either doesn't exist or contains no files.
# Used to verify cleanup operations.
#
# Arguments:
#   $1 - Directory path to check
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if directory is empty or doesn't exist
#   1 if directory contains files (via assertion failure)
#
assert_directory_empty() {
    dir="$1"
    
    if [ -d "$dir" ]; then
        file_count=$(find "$dir" -type f | wc -l)
        assertEquals "Directory should be empty: $dir" "0" "$file_count"
    fi
}

# Verify directory contains expected number of files
#
# Checks that a directory contains exactly the expected number of files.
# Used to verify sync operations deploy the correct number of rules.
#
# Arguments:
#   $1 - Directory path to check
#   $2 - Expected number of files
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if file count matches
#   1 if file count doesn't match (via assertion failure)
#
assert_directory_file_count() {
    dir="$1"
    expected_count="$2"
    
    assertTrue "Directory should exist: $dir" "[ -d '$dir' ]"
    
    actual_count=$(find "$dir" -type f -name "*.mdc" | wc -l)
    assertEquals "Directory file count mismatch: $dir" "$expected_count" "$actual_count"
}

# Verify command output contains expected text
#
# Checks that command output contains the specified text.
# Used for loose output verification without exact matching.
#
# Arguments:
#   $1 - Output text to search
#   $2 - Expected text to find
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if text found
#   1 if text not found (via assertion failure)
#
assert_output_contains() {
    output="$1"
    expected_text="$2"
    
    echo "$output" | grep -q "$expected_text" || \
        fail "Output should contain: $expected_text"
}

# Verify command output does not contain specific text
#
# Checks that command output does not contain the specified text.
# Used to verify error conditions or absence of specific messages.
#
# Arguments:
#   $1 - Output text to search
#   $2 - Text that should not be present
#
# Outputs:
#   None (uses shunit2 assertions)
#
# Returns:
#   0 if text not found
#   1 if text found (via assertion failure)
#
assert_output_not_contains() {
    output="$1"
    unwanted_text="$2"
    
    if echo "$output" | grep -q "$unwanted_text"; then
        fail "Output should not contain: $unwanted_text"
    fi
}

# Create a test rule file with specified content
create_test_rule() {
    target_dir="$1"
    rule_name="$2"
    rule_file="$target_dir/$rule_name.mdc"
    
    # Ensure target directory exists
    mkdir -p "$target_dir"
    
    # Create rule with simple content
    cat > "$rule_file" << EOF
# $rule_name
Test rule content for $rule_name
EOF
    
    # Make it readable
    chmod 644 "$rule_file"
}

# Remove a test rule file
remove_test_rule() {
    target_dir="$1"
    rule_name="$2"
    rule_file="$target_dir/$rule_name.mdc"
    
    if [ -f "$rule_file" ]; then
        rm -f "$rule_file"
    fi
}

# Count files in directory (non-recursive)
count_files_in_dir() {
    dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo "0"
        return
    fi
    
    file_count=$(find "$dir" -maxdepth 1 -type f | wc -l)
    echo "$file_count"
}

# Assert directory contains expected number of files
assert_directory_file_count() {
    dir="$1"
    expected_count="$2"
    
    if [ ! -d "$dir" ]; then
        fail "Directory should exist: $dir"
        return
    fi
    
    actual_count=$(count_files_in_dir "$dir")
    
    assertEquals "File count in $dir" "$expected_count" "$actual_count"
} 