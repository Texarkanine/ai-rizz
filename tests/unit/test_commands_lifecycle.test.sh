#!/bin/sh
#
# test_commands_lifecycle.test.sh - Commands lifecycle and cleanup test suite
#
# Tests the namespaced commands lifecycle management, including:
# - Commands copied to namespaced directory
# - Orphaned commands cleaned up during sync
# - Commands namespace cleaned up during deinit
#
# Test Coverage:
# - Commands copied to commands/ai-rizz/<ruleset>/
# - Orphaned commands removed when ruleset removed from manifest
# - Commands namespace cleaned up on deinit
# - Sync cleans up orphaned commands
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_commands_lifecycle.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# NAMESPACED COMMANDS TESTS
# ============================================================================

# Test that commands are copied to namespaced directory
# Expected: Commands copied to commands/ai-rizz/<ruleset>/
test_commands_copied_to_namespaced_directory() {
	# Setup: Create ruleset with commands
	mkdir -p "$REPO_DIR/rulesets/test-namespace/commands"
	echo "command content" > "$REPO_DIR/rulesets/test-namespace/commands/test.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-namespace/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-namespace ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-namespace" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Commands copied to namespaced directory
	test -f "commands/ai-rizz/test-namespace/test.md" || fail "Command should be copied to namespaced directory"
	assertEquals "Command content should match" "command content" "$(cat "commands/ai-rizz/test-namespace/test.md")"
}

# Test that orphaned commands are cleaned up during sync
# Expected: Commands from rulesets not in manifest are removed
test_orphaned_commands_cleaned_up_during_sync() {
	# Setup: Create two rulesets with commands
	mkdir -p "$REPO_DIR/rulesets/test-sync1/commands"
	mkdir -p "$REPO_DIR/rulesets/test-sync2/commands"
	echo "sync1 content" > "$REPO_DIR/rulesets/test-sync1/commands/cmd1.md"
	echo "sync2 content" > "$REPO_DIR/rulesets/test-sync2/commands/cmd2.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-sync1/rule1.mdc"
	ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-sync2/rule2.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-sync rulesets" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Add both rulesets
	cmd_add_ruleset "test-sync1" --commit
	cmd_add_ruleset "test-sync2" --commit
	
	# Verify both commands exist
	test -f "commands/ai-rizz/test-sync1/cmd1.md" || fail "cmd1.md should exist"
	test -f "commands/ai-rizz/test-sync2/cmd2.md" || fail "cmd2.md should exist"
	
	# Action: Remove one ruleset from manifest (simulating manual edit or other removal path)
	cmd_remove_ruleset "test-sync1" --commit
	
	# Expected: test-sync1 commands should be removed
	test ! -f "commands/ai-rizz/test-sync1/cmd1.md" || fail "cmd1.md should be removed"
	test ! -d "commands/ai-rizz/test-sync1" || fail "test-sync1 directory should be removed"
	
	# Expected: test-sync2 commands should still exist
	test -f "commands/ai-rizz/test-sync2/cmd2.md" || fail "cmd2.md should still exist"
}

# Test that commands namespace is cleaned up on deinit
# Expected: commands/ai-rizz/ directory removed when commit mode is deinitialized
test_commands_namespace_cleaned_up_on_deinit() {
	# Setup: Create ruleset with commands
	mkdir -p "$REPO_DIR/rulesets/test-deinit/commands"
	echo "deinit content" > "$REPO_DIR/rulesets/test-deinit/commands/cmd.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-deinit/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-deinit ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Add ruleset
	cmd_add_ruleset "test-deinit" --commit
	
	# Verify commands exist
	test -f "commands/ai-rizz/test-deinit/cmd.md" || fail "cmd.md should exist"
	
	# Action: Deinit commit mode
	echo "y" | cmd_deinit --commit >/dev/null 2>&1
	
	# Expected: Commands namespace should be removed
	test ! -d "commands/ai-rizz" || fail "commands/ai-rizz/ directory should be removed"
	test ! -f "commands/ai-rizz/test-deinit/cmd.md" || fail "cmd.md should be removed"
}

# Test that user commands outside namespace are preserved
# Expected: User-created commands in commands/ are not touched
test_user_commands_preserved_outside_namespace() {
	# Setup: Create ruleset with commands
	mkdir -p "$REPO_DIR/rulesets/test-preserve/commands"
	echo "ruleset command" > "$REPO_DIR/rulesets/test-preserve/commands/ruleset-cmd.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-preserve/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-preserve ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Create user command outside namespace
	mkdir -p "commands"
	echo "user command" > "commands/user-cmd.md"
	
	# Add ruleset
	cmd_add_ruleset "test-preserve" --commit
	
	# Verify both commands exist
	test -f "commands/user-cmd.md" || fail "User command should exist"
	test -f "commands/ai-rizz/test-preserve/ruleset-cmd.md" || fail "Ruleset command should exist"
	
	# Action: Remove ruleset
	cmd_remove_ruleset "test-preserve" --commit
	
	# Expected: User command preserved, ruleset command removed
	test -f "commands/user-cmd.md" || fail "User command should be preserved"
	test ! -f "commands/ai-rizz/test-preserve/ruleset-cmd.md" || fail "Ruleset command should be removed"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

