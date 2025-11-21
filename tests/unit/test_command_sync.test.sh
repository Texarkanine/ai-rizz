#!/bin/sh
#
# test_command_sync.test.sh - Command sync integration test suite
#
# Tests the sync_commands() function and its integration with sync_all_modes()
#
# Test Coverage:
# Validates that commands sync from manifest, stale commands are removed,
# missing commands are handled gracefully, and collisions don't break sync.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_command_sync.test.sh

# Calculate AI_RIZZ_PATH once at script startup
_TEST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_RIZZ_PATH="${_TEST_SCRIPT_DIR}/../../ai-rizz"
export AI_RIZZ_PATH

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# setUp - runs before each test
setUp() {
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
  
  # Set COMMANDS_PATH global (used by sync_commands and deploy_command)
  COMMANDS_PATH="commands"
  COMMIT_MANIFEST_FILE="ai-rizz.skbd"
}

# tearDown - runs after each test
tearDown() {
  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    cd /
    rm -rf "$TEST_DIR"
  fi
}

# Test: sync_commands reads manifest and deploys all commands
test_sync_commands_reads_manifest() {
  # Create V2 manifest with 2 commands
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  
  # Run sync_commands
  sync_commands
  
  # Verify both commands deployed
  assertTrue "review-code.md should exist in shared-commands" "[ -f .cursor/shared-commands/review-code.md ]"
  assertTrue "review-code.md symlink should exist" "[ -L .cursor/commands/review-code.md ]"
  assertTrue "create-pr.md should exist in shared-commands" "[ -f .cursor/shared-commands/create-pr.md ]"
  assertTrue "create-pr.md symlink should exist" "[ -L .cursor/commands/create-pr.md ]"
}

# Test: sync_commands deploys all commands from manifest
test_sync_commands_deploys_all() {
  # Create V2 manifest with 3 commands
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/test-cmd.md" >> "$COMMIT_MANIFEST_FILE"
  
  # Run sync_commands
  sync_commands
  
  # Verify all 3 commands deployed (files + symlinks)
  assertTrue "review-code.md file should exist" "[ -f .cursor/shared-commands/review-code.md ]"
  assertTrue "review-code.md symlink should exist" "[ -L .cursor/commands/review-code.md ]"
  
  assertTrue "create-pr.md file should exist" "[ -f .cursor/shared-commands/create-pr.md ]"
  assertTrue "create-pr.md symlink should exist" "[ -L .cursor/commands/create-pr.md ]"
  
  assertTrue "test-cmd.md file should exist" "[ -f .cursor/shared-commands/test-cmd.md ]"
  assertTrue "test-cmd.md symlink should exist" "[ -L .cursor/commands/test-cmd.md ]"
  
  # Verify symlinks point to correct targets
  link_target=$(readlink .cursor/commands/review-code.md)
  assertEquals "Symlink should point to shared-commands" "../shared-commands/review-code.md" "$link_target"
}

# Test: sync_commands removes stale commands (not in manifest)
test_sync_commands_removes_stale() {
  # Initial setup: Create V2 manifest with 3 commands and sync
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/test-cmd.md" >> "$COMMIT_MANIFEST_FILE"
  
  sync_commands
  
  # Verify all 3 deployed
  assertTrue "review-code.md should exist" "[ -L .cursor/commands/review-code.md ]"
  assertTrue "create-pr.md should exist" "[ -L .cursor/commands/create-pr.md ]"
  assertTrue "test-cmd.md should exist" "[ -L .cursor/commands/test-cmd.md ]"
  
  # Add a user's own file (non-symlink) to .cursor/commands/
  echo "# User's command" > .cursor/commands/user-cmd.md
  
  # Update manifest to remove test-cmd.md (keep only 2)
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  
  # Run sync_commands again
  sync_commands
  
  # Verify: 2 commands remain, 1 removed
  assertTrue "review-code.md should still exist" "[ -L .cursor/commands/review-code.md ]"
  assertTrue "create-pr.md should still exist" "[ -L .cursor/commands/create-pr.md ]"
  assertFalse "test-cmd.md symlink should be removed" "[ -L .cursor/commands/test-cmd.md ]"
  assertFalse "test-cmd.md file should be removed" "[ -f .cursor/shared-commands/test-cmd.md ]"
  
  # Verify: user's non-symlink file untouched
  assertTrue "user-cmd.md should still exist" "[ -f .cursor/commands/user-cmd.md ]"
  assertFalse "user-cmd.md should NOT be a symlink" "[ -L .cursor/commands/user-cmd.md ]"
}

# Test: sync_commands skips missing commands gracefully
test_sync_commands_skips_missing() {
  # Create V2 manifest with one valid and one missing command
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/nonexistent.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  
  # Run sync_commands (should not fail)
  sync_commands
  
  # Verify: valid commands deployed
  assertTrue "review-code.md should be deployed" "[ -f .cursor/shared-commands/review-code.md ]"
  assertTrue "create-pr.md should be deployed" "[ -f .cursor/shared-commands/create-pr.md ]"
  
  # Verify: missing command skipped (not deployed)
  assertFalse "nonexistent.md should not be deployed" "[ -f .cursor/shared-commands/nonexistent.md ]"
  assertFalse "nonexistent.md symlink should not exist" "[ -L .cursor/commands/nonexistent.md ]"
}

# Test: sync_all_modes calls sync_commands
test_sync_all_modes_calls_sync_commands() {
  # Create V2 commit mode manifest with commands
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  
  # Run sync_all_modes (should call sync_commands)
  sync_all_modes
  
  # Verify commands were synced
  assertTrue "Commands should be synced via sync_all_modes" "[ -f .cursor/shared-commands/review-code.md ]"
  assertTrue "Symlinks should be created via sync_all_modes" "[ -L .cursor/commands/review-code.md ]"
}

# Test: sync handles collisions gracefully
test_sync_handles_collisions_gracefully() {
  # Create a non-symlink file that will collide
  mkdir -p .cursor/commands
  echo "# User's existing file" > .cursor/commands/review-code.md
  
  # Create V2 manifest with colliding command and others
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "file://$REPO_DIR" ".cursor/rules" "rules" "rulesets" "commands" "commandsets" > "$COMMIT_MANIFEST_FILE"
  echo "commands/review-code.md" >> "$COMMIT_MANIFEST_FILE"
  echo "commands/create-pr.md" >> "$COMMIT_MANIFEST_FILE"
  
  # Run sync_commands (should warn but continue)
  sync_commands
  
  # Verify: collision prevented (file untouched)
  assertFalse "review-code.md should NOT be a symlink (collision)" "[ -L .cursor/commands/review-code.md ]"
  assertTrue "review-code.md should still be user's file" "[ -f .cursor/commands/review-code.md ]"
  assertFalse "review-code.md should NOT be in shared-commands" "[ -f .cursor/shared-commands/review-code.md ]"
  
  # Verify: other commands still sync (graceful handling)
  assertTrue "create-pr.md should be deployed despite collision" "[ -f .cursor/shared-commands/create-pr.md ]"
  assertTrue "create-pr.md symlink should exist" "[ -L .cursor/commands/create-pr.md ]"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
