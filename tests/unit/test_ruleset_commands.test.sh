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

# Test that adding a ruleset with commands/ subdirectory works in local mode
# Expected: Successfully added in local mode, commands copied to .cursor/commands/local/
test_ruleset_with_commands_works_in_local_mode() {
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
	
	# Initialize both modes
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset with --local flag (should work now, no longer auto-switches)
	output=$(cmd_add_ruleset "ruleset-with-commands" --local 2>&1)
	exit_code=$?

	# Expected: Success without warning, added to local mode
	assertEquals "Should exit with success code" 0 $exit_code
	echo "$output" | grep -q "Switching to commit mode" && fail "Should NOT show warning about switching to commit mode"
	
	# Verify ruleset was added to LOCAL manifest (not commit)
	test -f "$TEST_LOCAL_MANIFEST_FILE" || fail "Local manifest should be created"
	grep -q "ruleset-with-commands" "$TEST_LOCAL_MANIFEST_FILE" || fail "Ruleset should be added to local manifest"
	if [ -f "$TEST_COMMIT_MANIFEST_FILE" ]; then
		grep -q "ruleset-with-commands" "$TEST_COMMIT_MANIFEST_FILE" && fail "Ruleset should NOT be added to commit manifest"
	fi
	
	# Verify commands were copied to local commands directory
	test -d ".cursor/commands/local" || fail "Local commands directory should be created"
	test -f ".cursor/commands/local/test-command.md" || fail "test-command.md should be copied to local commands dir"
	return 0
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
	commands_dir=".cursor/commands/shared"
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
	commands_dir=".cursor/commands/shared"
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
	commands_dir=".cursor/commands/shared"
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
	rm -rf ".cursor/commands"
	test ! -d ".cursor/commands" || fail "Commands directory should not exist initially"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset with commands in commit mode
	cmd_add_ruleset "test-auto-create" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Directory created, files copied
	test -d ".cursor/commands/shared" || fail "Commands directory should be created"
	test -f ".cursor/commands/shared/test.md" || fail "test.md should be copied"
}

# Test that adding ruleset with commands works in local mode (no auto-switch)
# Expected: Commands copied to local commands directory
test_ruleset_with_commands_in_local_only_mode() {
	# Setup: Create ruleset with commands/ subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-local-cmd"
	mkdir -p "$REPO_DIR/rulesets/test-local-cmd/commands"
	echo "command content" > "$REPO_DIR/rulesets/test-local-cmd/commands/test.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-local-cmd/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-local-cmd ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize only in local mode (commit mode not initialized)
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Add ruleset with --local (should work, no longer auto-switches)
	output=$(cmd_add_ruleset "test-local-cmd" --local 2>&1)
	exit_code=$?
	
	# Expected: Should succeed in local mode
	assertEquals "Should exit with success code" 0 $exit_code
	echo "$output" | grep -q "Switching to commit mode" && fail "Should NOT show warning about switching to commit mode"
	
	# Verify commands/ WAS created in local commands directory
	test -d ".cursor/commands/local" || fail "Local commands directory should be created"
	test -f ".cursor/commands/local/test.md" || fail "test.md should be copied to local commands dir"
	
	# Verify ruleset was added to local manifest (not commit)
	grep -q "test-local-cmd" "$TEST_LOCAL_MANIFEST_FILE" || fail "Ruleset should be added to local manifest"
}

# ============================================================================
# REMOVE RULESET MODE FLAG TESTS
# ============================================================================

# Test that cmd_remove_ruleset parses --global flag correctly
# Expected: Removes ruleset from global mode only, doesn't treat --global as ruleset name
test_remove_ruleset_global_flag_after_name() {
	# Setup: Create ruleset and add to global mode
	mkdir -p "$HOME/.cursor/rules/ai-rizz"
	mkdir -p "$HOME/.cursor/commands/ai-rizz"
	
	# Initialize global mode
	cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
	cmd_add_ruleset "ruleset1" --global
	
	# Verify ruleset is in global manifest
	grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" || fail "Ruleset should be in global manifest after add"
	
	# Action: Remove with flag AFTER name (like: remove ruleset foo --global)
	output=$(cmd_remove_ruleset "ruleset1" --global 2>&1)
	exit_code=$?
	
	# Expected: Success, ruleset removed from global manifest
	assertEquals "Should exit with success code" 0 $exit_code
	
	# Verify ruleset was removed from global manifest
	if [ -f "$GLOBAL_MANIFEST_FILE" ]; then
		grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" && fail "Ruleset should be removed from global manifest"
	fi
	
	# BUG CHECK: --global should NOT be treated as a ruleset name
	# If flag parsing is broken, output will contain "Ruleset not found" warning for "--global"
	echo "$output" | grep -Eq "Ruleset not found.*--global|not found.*-g" && \
		fail "Flag --global should be parsed as mode flag, not treated as ruleset name. Output: $output"
	
	# Cleanup global mode
	rm -f "$GLOBAL_MANIFEST_FILE"
	rm -rf "$HOME/.cursor/rules/ai-rizz"
	rm -rf "$HOME/.cursor/commands/ai-rizz"
}

# Test that cmd_remove_ruleset parses --global flag before name
# Expected: Removes ruleset from global mode only
test_remove_ruleset_global_flag_before_name() {
	# Setup: Create ruleset and add to global mode
	mkdir -p "$HOME/.cursor/rules/ai-rizz"
	mkdir -p "$HOME/.cursor/commands/ai-rizz"
	
	# Initialize global mode
	cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
	cmd_add_ruleset "ruleset1" --global
	
	# Verify ruleset is in global manifest
	grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" || fail "Ruleset should be in global manifest after add"
	
	# Action: Remove with flag BEFORE name (like: remove ruleset --global foo)
	output=$(cmd_remove_ruleset --global "ruleset1" 2>&1)
	exit_code=$?
	
	# Expected: Success, ruleset removed from global manifest
	assertEquals "Should exit with success code" 0 $exit_code
	
	# Verify ruleset was removed from global manifest
	if [ -f "$GLOBAL_MANIFEST_FILE" ]; then
		grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" && fail "Ruleset should be removed from global manifest"
	fi
	
	# BUG CHECK: --global should NOT be treated as a ruleset name
	echo "$output" | grep -Eq "Ruleset not found.*--global|not found.*-g" && \
		fail "Flag --global should be parsed as mode flag, not treated as ruleset name. Output: $output"
	
	# Cleanup global mode
	rm -f "$GLOBAL_MANIFEST_FILE"
	rm -rf "$HOME/.cursor/rules/ai-rizz"
	rm -rf "$HOME/.cursor/commands/ai-rizz"
}

# Test that cmd_remove_ruleset parses -g short flag
# Expected: Removes ruleset from global mode only
test_remove_ruleset_global_short_flag() {
	# Setup: Create ruleset and add to global mode
	mkdir -p "$HOME/.cursor/rules/ai-rizz"
	mkdir -p "$HOME/.cursor/commands/ai-rizz"
	
	# Initialize global mode
	cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
	cmd_add_ruleset "ruleset1" --global
	
	# Verify ruleset is in global manifest
	grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" || fail "Ruleset should be in global manifest after add"
	
	# Action: Remove with short flag -g
	output=$(cmd_remove_ruleset -g "ruleset1" 2>&1)
	exit_code=$?
	
	# Expected: Success, ruleset removed from global manifest
	assertEquals "Should exit with success code" 0 $exit_code
	
	# Verify ruleset was removed from global manifest
	if [ -f "$GLOBAL_MANIFEST_FILE" ]; then
		grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" && fail "Ruleset should be removed from global manifest"
	fi
	
	# BUG CHECK: -g should NOT be treated as a ruleset name
	echo "$output" | grep -Eq "Ruleset not found.*-g" && \
		fail "Flag -g should be parsed as mode flag, not treated as ruleset name. Output: $output"
	
	# Cleanup global mode
	rm -f "$GLOBAL_MANIFEST_FILE"
	rm -rf "$HOME/.cursor/rules/ai-rizz"
	rm -rf "$HOME/.cursor/commands/ai-rizz"
}

# Test that --global mode-specific removal only removes from global mode
# Expected: Ruleset remains in local/commit mode when --global specified
test_remove_ruleset_global_flag_mode_specific() {
	# Setup: Add ruleset to both local and global modes
	mkdir -p "$HOME/.cursor/rules/ai-rizz"
	mkdir -p "$HOME/.cursor/commands/ai-rizz"
	
	# Initialize both modes
	cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
	cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
	
	# Add to both modes
	cmd_add_ruleset "ruleset1" --local
	cmd_add_ruleset "ruleset1" --global
	
	# Verify in both manifests
	grep -q "rulesets/ruleset1" "$LOCAL_MANIFEST_FILE" || fail "Ruleset should be in local manifest"
	grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" || fail "Ruleset should be in global manifest"
	
	# Action: Remove from global mode ONLY
	cmd_remove_ruleset "ruleset1" --global 2>&1
	
	# Expected: Removed from global, remains in local
	if [ -f "$GLOBAL_MANIFEST_FILE" ]; then
		grep -q "rulesets/ruleset1" "$GLOBAL_MANIFEST_FILE" && fail "Ruleset should be removed from global manifest"
	fi
	grep -q "rulesets/ruleset1" "$LOCAL_MANIFEST_FILE" || fail "Ruleset should REMAIN in local manifest"
	
	# Cleanup
	rm -f "$GLOBAL_MANIFEST_FILE"
	rm -rf "$HOME/.cursor/rules/ai-rizz"
	rm -rf "$HOME/.cursor/commands/ai-rizz"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

