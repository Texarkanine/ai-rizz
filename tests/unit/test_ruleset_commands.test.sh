#!/bin/sh
#
# test_ruleset_commands.test.sh - Ruleset commands test suite
#
# Tests all operations related to commands in rulesets, including .md files
# in ruleset root being treated as commands, uppercase .md files being ignored,
# and proper migration from old directory structures.
#
# Test Coverage:
# - .md files in ruleset root → treated as commands (unified handling)
# - Uppercase .md files (README.md) → ignored (documentation, not commands)
# - commands/ subdir still works (backwards compatible)
# - Ruleset with commands works in all modes (local, commit, global)
# - Commands copied flat (no directory structure preserved)
# - Symlink handling in commands
# - Migration: old flat command dirs cleaned up
# - Migration: old flat standalone commands cleaned up
# - Migration: user-created commands NOT touched
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_ruleset_commands.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# UNIFIED COMMAND HANDLING TESTS (.md files in ruleset root)
# ============================================================================

# Test that .md files in ruleset root are treated as commands
# Expected: foo.md in ruleset root → copied to commands directory
test_md_files_in_ruleset_root_treated_as_commands() {
	# Setup: Create ruleset with .md file in root
	mkdir -p "$REPO_DIR/rulesets/test-root-md"
	echo "rule content" > "$REPO_DIR/rulesets/test-root-md/test-rule.mdc"
	echo "command in root" > "$REPO_DIR/rulesets/test-root-md/my-command.md"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with .md in root" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-root-md" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: .md file copied to commands directory (flat, not in subdirectory)
	commands_dir=".cursor/commands/shared"
	test -d "$commands_dir" || fail "Commands directory should be created"
	test -f "$commands_dir/my-command.md" || fail "my-command.md should be copied to commands dir"
	assertEquals "Command content should match" "command in root" "$(cat "$commands_dir/my-command.md")"
	
	# Expected: .mdc file copied to rules directory
	test -f "$TEST_TARGET_DIR/shared/test-rule.mdc" || fail "test-rule.mdc should be copied to rules dir"
}

# Test that uppercase .md files (README.md, CHANGELOG.md) are ignored
# Expected: README.md in ruleset root → NOT copied (it's documentation)
test_uppercase_md_files_ignored() {
	# Setup: Create ruleset with uppercase .md files
	mkdir -p "$REPO_DIR/rulesets/test-uppercase-md"
	echo "rule content" > "$REPO_DIR/rulesets/test-uppercase-md/test-rule.mdc"
	echo "readme content" > "$REPO_DIR/rulesets/test-uppercase-md/README.md"
	echo "changelog content" > "$REPO_DIR/rulesets/test-uppercase-md/CHANGELOG.md"
	echo "contributing content" > "$REPO_DIR/rulesets/test-uppercase-md/CONTRIBUTING.md"
	echo "license content" > "$REPO_DIR/rulesets/test-uppercase-md/LICENSE.md"
	echo "lowercase command" > "$REPO_DIR/rulesets/test-uppercase-md/my-command.md"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with uppercase .md files" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-uppercase-md" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Uppercase .md files NOT copied
	commands_dir=".cursor/commands/shared"
	test ! -f "$commands_dir/README.md" || fail "README.md should NOT be copied"
	test ! -f "$commands_dir/CHANGELOG.md" || fail "CHANGELOG.md should NOT be copied"
	test ! -f "$commands_dir/CONTRIBUTING.md" || fail "CONTRIBUTING.md should NOT be copied"
	test ! -f "$commands_dir/LICENSE.md" || fail "LICENSE.md should NOT be copied"
	
	# Expected: Lowercase .md files ARE copied
	test -f "$commands_dir/my-command.md" || fail "my-command.md SHOULD be copied"
}

# Test that multiple .md files in ruleset root are all copied flat
# Expected: All .md files copied to commands dir root (not preserving subdirs)
test_multiple_md_files_copied_flat() {
	# Setup: Create ruleset with nested .md files
	mkdir -p "$REPO_DIR/rulesets/test-nested-md"
	mkdir -p "$REPO_DIR/rulesets/test-nested-md/subdir"
	echo "rule content" > "$REPO_DIR/rulesets/test-nested-md/test-rule.mdc"
	echo "root command" > "$REPO_DIR/rulesets/test-nested-md/root-cmd.md"
	echo "nested command" > "$REPO_DIR/rulesets/test-nested-md/subdir/nested-cmd.md"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with nested .md files" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-nested-md" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Both .md files copied flat to commands dir
	commands_dir=".cursor/commands/shared"
	test -f "$commands_dir/root-cmd.md" || fail "root-cmd.md should be copied"
	test -f "$commands_dir/nested-cmd.md" || fail "nested-cmd.md should be copied (flat, not in subdir)"
	
	# Expected: NOT in a nested structure
	test ! -d "$commands_dir/subdir" || fail "subdir should NOT be created in commands dir"
}

# Test that commands/ subdir still works (backwards compatible)
# Expected: .md files in commands/ subdir are also copied
test_commands_subdir_still_works() {
	# Setup: Create ruleset with both root .md and commands/ subdir
	mkdir -p "$REPO_DIR/rulesets/test-both-locations"
	mkdir -p "$REPO_DIR/rulesets/test-both-locations/commands"
	echo "rule content" > "$REPO_DIR/rulesets/test-both-locations/test-rule.mdc"
	echo "root command" > "$REPO_DIR/rulesets/test-both-locations/root-cmd.md"
	echo "subdir command" > "$REPO_DIR/rulesets/test-both-locations/commands/subdir-cmd.md"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with both locations" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-both-locations" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Both .md files copied
	commands_dir=".cursor/commands/shared"
	test -f "$commands_dir/root-cmd.md" || fail "root-cmd.md should be copied"
	test -f "$commands_dir/subdir-cmd.md" || fail "subdir-cmd.md should be copied (from commands/ subdir)"
}

# ============================================================================
# MIGRATION TESTS
# ============================================================================

# Test that sync cleans up old flat command directories inside mode subdirs
# Scenario: .cursor/commands/shared/niko/ → should be cleaned up to flat structure
test_sync_cleans_old_ruleset_command_subdirs() {
	# Setup: Initialize and add a ruleset
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	cmd_add_ruleset "ruleset1" --commit
	
	# Simulate old directory structure (as if from old ai-rizz)
	# Create a ruleset subdir inside the mode's commands directory
	mkdir -p ".cursor/commands/shared/ruleset1"
	echo "old command" > ".cursor/commands/shared/ruleset1/old-cmd.md"
	
	# Action: Sync - should clean up the old structure
	cmd_sync
	
	# Expected: Empty directories cleaned up after sync
	# Note: The .md file will be deleted by the general find -delete,
	# and empty dirs should be cleaned up
	test ! -d ".cursor/commands/shared/ruleset1" || fail "Old ruleset1/ subdir should be cleaned up"
}

# Test that sync cleans up old flat standalone commands at root
# Scenario: .cursor/commands/foo.md (old flat) → should be cleaned up
test_sync_cleans_old_flat_standalone_commands() {
	# Setup: Create a command and add it
	mkdir -p "$REPO_DIR/rules"
	echo "standalone command" > "$REPO_DIR/rules/standalone-cmd.md"
	
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add standalone command" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize and add the command
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	cmd_add_rule "standalone-cmd" --commit
	
	# Simulate old flat structure at .cursor/commands/ root
	echo "old standalone" > ".cursor/commands/standalone-cmd.md"
	
	# Action: Sync
	cmd_sync
	
	# Expected: Old flat command at root cleaned up
	test ! -f ".cursor/commands/standalone-cmd.md" || fail "Old flat standalone-cmd.md at root should be cleaned up"
	
	# Expected: Command still exists in mode subdir
	test -f ".cursor/commands/shared/standalone-cmd.md" || fail "standalone-cmd.md should exist in shared/"
}

# Test that user-created commands at root are NOT touched
# Scenario: .cursor/commands/my-personal.md (user-created) → should NOT be deleted
test_sync_preserves_user_created_commands() {
	# Setup: Initialize
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Create user-owned command at root (not managed by ai-rizz)
	mkdir -p ".cursor/commands"
	echo "user command" > ".cursor/commands/user-personal.md"
	
	# Action: Sync
	cmd_sync
	
	# Expected: User command NOT deleted (it's not in any manifest)
	test -f ".cursor/commands/user-personal.md" || fail "User-created user-personal.md should NOT be deleted"
	assertEquals "User command content should be unchanged" "user command" "$(cat ".cursor/commands/user-personal.md")"
}

# Test that user-created directories at root are NOT touched
# Scenario: .cursor/commands/my-custom-dir/ (user-created) → should NOT be deleted
test_sync_preserves_user_created_directories() {
	# Setup: Initialize
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Create user-owned directory at root (not managed by ai-rizz)
	mkdir -p ".cursor/commands/my-custom-dir"
	echo "user nested command" > ".cursor/commands/my-custom-dir/nested.md"
	
	# Action: Sync
	cmd_sync
	
	# Expected: User directory NOT deleted (it's not in any manifest)
	test -d ".cursor/commands/my-custom-dir" || fail "User-created my-custom-dir/ should NOT be deleted"
	test -f ".cursor/commands/my-custom-dir/nested.md" || fail "User command in custom dir should NOT be deleted"
}

# Test that flat .md files from old commands/ structure are cleaned up
# Scenario: Old ai-rizz copied rulesets/niko/commands/niko.md to .cursor/commands/niko.md (flat)
# New ai-rizz should clean this up and place in .cursor/commands/shared/niko.md
test_sync_cleans_old_flat_commands_from_ruleset() {
	# Setup: Create ruleset with commands/ subdirectory (old structure)
	mkdir -p "$REPO_DIR/rulesets/test-old-flat/commands"
	echo "main command" > "$REPO_DIR/rulesets/test-old-flat/commands/main-cmd.md"
	echo "rule content" > "$REPO_DIR/rulesets/test-old-flat/test-rule.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-old-flat ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize and add ruleset
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	cmd_add_ruleset "test-old-flat" --commit
	
	# Simulate old flat structure - old ai-rizz would have copied to .cursor/commands/main-cmd.md
	echo "old flat copy" > ".cursor/commands/main-cmd.md"
	
	# Action: Sync
	cmd_sync
	
	# Expected: Old flat file cleaned up
	test ! -f ".cursor/commands/main-cmd.md" || fail "Old flat main-cmd.md at root should be cleaned up"
	
	# Expected: New file in mode subdir
	test -f ".cursor/commands/shared/main-cmd.md" || fail "main-cmd.md should exist in shared/"
}

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

# Test that .md commands are copied to the correct location (.cursor/commands/)
# Expected: Only .md files from rulesets are present in .cursor/commands/ (unified handling)
test_commands_copied_to_correct_location() {
	# Setup: Create ruleset with various files
	mkdir -p "$REPO_DIR/rulesets/test-commands"
	mkdir -p "$REPO_DIR/rulesets/test-commands/commands"
	echo "file1 content" > "$REPO_DIR/rulesets/test-commands/commands/file1.md"
	echo "file2 content" > "$REPO_DIR/rulesets/test-commands/commands/file2.txt"  # NOT copied (not .md)
	echo "file3 content" > "$REPO_DIR/rulesets/test-commands/commands/file3.sh"   # NOT copied (not .md)
	echo "root cmd content" > "$REPO_DIR/rulesets/test-commands/root-cmd.md"
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
	
	# Action: Verify .md files in commands/ (relative to TARGET_DIR parent)
	commands_dir=".cursor/commands/shared"
	test -d "$commands_dir" || fail "Commands directory should exist"
	test -f "$commands_dir/file1.md" || fail "file1.md should be copied"
	test -f "$commands_dir/root-cmd.md" || fail "root-cmd.md should be copied"
	
	# Non-.md files should NOT be copied (unified .md handling)
	test ! -f "$commands_dir/file2.txt" || fail "file2.txt should NOT be copied (not .md)"
	test ! -f "$commands_dir/file3.sh" || fail "file3.sh should NOT be copied (not .md)"
	
	# Verify content matches
	assertEquals "file1.md content should match" "file1 content" "$(cat "$commands_dir/file1.md")"
	assertEquals "root-cmd.md content should match" "root cmd content" "$(cat "$commands_dir/root-cmd.md")"
}

# Test that symlinks in ruleset are followed correctly
# Expected: Actual source content is copied, not the symlink itself
test_commands_symlinks_followed_correctly() {
	# Setup: Create ruleset with symlinked .md files
	mkdir -p "$REPO_DIR/rulesets/test-symlinks"
	mkdir -p "$REPO_DIR/rulesets/test-symlinks/commands"
	echo "original content" > "$REPO_DIR/rulesets/test-symlinks/commands/original.md"
	ln -sf "original.md" "$REPO_DIR/rulesets/test-symlinks/commands/symlink.md"
	# Also test symlink at ruleset root
	echo "root original" > "$REPO_DIR/rulesets/test-symlinks/root-original.md"
	ln -sf "root-original.md" "$REPO_DIR/rulesets/test-symlinks/root-symlink.md"
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
	
	# Verify root-level symlink was also followed
	test -f "$commands_dir/root-original.md" || fail "root-original.md should be copied"
	test -f "$commands_dir/root-symlink.md" || fail "root-symlink.md should be copied"
	assertEquals "root-symlink.md content should match original" "root original" "$(cat "$commands_dir/root-symlink.md")"
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

