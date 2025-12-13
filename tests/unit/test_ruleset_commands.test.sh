#!/bin/sh
#
# test_ruleset_commands.test.sh - Ruleset commands subdirectory test suite
#
# Tests all operations related to rulesets containing a `commands/` subdirectory,
# including validation that commands can only be added in commit mode, command
# file copying, and proper error handling.
#
# Test Coverage:
# - Ruleset with commands rejects local mode
# - Ruleset with commands allows commit mode
# - Ruleset without commands works in local mode
# - Commands copied to correct location
# - Commands directory created if missing
# - Symlink handling in commands directory
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_ruleset_commands.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# DETECTION AND VALIDATION TESTS
# ============================================================================

# Test that adding a ruleset with commands/ subdirectory in local mode is rejected
# Expected: Error message explaining that rulesets with commands must be committed
test_ruleset_with_commands_rejects_local_mode() {
	# Setup: Create ruleset with commands/ subdirectory
	mkdir -p "$REPO_DIR/rulesets/ruleset-with-commands"
	mkdir -p "$REPO_DIR/rulesets/ruleset-with-commands/commands"
	echo "command content" > "$REPO_DIR/rulesets/ruleset-with-commands/commands/test-command.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/ruleset-with-commands/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with commands" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in local mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Try to add ruleset in local mode
	output=$(cmd_add_ruleset "ruleset-with-commands" --local 2>&1)
	exit_code=$?
	
	# Expected: Error with helpful message, ruleset not added
	assertEquals "Should exit with error code" 1 $exit_code
	echo "$output" | grep -q "commands" || fail "Error message should mention commands"
	echo "$output" | grep -q "commit" || fail "Error message should mention commit mode"
	
	# Verify ruleset was NOT added to manifest
	if [ -f "$TEST_LOCAL_MANIFEST_FILE" ]; then
		grep -q "ruleset-with-commands" "$TEST_LOCAL_MANIFEST_FILE" && fail "Ruleset should not be added to manifest"
	fi
}

# Test that adding a ruleset with commands/ subdirectory in commit mode is allowed
# Expected: Ruleset added successfully, commands copied to .cursor/commands/
test_ruleset_with_commands_allows_commit_mode() {
	# Setup: Create ruleset with commands/ subdirectory
	mkdir -p "$REPO_DIR/rulesets/ruleset-with-commands"
	mkdir -p "$REPO_DIR/rulesets/ruleset-with-commands/commands"
	echo "command content" > "$REPO_DIR/rulesets/ruleset-with-commands/commands/test-command.md"
	echo "another command" > "$REPO_DIR/rulesets/ruleset-with-commands/commands/other-command.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/ruleset-with-commands/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with commands" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset in commit mode
	cmd_add_ruleset "ruleset-with-commands" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Success, commands copied to commands/ (relative to TARGET_DIR parent)
	# TARGET_DIR is "test_target", so commands dir is $(dirname "test_target")/commands = "commands"
	commands_dir="commands"
	test -d "$commands_dir" || fail "Commands directory should be created"
	test -f "$commands_dir/test-command.md" || fail "test-command.md should be copied"
	test -f "$commands_dir/other-command.md" || fail "other-command.md should be copied"
}

# Test that adding a ruleset without commands/ subdirectory works in local mode
# Expected: Normal behavior - ruleset added successfully (existing behavior)
test_ruleset_without_commands_works_in_local_mode() {
	# Setup: Create ruleset without commands/ subdirectory (use existing ruleset1)
	# ruleset1 is already created in setUp()
	
	# Initialize in local mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Add ruleset in local mode
	cmd_add_ruleset "ruleset1" --local
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Success (existing behavior preserved)
	# Verify ruleset was added to manifest
	grep -q "rulesets/ruleset1" "$TEST_LOCAL_MANIFEST_FILE" || fail "Ruleset should be in manifest"
	
	# Verify rules were copied
	test -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc" || fail "rule1.mdc should be copied"
	test -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc" || fail "rule2.mdc should be copied"
}

# ============================================================================
# COMMAND COPYING TESTS
# ============================================================================

# Test that commands are copied to the correct location (.cursor/commands/)
# Expected: All files from rulesets/X/commands/ are present in .cursor/commands/
test_commands_copied_to_correct_location() {
	# Setup: Create ruleset with commands/ subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-commands"
	mkdir -p "$REPO_DIR/rulesets/test-commands/commands"
	echo "file1 content" > "$REPO_DIR/rulesets/test-commands/commands/file1.md"
	echo "file2 content" > "$REPO_DIR/rulesets/test-commands/commands/file2.txt"
	echo "file3 content" > "$REPO_DIR/rulesets/test-commands/commands/file3.sh"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-commands/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-commands ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Add ruleset with commands in commit mode
	cmd_add_ruleset "test-commands" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Action: Verify files in commands/ (relative to TARGET_DIR parent)
	commands_dir="commands"
	test -d "$commands_dir" || fail "Commands directory should exist"
	test -f "$commands_dir/file1.md" || fail "file1.md should be copied"
	test -f "$commands_dir/file2.txt" || fail "file2.txt should be copied"
	test -f "$commands_dir/file3.sh" || fail "file3.sh should be copied"
	
	# Expected: All files from rulesets/X/commands/ present
	# Verify content matches
	assertEquals "file1.md content should match" "file1 content" "$(cat "$commands_dir/file1.md")"
	assertEquals "file2.txt content should match" "file2 content" "$(cat "$commands_dir/file2.txt")"
}

# Test that symlinks in commands/ directory are followed correctly
# Expected: Actual source content is copied, not the symlink itself
test_commands_symlinks_followed_correctly() {
	# Setup: Create ruleset with commands/ containing symlinks
	mkdir -p "$REPO_DIR/rulesets/test-symlinks"
	mkdir -p "$REPO_DIR/rulesets/test-symlinks/commands"
	echo "original content" > "$REPO_DIR/rulesets/test-symlinks/commands/original.md"
	ln -sf "original.md" "$REPO_DIR/rulesets/test-symlinks/commands/symlink.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-symlinks/commands/rule-symlink.mdc"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-symlinks/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-symlinks ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset in commit mode
	cmd_add_ruleset "test-symlinks" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Symlink targets copied, not symlinks themselves
	commands_dir="commands"
	test -f "$commands_dir/original.md" || fail "original.md should be copied"
	test -f "$commands_dir/symlink.md" || fail "symlink.md should be copied (as file, not symlink)"
	test ! -L "$commands_dir/symlink.md" || fail "symlink.md should be a file, not a symlink"
	assertEquals "symlink.md content should match original" "original content" "$(cat "$commands_dir/symlink.md")"
	
	# Verify rule symlink was also followed
	test -f "$commands_dir/rule-symlink.mdc" || fail "rule-symlink.mdc should be copied"
	test ! -L "$commands_dir/rule-symlink.mdc" || fail "rule-symlink.mdc should be a file, not a symlink"
}

# Test that commands directory is created if it doesn't exist
# Expected: .cursor/commands/ directory created automatically
test_commands_directory_created_if_missing() {
	# Setup: Create ruleset with commands/ subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-auto-create"
	mkdir -p "$REPO_DIR/rulesets/test-auto-create/commands"
	echo "test command" > "$REPO_DIR/rulesets/test-auto-create/commands/test.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-auto-create/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-auto-create ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Ensure commands/ doesn't exist
	rm -rf "commands"
	test ! -d "commands" || fail "Commands directory should not exist initially"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset with commands in commit mode
	cmd_add_ruleset "test-auto-create" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Directory created, files copied
	test -d "commands" || fail "Commands directory should be created"
	test -f "commands/test.md" || fail "test.md should be copied"
}

# Test that commands are not copied in local mode (even if somehow bypassed)
# Expected: Commands directory not created when in local mode
test_commands_not_copied_in_local_mode() {
	# Setup: Create ruleset with commands/ subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-no-local"
	mkdir -p "$REPO_DIR/rulesets/test-no-local/commands"
	echo "command content" > "$REPO_DIR/rulesets/test-no-local/commands/test.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-no-local/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-no-local ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in local mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Ensure commands/ doesn't exist
	rm -rf "commands"
	
	# Action: Try to add ruleset (should fail)
	output=$(cmd_add_ruleset "test-no-local" --local 2>&1)
	exit_code=$?
	
	# Expected: Should fail
	assertEquals "Should exit with error code" 1 $exit_code
	
	# Verify commands/ not created
	test ! -d "commands" || fail "Commands directory should not be created in local mode"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

