#!/bin/sh
#
# test_ruleset_list_display.test.sh - Ruleset list output and flat command deploy
#
# Verifies cmd_list tree shape, flat deployment of ruleset .md commands to
# .cursor/commands/shared/, how subdirectory rules appear in list output versus
# on disk, and .mdc visibility in list output.
#
# Test coverage:
# - Commands sourced from nested paths under ruleset commands/ deploy flat into shared commands
# - List shows ruleset subtree: top-level rules and subdirectory names without listing children
# - Tree output for rulesets that have only .mdc rules (no commands subdirs)
# - Only .mdc files listed where applicable; complex ruleset exercising several behaviors together
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_ruleset_list_display.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# COMMANDS FLAT COPY
# ============================================================================

# Test that all .md commands in ruleset are copied FLAT (unified handling)
# Expected: All .md files copied to commands dir without preserving structure
test_commands_from_nested_dirs_copied_flat() {
	# Setup: Create ruleset with .md files in various locations
	mkdir -p "$REPO_DIR/rulesets/test-recursive/commands/subdir"
	echo "nested command content" > "$REPO_DIR/rulesets/test-recursive/commands/subdir/nested.md"
	echo "top command content" > "$REPO_DIR/rulesets/test-recursive/commands/top.md"
	echo "root command content" > "$REPO_DIR/rulesets/test-recursive/root-cmd.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-recursive/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-recursive ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-recursive" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: All .md files copied FLAT (unified handling - no directory structure)
	test -f ".cursor/commands/shared/top.md" || fail "Top-level command should be copied"
	test -f ".cursor/commands/shared/nested.md" || fail "Nested command should be copied (FLAT, not in subdir)"
	test -f ".cursor/commands/shared/root-cmd.md" || fail "Root command should be copied"
	
	# Verify content matches
	assertEquals "Top command content should match" "top command content" "$(cat ".cursor/commands/shared/top.md")"
	assertEquals "Nested command content should match" "nested command content" "$(cat ".cursor/commands/shared/nested.md")"
	assertEquals "Root command content should match" "root command content" "$(cat ".cursor/commands/shared/root-cmd.md")"
}

# ============================================================================
# RULESET TREE DISPLAY
# ============================================================================

# Test that subdirectory rule files are not enumerated in list (subdir appears; children hidden)
# Expected: Top-level rules visible; subdirs shown as entries but NOT their contents in list output
test_list_shows_subdirs_as_entries_but_hides_their_contents() {
	# Setup: Create ruleset with rules in subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-subdir/supporting"
	echo "subdir rule content" > "$REPO_DIR/rulesets/test-subdir/supporting/subrule.mdc"
	echo "root rule content" > "$REPO_DIR/rulesets/test-subdir/rootrule.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-subdir ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-subdir" --commit
	assertTrue "Should add ruleset successfully" $?
	
	output=$(cmd_list)
	
	# Expected: Top-level rule visible, subdir shown but NOT its contents in list
	echo "$output" | grep -q "rootrule.mdc" || fail "Root rule should appear in list (top-level)"
	echo "$output" | grep -q "supporting" || fail "Supporting directory should appear in list (top-level subdir)"
	# Subdirectory contents should NOT appear in list output (top-level-only listing under each ruleset)
	if echo "$output" | grep -A 10 "test-subdir" | grep -A 5 "supporting" | grep -q "subrule.mdc"; then
		fail "Subdirectory rule should NOT appear in list (subdir contents are not shown)"
	fi
	
	# Verify rules were deployed preserving subdirectory paths on disk (separate from list display)
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root rule should be copied"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/subrule.mdc" || fail "Subdirectory rule should be copied (preserving structure)"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/subrule.mdc" || fail "Subdirectory rule should NOT be flattened"
}

# Test that list shows tree structure for rulesets without commands or subdirectories
# Expected: All rulesets show tree with their .mdc files
test_list_shows_tree_for_all_rulesets() {
	# Setup: Create ruleset with only .mdc files (no commands, no subdirs)
	mkdir -p "$REPO_DIR/rulesets/test-simple"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-simple/rule1.mdc"
	ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-simple/rule2.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-simple ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-simple" --commit
	assertTrue "Should add ruleset successfully" $?
	
	output=$(cmd_list)
	
	# Expected: Ruleset shows tree with .mdc files
	echo "$output" | grep -A 5 "test-simple" | grep -q "rule1.mdc" || fail "rule1.mdc should appear in tree"
	echo "$output" | grep -A 5 "test-simple" | grep -q "rule2.mdc" || fail "rule2.mdc should appear in tree"
}

# ============================================================================
# .MDC FILE VISIBILITY
# ============================================================================

# Test that .mdc files are visible in list output
# Expected: .mdc files appear in tree, non-.mdc files are excluded
test_mdc_files_visible_in_list() {
	# Setup: Create ruleset with .mdc files and other files
	mkdir -p "$REPO_DIR/rulesets/test-mdc"
	echo "rule content" > "$REPO_DIR/rulesets/test-mdc/rule.mdc"
	echo "readme content" > "$REPO_DIR/rulesets/test-mdc/README.md"
	echo "config content" > "$REPO_DIR/rulesets/test-mdc/config.txt"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-mdc ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-mdc" --commit
	assertTrue "Should add ruleset successfully" $?
	
	output=$(cmd_list)
	
	# Expected: .mdc file visible, other files excluded
	echo "$output" | grep -A 5 "test-mdc" | grep -q "rule.mdc" || fail ".mdc file should appear in tree"
	if echo "$output" | grep -A 5 "test-mdc" | grep -q "README.md"; then
		fail "README.md should NOT appear (not .mdc file)"
	fi
	if echo "$output" | grep -A 5 "test-mdc" | grep -q "config.txt"; then
		fail "config.txt should NOT appear (not .mdc file)"
	fi
}

# ============================================================================
# COMPLEX RULESET (LIST OUTPUT AND FLAT COMMANDS)
# ============================================================================

# Test complex ruleset with commands, subdirs, and .mdc files
# Expected: Top-level list entries and commands copied FLAT
test_complex_ruleset_display() {
	# Setup: Create ruleset matching temp-test structure
	mkdir -p "$REPO_DIR/rulesets/test-complex/commands/subs"
	mkdir -p "$REPO_DIR/rulesets/test-complex/supporting"
	echo "top command" > "$REPO_DIR/rulesets/test-complex/commands/top.md"
	echo "nested command" > "$REPO_DIR/rulesets/test-complex/commands/subs/nested.md"
	echo "root command" > "$REPO_DIR/rulesets/test-complex/root-cmd.md"
	echo "root rule" > "$REPO_DIR/rulesets/test-complex/test-complex.mdc"
	echo "subrule" > "$REPO_DIR/rulesets/test-complex/supporting/subrule.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-complex ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize in commit mode
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-complex" --commit
	assertTrue "Should add ruleset successfully" $?
	
	output=$(cmd_list)
	
	# Expected: Top-level components visible, subdirs shown but NOT their contents
	echo "$output" | grep -A 10 "test-complex" | grep -q "commands" || fail ".cursor/commands/shared/ should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "test-complex.mdc" || fail "Root .mdc should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "supporting" || fail "supporting/ should appear (top-level subdir)"
	if echo "$output" | grep -A 15 "test-complex" | grep -A 5 "supporting" | grep -q "subrule.mdc"; then
		fail "Subdirectory .mdc should NOT appear in list (subdir contents are not shown)"
	fi
	
	# Verify commands copied FLAT (unified handling - no directory structure)
	test -f ".cursor/commands/shared/top.md" || fail "Top command should be copied"
	test -f ".cursor/commands/shared/nested.md" || fail "Nested command should be copied (FLAT)"
	test -f ".cursor/commands/shared/root-cmd.md" || fail "Root command should be copied"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

