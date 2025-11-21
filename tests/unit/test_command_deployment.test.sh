#!/bin/sh
#
# test_command_deployment.test.sh - Command deployment test suite
#
# Tests command deployment functionality including symlink creation,
# collision detection, and cleanup operations.
#
# Test Coverage:
# Validates command deployment to .cursor/shared-commands/, symlink creation
# in .cursor/commands/, collision detection with user files, and safe removal
# that preserves user-owned files.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_command_deployment.test.sh

# Calculate AI_RIZZ_PATH once at script startup
_TEST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_RIZZ_PATH="${_TEST_SCRIPT_DIR}/../../ai-rizz"
export AI_RIZZ_PATH

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# setUp - runs before each test
setUp() {
  # AI_RIZZ_PATH is already set globally
  
  # Create a temporary test directory
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR" || fail "Failed to change to test directory"
  
  # Set up source ai-rizz for testing
  source_ai_rizz
  
  # Reset ai-rizz state
  reset_ai_rizz_state
  
  # Setup test repository
  REPO_DIR=$(get_repo_dir)
  mkdir -p "$REPO_DIR"
  
  # Create repository structure with commands
  mkdir -p "$REPO_DIR/commands"
  echo "# Review Code Command" > "$REPO_DIR/commands/review-code.md"
  echo "# Create PR Command" > "$REPO_DIR/commands/create-pr.md"
  echo "# Test Command" > "$REPO_DIR/commands/test-cmd.md"
  
  # Initialize git repo
  cd "$REPO_DIR" || fail "Failed to change to repo directory"
  git init . >/dev/null 2>&1
  git config user.email "test@example.com" >/dev/null 2>&1
  git config user.name "Test User" >/dev/null 2>&1
  
  # Add and commit commands
  git add commands/ >/dev/null 2>&1
  git commit -m "Add commands" --no-gpg-sign >/dev/null 2>&1
  
  # Return to test directory
  cd "$TEST_DIR" || fail "Failed to change back to test directory"
  
  # Set COMMANDS_PATH global (used by deploy_command)
  COMMANDS_PATH="commands"
}

# tearDown - runs after each test
tearDown() {
  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    cd /
    rm -rf "$TEST_DIR"
  fi
}

# Test: deploy_command creates file in shared-commands directory
test_deploy_command_creates_file_in_shared_commands() {
  # Setup: ensure directories don't exist yet
  assertFalse "shared-commands should not exist yet" "[ -d .cursor/shared-commands ]"
  
  # Deploy a command
  deploy_command "review-code.md"
  
  # Verify file exists in shared-commands
  assert_file_exists ".cursor/shared-commands/review-code.md"
  
  # Verify content matches source
  expected_content="# Review Code Command"
  actual_content=$(cat .cursor/shared-commands/review-code.md)
  assertEquals "Content should match source" "$expected_content" "$actual_content"
}

# Test: deploy_command creates symlink in commands directory
test_deploy_command_creates_symlink_in_commands() {
  # Setup: ensure directories don't exist yet
  assertFalse "commands should not exist yet" "[ -d .cursor/commands ]"
  
  # Deploy a command
  deploy_command "review-code.md"
  
  # Verify symlink exists in commands/
  assertTrue "Symlink should exist" "[ -L .cursor/commands/review-code.md ]"
  
  # Verify it's actually a symlink (not a regular file)
  assertFalse "Should be symlink, not regular file" "[ -f .cursor/commands/review-code.md ] && [ ! -L .cursor/commands/review-code.md ]"
}

# Test: symlink points to correct target
test_symlink_points_to_correct_target() {
  # Deploy a command
  deploy_command "create-pr.md"
  
  # Verify symlink points to correct target (relative path)
  link_target=$(readlink .cursor/commands/create-pr.md)
  expected_target="../shared-commands/create-pr.md"
  assertEquals "Symlink should point to relative path" "$expected_target" "$link_target"
  
  # Verify symlink is valid (can be followed)
  assertTrue "Symlink should point to valid file" "[ -f .cursor/commands/create-pr.md ]"
}

# Test: collision detection - non-symlink file exists
test_collision_detection_non_symlink_file() {
  # Setup: create a non-symlink file where we want to deploy
  mkdir -p .cursor/commands
  echo "User's own command" > .cursor/commands/review-code.md
  
  # Attempt to deploy should fail
  output=$(deploy_command "review-code.md" 2>&1)
  result=$?
  
  # Verify it failed
  assertNotEquals "Should fail with non-zero exit code" 0 "$result"
  
  # Verify error message is actionable
  echo "$output" | grep -q "not managed by ai-rizz"
  assertTrue "Error should mention file not managed by ai-rizz" $?
  
  # Verify user's file is preserved
  user_content=$(cat .cursor/commands/review-code.md)
  assertEquals "User file should be preserved" "User's own command" "$user_content"
}

# Test: collision detection - wrong symlink target
test_collision_detection_wrong_symlink_target() {
  # Setup: create a symlink pointing elsewhere
  mkdir -p .cursor/commands
  mkdir -p /tmp/elsewhere
  echo "External command" > /tmp/elsewhere/test-cmd.md
  ln -s /tmp/elsewhere/test-cmd.md .cursor/commands/test-cmd.md
  
  # Attempt to deploy should fail
  output=$(deploy_command "test-cmd.md" 2>&1)
  result=$?
  
  # Verify it failed
  assertNotEquals "Should fail with non-zero exit code" 0 "$result"
  
  # Verify error message mentions wrong symlink
  echo "$output" | grep -q "not managed by ai-rizz"
  assertTrue "Error should mention symlink not managed by ai-rizz" $?
  
  # Verify original symlink is preserved
  link_target=$(readlink .cursor/commands/test-cmd.md)
  assertEquals "Original symlink should be preserved" "/tmp/elsewhere/test-cmd.md" "$link_target"
}

# Test: remove_command deletes both files
test_remove_command_deletes_both_files() {
  # Setup: deploy a command first
  deploy_command "review-code.md"
  
  # Verify files exist
  assert_file_exists ".cursor/shared-commands/review-code.md"
  assertTrue "Symlink should exist" "[ -L .cursor/commands/review-code.md ]"
  
  # Remove the command
  remove_command "review-code.md"
  
  # Verify both files are gone
  assert_file_not_exists ".cursor/shared-commands/review-code.md"
  assertFalse "Symlink should be removed" "[ -e .cursor/commands/review-code.md ]"
}

# Test: remove_command ignores non-symlink files
test_remove_command_ignores_non_symlink_files() {
  # Setup: create a user's own file (non-symlink)
  mkdir -p .cursor/commands
  echo "User's personal command" > .cursor/commands/my-cmd.md
  
  # Also create the shared-commands file (simulating partial state)
  mkdir -p .cursor/shared-commands
  echo "Managed command" > .cursor/shared-commands/my-cmd.md
  
  # Remove the command
  remove_command "my-cmd.md"
  
  # Verify user's file is preserved
  assert_file_exists ".cursor/commands/my-cmd.md"
  user_content=$(cat .cursor/commands/my-cmd.md)
  assertEquals "User file should be preserved" "User's personal command" "$user_content"
  
  # Verify managed file is removed
  assert_file_not_exists ".cursor/shared-commands/my-cmd.md"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
