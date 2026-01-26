#!/bin/sh
#
# test_symlink_security.test.sh - Symlink security validation test suite
#
# Tests security fixes for symlink vulnerabilities in copy_ruleset_commands()
# and copy_entry_to_target() functions. Verifies that symlinks pointing outside
# REPO_DIR are rejected and valid symlinks within the repository continue to work.
#
# Test Coverage:
# - Malicious symlink in commands directory pointing outside repo → rejected
# - Malicious symlink in ruleset pointing outside repo → rejected
# - Valid symlink within repo in commands → works normally
# - Valid symlink within repo in ruleset → works normally
# - Relative symlink within repo → works normally
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_symlink_security.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# SECURITY TESTS: copy_ruleset_commands()
# ============================================================================

# Test that malicious symlink in commands directory pointing outside repo is rejected
# Expected: Symlink skipped with warning, file not copied
test_commands_malicious_symlink_rejected() {
	# Setup: Create ruleset with commands/ containing symlink to /etc/passwd
	mkdir -p "$REPO_DIR/rulesets/test-malicious-commands"
	mkdir -p "$REPO_DIR/rulesets/test-malicious-commands/commands"
	
	# Create a test file that we'll symlink to (simulating /etc/passwd)
	mkdir -p "$TEST_DIR/outside-repo"
	echo "sensitive data" > "$TEST_DIR/outside-repo/sensitive.txt"
	
	# Create malicious symlink pointing outside REPO_DIR
	ln -sf "$TEST_DIR/outside-repo/sensitive.txt" "$REPO_DIR/rulesets/test-malicious-commands/commands/malicious.md"
	
	# Create valid rule symlink
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-malicious-commands/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-malicious-commands ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset in commit mode
	output=$(cmd_add_ruleset "test-malicious-commands" --commit 2>&1)
	exit_code=$?
	
	# Expected: Should succeed (other files copied), but malicious symlink skipped
	assertEquals "Should exit with success code" 0 $exit_code
	echo "$output" | grep -q "Skipping symlink pointing outside repository" || fail "Should show warning about skipping malicious symlink"
	
	# Verify malicious file was NOT copied
	# Commands now go to .cursor/commands/shared/ for commit mode
	commands_dir=".cursor/commands/shared"
	test ! -f "$commands_dir/malicious.md" || fail "Malicious symlink target should NOT be copied"
	
	# Verify sensitive data was NOT copied
	test ! -f "$commands_dir/sensitive.txt" || fail "Sensitive file should NOT be copied"
}

# Test that valid symlink within repo in commands directory works normally
# Expected: Symlink followed, content copied
test_commands_valid_symlink_works() {
	# Setup: Create ruleset with commands/ containing valid symlink within repo
	mkdir -p "$REPO_DIR/rulesets/test-valid-commands"
	mkdir -p "$REPO_DIR/rulesets/test-valid-commands/commands"
	
	# Create a file within repo to symlink to
	echo "valid content" > "$REPO_DIR/rulesets/test-valid-commands/commands/original.md"
	
	# Create valid symlink within repo
	ln -sf "original.md" "$REPO_DIR/rulesets/test-valid-commands/commands/valid-symlink.md"
	
	# Create valid rule symlink
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-valid-commands/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-valid-commands ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset in commit mode
	cmd_add_ruleset "test-valid-commands" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Valid symlink followed, content copied
	# Commands now go to .cursor/commands/shared/ for commit mode
	commands_dir=".cursor/commands/shared"
	test -f "$commands_dir/original.md" || fail "original.md should be copied"
	test -f "$commands_dir/valid-symlink.md" || fail "valid-symlink.md should be copied (as file, not symlink)"
	test ! -L "$commands_dir/valid-symlink.md" || fail "valid-symlink.md should be a file, not a symlink"
	assertEquals "valid-symlink.md content should match original" "valid content" "$(cat "$commands_dir/valid-symlink.md")"
}

# Test that relative symlink within repo in commands directory works normally
# Expected: Relative symlink resolved and followed, content copied
test_commands_relative_symlink_works() {
	# Setup: Create ruleset with .md symlink files
	mkdir -p "$REPO_DIR/rulesets/test-relative-commands"
	mkdir -p "$REPO_DIR/rulesets/test-relative-commands/commands"
	
	# Create a source .md file to symlink to
	echo "source command content" > "$REPO_DIR/rulesets/test-relative-commands/commands/source.md"
	
	# Create relative symlink to the .md file
	ln -sf "source.md" "$REPO_DIR/rulesets/test-relative-commands/commands/relative-symlink.md"
	
	# Also create a root-level command with relative symlink
	echo "root source content" > "$REPO_DIR/rulesets/test-relative-commands/root-source.md"
	ln -sf "root-source.md" "$REPO_DIR/rulesets/test-relative-commands/root-symlink.md"
	
	# Create valid rule symlink
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-relative-commands/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-relative-commands ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset in commit mode
	cmd_add_ruleset "test-relative-commands" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Relative symlinks resolved and followed, content copied (FLAT)
	# Commands now go to .cursor/commands/shared/ for commit mode
	commands_dir=".cursor/commands/shared"
	test -f "$commands_dir/source.md" || fail "source.md should be copied"
	test -f "$commands_dir/relative-symlink.md" || fail "relative-symlink.md should be copied"
	test -f "$commands_dir/root-source.md" || fail "root-source.md should be copied"
	test -f "$commands_dir/root-symlink.md" || fail "root-symlink.md should be copied"
	
	# Verify content matches
	assertEquals "relative-symlink.md content should match source" "source command content" "$(cat "$commands_dir/relative-symlink.md")"
	assertEquals "root-symlink.md content should match root-source" "root source content" "$(cat "$commands_dir/root-symlink.md")"
}

# ============================================================================
# SECURITY TESTS: copy_entry_to_target()
# ============================================================================

# Test that malicious symlink in ruleset pointing outside repo is rejected
# Expected: Symlink skipped with warning, file not copied
test_ruleset_malicious_symlink_rejected() {
	# Setup: Create ruleset with symlink pointing outside repo
	mkdir -p "$REPO_DIR/rulesets/test-malicious-ruleset"
	
	# Create a test file that we'll symlink to (simulating ~/.ssh/id_rsa)
	mkdir -p "$TEST_DIR/outside-repo"
	echo "private key data" > "$TEST_DIR/outside-repo/private-key.txt"
	
	# Create malicious symlink pointing outside REPO_DIR
	ln -sf "$TEST_DIR/outside-repo/private-key.txt" "$REPO_DIR/rulesets/test-malicious-ruleset/sensitive-data.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-malicious-ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in local mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Add ruleset in local mode
	output=$(cmd_add_ruleset "test-malicious-ruleset" --local 2>&1)
	exit_code=$?
	
	# Expected: Should succeed (other files copied), but malicious symlink skipped
	assertEquals "Should exit with success code" 0 $exit_code
	echo "$output" | grep -q "Skipping symlink pointing outside repository" || fail "Should show warning about skipping malicious symlink"
	
	# Verify malicious file was NOT copied
	test ! -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/sensitive-data.mdc" || fail "Malicious symlink target should NOT be copied"
	
	# Verify sensitive data was NOT copied
	test ! -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/private-key.txt" || fail "Sensitive file should NOT be copied"
}

# Test that valid symlink within repo in ruleset works normally
# Expected: Symlink followed, content copied
test_ruleset_valid_symlink_works() {
	# Setup: Create ruleset with valid symlink within repo
	mkdir -p "$REPO_DIR/rulesets/test-valid-ruleset"
	
	# Create valid symlink within repo
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-valid-ruleset/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-valid-ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in local mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Add ruleset in local mode
	cmd_add_ruleset "test-valid-ruleset" --local
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Valid symlink followed, content copied
	test -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc" || fail "rule1.mdc should be copied"
	test ! -L "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc" || fail "rule1.mdc should be a file, not a symlink"
	assertEquals "rule1.mdc content should match" "Rule 1 content" "$(cat "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc")"
}

# Test that relative symlink within repo in ruleset works normally
# Expected: Relative symlink resolved and followed, content copied
test_ruleset_relative_symlink_works() {
	# Setup: Create ruleset with relative symlink within repo (rule2.mdc already exists from setUp)
	mkdir -p "$REPO_DIR/rulesets/test-relative-ruleset"
	
	# Create relative symlink within repo
	# From rulesets/test-relative-ruleset/, need ../../rules/rule2.mdc to reach rules/
	ln -sf "../../rules/rule2.mdc" "$REPO_DIR/rulesets/test-relative-ruleset/rule2.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-relative-ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in local mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Add ruleset in local mode
	cmd_add_ruleset "test-relative-ruleset" --local
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Relative symlink resolved and followed, content copied
	test -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc" || fail "rule2.mdc should be copied"
	test ! -L "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc" || fail "rule2.mdc should be a file, not a symlink"
	assertEquals "rule2.mdc content should match" "Rule 2 content" "$(cat "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule2.mdc")"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

