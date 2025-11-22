#!/bin/sh
# Test suite for command management operations
# Tests: add cmd, add cmdset, remove cmd, remove cmdset

set -eu

# Calculate AI_RIZZ_PATH once at script startup
_TEST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_RIZZ_PATH="${_TEST_SCRIPT_DIR}/../../ai-rizz"
export AI_RIZZ_PATH

# Load common test utilities
# shellcheck disable=SC1091
. "${_TEST_SCRIPT_DIR}/../common.sh"

# setUp - runs before each test
setUp() {
	# Create a temporary test directory
	TEST_DIR="$(mktemp -d)"
	cd "$TEST_DIR" || fail "Failed to change to test directory"
	
	# Initialize variables before sourcing
	MANIFEST_FILE=""
	SOURCE_REPO=""
	TARGET_DIR=""
	REPO_DIR=""
	
	# Source ai-rizz for testing
	source_ai_rizz
	
	# Reset ai-rizz state
	reset_ai_rizz_state
	
	# Setup test repository
	REPO_DIR=$(get_repo_dir)
	mkdir -p "$REPO_DIR"
	
	# Create repository structure with commands and commandsets
	mkdir -p "$REPO_DIR/commands"
	mkdir -p "$REPO_DIR/commandsets/workflows"
	
	# Create individual commands
	echo "# Review Code Command" > "$REPO_DIR/commands/review-code.md"
	echo "# Create PR Command" > "$REPO_DIR/commands/create-pr.md"
	echo "# Test Command" > "$REPO_DIR/commands/test-cmd.md"
	echo "# Security Audit" > "$REPO_DIR/commands/security-audit.md"
	
	# Create commandset with symlinks (like rulesets)
	ln -s "../../commands/review-code.md" "$REPO_DIR/commandsets/workflows/review-code.md"
	ln -s "../../commands/test-cmd.md" "$REPO_DIR/commandsets/workflows/test-cmd.md"
	
	# Initialize git repo
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git init . >/dev/null 2>&1
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	
	# Add and commit commands
	git add commands/ commandsets/ >/dev/null 2>&1
	git commit -m "Add commands" --no-gpg-sign >/dev/null 2>&1
	
	# Return to test directory
	cd "$TEST_DIR" || fail "Failed to change back to test directory"
	
	# Initialize ai-rizz in commit mode
	# Create commit manifest
	echo "file://$REPO_DIR	.cursor/rules	rules	rulesets	commands	commandsets" > "ai-rizz.skbd"
	
	# Set global variables (simulating initialization)
	SOURCE_REPO="file://$REPO_DIR"
	TARGET_DIR=".cursor/rules"
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	COMMANDS_PATH="commands"
	COMMANDSETS_PATH="commandsets"
	COMMIT_MANIFEST_FILE="ai-rizz.skbd"
	SHARED_COMMANDS_DIR="shared-commands"
}

# tearDown - runs after each test
tearDown() {
	# Clean up test directory
	if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
		cd /
		rm -rf "$TEST_DIR"
	fi
}

#######################################
# Test: Add single command
#
# Verifies that adding a single command:
# - Adds entry to manifest
# - Deploys file to shared-commands/
# - Creates symlink in commands/
#######################################
test_add_single_command() {
	# Add single command
	cmd_add_cmd "review-code.md"
	
	# Verify added to manifest
	assert_manifest_contains "ai-rizz.skbd" "commands/review-code.md"
	
	# Verify deployed to shared-commands
	assert_file_exists ".cursor/shared-commands/review-code.md"
	
	# Verify symlink created
	assertTrue "Symlink should exist" "[ -L .cursor/commands/review-code.md ]"
	
	# Verify symlink target
	link_target=$(readlink .cursor/commands/review-code.md)
	assertEquals "Symlink target" "../shared-commands/review-code.md" "$link_target"
}

#######################################
# Test: Add multiple commands
#
# Verifies that multiple commands can be added in one operation
#######################################
test_add_multiple_commands() {
	# Add multiple commands
	cmd_add_cmd "review-code.md" "create-pr.md" "test-cmd.md"
	
	# Verify all added to manifest
	assert_manifest_contains "ai-rizz.skbd" "commands/review-code.md"
	assert_manifest_contains "ai-rizz.skbd" "commands/create-pr.md"
	assert_manifest_contains "ai-rizz.skbd" "commands/test-cmd.md"
	
	# Verify all deployed
	assert_file_exists ".cursor/shared-commands/review-code.md"
	assert_file_exists ".cursor/shared-commands/create-pr.md"
	assert_file_exists ".cursor/shared-commands/test-cmd.md"
	
	# Verify all symlinks created
	assertTrue "review-code symlink should exist" "[ -L .cursor/commands/review-code.md ]"
	assertTrue "create-pr symlink should exist" "[ -L .cursor/commands/create-pr.md ]"
	assertTrue "test-cmd symlink should exist" "[ -L .cursor/commands/test-cmd.md ]"
}

#######################################
# Test: Add command with .md extension
#
# Verifies that commands with .md extension are handled correctly
#######################################
test_add_command_with_extension() {
	# Add command with extension
	cmd_add_cmd "security-audit.md"
	
	# Verify added to manifest
	assert_manifest_contains "ai-rizz.skbd" "commands/security-audit.md"
	
	# Verify deployed
	assert_file_exists ".cursor/shared-commands/security-audit.md"
	
	# Verify symlink
	assertTrue "Symlink should exist" "[ -L .cursor/commands/security-audit.md ]"
}

#######################################
# Test: Add command without .md extension
#
# Verifies that .md extension is automatically added when missing
#######################################
test_add_command_without_extension() {
	# Add command without extension
	cmd_add_cmd "security-audit"
	
	# Verify added to manifest with extension
	assert_manifest_contains "ai-rizz.skbd" "commands/security-audit.md"
	
	# Verify deployed with extension
	assert_file_exists ".cursor/shared-commands/security-audit.md"
	
	# Verify symlink created with extension
	assertTrue "Symlink should exist" "[ -L .cursor/commands/security-audit.md ]"
}

#######################################
# Test: Add commandset
#
# Verifies that commandsets deploy all contained commands
#######################################
test_add_commandset() {
	# Add commandset
	cmd_add_cmdset "workflows"
	
	# Verify commandset added to manifest
	assert_manifest_contains "ai-rizz.skbd" "commandsets/workflows"
	
	# Verify all commands from commandset deployed
	# workflows contains: review-code.md, test-cmd.md
	assert_file_exists ".cursor/shared-commands/review-code.md"
	assert_file_exists ".cursor/shared-commands/test-cmd.md"
	
	# Verify symlinks
	assertTrue "review-code symlink should exist" "[ -L .cursor/commands/review-code.md ]"
	assertTrue "test-cmd symlink should exist" "[ -L .cursor/commands/test-cmd.md ]"
}

#######################################
# Test: Remove command
#
# Verifies that removing a command:
# - Removes entry from manifest
# - Removes file from shared-commands/
# - Removes symlink from commands/
#######################################
test_remove_command() {
	# Setup: Add a command first
	cmd_add_cmd "review-code.md"
	
	# Verify it's there
	assert_manifest_contains "ai-rizz.skbd" "commands/review-code.md"
	assert_file_exists ".cursor/shared-commands/review-code.md"
	
	# Remove the command
	cmd_remove_cmd "review-code.md"
	
	# Verify removed from manifest
	assert_manifest_not_contains "ai-rizz.skbd" "commands/review-code.md"
	
	# Verify files removed
	assertFalse "File should not exist" "[ -f .cursor/shared-commands/review-code.md ]"
	assertFalse "Symlink should not exist" "[ -L .cursor/commands/review-code.md ]"
}

#######################################
# Test: Remove commandset
#
# Verifies that commandsets can be removed
#######################################
test_remove_commandset() {
	# Setup: Add commandset first
	cmd_add_cmdset "workflows"
	
	# Verify it's there
	assert_manifest_contains "ai-rizz.skbd" "commandsets/workflows"
	assert_file_exists ".cursor/shared-commands/review-code.md"
	
	# Remove the commandset
	cmd_remove_cmdset "workflows"
	
	# Verify removed from manifest
	assert_manifest_not_contains "ai-rizz.skbd" "commandsets/workflows"
	
	# Verify files removed (assuming no other commands reference them)
	assertFalse "review-code should not exist" "[ -f .cursor/shared-commands/review-code.md ]"
	assertFalse "test-cmd should not exist" "[ -f .cursor/shared-commands/test-cmd.md ]"
}

#######################################
# Test: Reject --local flag for commands
#
# Verifies that commands do not support --local mode
# and provide helpful error message
#######################################
test_reject_local_flag() {
	# Try to add command with --local flag
	# Capture output and exit code properly
	set +e
	output=$(cmd_add_cmd "review-code.md" "--local" 2>&1)
	exit_code=$?
	set -e
	
	# Should fail
	assertNotEquals "Should fail" 0 "$exit_code"
	
	# Error message should mention --local not supported
	echo "$output" | grep -q "do not support --local"
	assertTrue "Should mention --local not supported" $?
	
	# Error message should mention ~/.cursor/commands/
	echo "$output" | grep -q "~/.cursor/commands"
	assertTrue "Should mention global commands directory" $?
	
	# Verify nothing was added
	assert_manifest_not_contains "ai-rizz.skbd" "commands/review-code.md"
}

#######################################
# Test: Accept --commit flag for commands
#
# Verifies that --commit flag is accepted (even though redundant)
#######################################
test_accept_commit_flag() {
	# Add command with --commit flag
	cmd_add_cmd "review-code.md" "--commit"
	
	# Should succeed and add to manifest
	assert_manifest_contains "ai-rizz.skbd" "commands/review-code.md"
	
	# Should be deployed
	assert_file_exists ".cursor/shared-commands/review-code.md"
	assertTrue "Symlink should exist" "[ -L .cursor/commands/review-code.md ]"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
