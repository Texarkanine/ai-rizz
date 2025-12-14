#!/bin/sh
#
# test_ruleset_bug_fixes.test.sh - Regression tests for ruleset bug fixes
#
# Tests for 4 bugs in commands subdirectory implementation:
# 1. Subdirectory rules don't show up in mode list
# 2. Commands not copied recursively (only top-level)
# 3. List doesn't show tree for rulesets without commands
# 4. List doesn't show .mdc files in rulesets
#
# These tests are designed to FAIL with current implementation and PASS after fixes.
# Following TDD workflow: write failing tests first, then fix bugs.
#
# Test Coverage:
# - Recursive command copying (commands in subdirectories)
# - Subdirectory rules visible in list
# - Tree display for all rulesets (not just those with commands)
# - .mdc files visible in list output
# - Complex ruleset with all features
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_ruleset_bug_fixes.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# BUG 2: RECURSIVE COMMAND COPYING TESTS
# ============================================================================

# Test that commands in subdirectories are copied recursively
# Expected: Commands at any depth are copied, preserving directory structure
# Currently: FAILS - only top-level commands are copied
test_commands_copied_recursively() {
	# Setup: Create ruleset with nested commands structure
	mkdir -p "$REPO_DIR/rulesets/test-recursive/commands/subdir"
	echo "nested command content" > "$REPO_DIR/rulesets/test-recursive/commands/subdir/nested.md"
	echo "top command content" > "$REPO_DIR/rulesets/test-recursive/commands/top.md"
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
	
	# Expected: Both top-level and nested commands copied with directory structure
	test -f "commands/ai-rizz/test-recursive/top.md" || fail "Top-level command should be copied"
	test -f "commands/ai-rizz/test-recursive/subdir/nested.md" || fail "Nested command should be copied recursively"
	
	# Verify content matches
	assertEquals "Top command content should match" "top command content" "$(cat "commands/ai-rizz/test-recursive/top.md")"
	assertEquals "Nested command content should match" "nested command content" "$(cat "commands/ai-rizz/test-recursive/subdir/nested.md")"
}

# ============================================================================
# BUG 1: SUBDIRECTORY RULES VISIBLE IN LIST
# ============================================================================

# Test that rules in subdirectories are NOT visible in list output (subdir contents hidden)
# Expected: Top-level rules visible, subdirs shown but NOT their contents
# Per Phase 3: List display shows top-level only, subdir contents are NOT shown
test_subdirectory_rules_visible_in_list() {
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
	
	# Expected: Top-level rule visible, subdir shown but NOT its contents
	echo "$output" | grep -q "rootrule.mdc" || fail "Root rule should appear in list (top-level)"
	echo "$output" | grep -q "supporting" || fail "Supporting directory should appear in list (top-level subdir)"
	# Subdirectory contents should NOT appear (per Phase 3 requirements)
	if echo "$output" | grep -A 10 "test-subdir" | grep -A 5 "supporting" | grep -q "subrule.mdc"; then
		fail "Subdirectory rule should NOT appear in list (subdir contents are not shown)"
	fi
	
	# Verify rules were copied (they should be, issue is only display)
	# File rules in subdirectories preserve structure (per Bug 2 fix)
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root rule should be copied"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/subrule.mdc" || fail "Subdirectory rule should be copied (preserving structure)"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/subrule.mdc" || fail "Subdirectory rule should NOT be flattened"
}

# ============================================================================
# BUG 3: TREE SHOWS FOR ALL RULESETS
# ============================================================================

# Test that list shows tree structure for rulesets without commands or subdirectories
# Expected: All rulesets show tree with their .mdc files
# Currently: FAILS - rulesets with only .mdc files don't show tree
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
# BUG 4: .MDC FILES VISIBLE IN LIST
# ============================================================================

# Test that .mdc files are visible in list output
# Expected: .mdc files appear in tree, non-.mdc files are excluded
# Currently: FAILS - .mdc files not shown (ignore pattern excludes all files)
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
# COMBINED TEST - ALL BUGS
# ============================================================================

# Test complex ruleset with commands, subdirs, and .mdc files
# Expected: All components visible and commands copied recursively
# Currently: FAILS - Multiple issues (commands not recursive, .mdc files not shown)
test_complex_ruleset_display() {
	# Setup: Create ruleset matching temp-test structure
	mkdir -p "$REPO_DIR/rulesets/test-complex/commands/subs"
	mkdir -p "$REPO_DIR/rulesets/test-complex/supporting"
	echo "top command" > "$REPO_DIR/rulesets/test-complex/commands/top.md"
	echo "nested command" > "$REPO_DIR/rulesets/test-complex/commands/subs/nested.md"
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
	echo "$output" | grep -A 10 "test-complex" | grep -q "commands" || fail "commands/ should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "test-complex.mdc" || fail "Root .mdc should appear"
	echo "$output" | grep -A 10 "test-complex" | grep -q "supporting" || fail "supporting/ should appear (top-level subdir)"
	# Subdirectory contents should NOT appear (per Phase 3 requirements)
	if echo "$output" | grep -A 15 "test-complex" | grep -A 5 "supporting" | grep -q "subrule.mdc"; then
		fail "Subdirectory .mdc should NOT appear in list (subdir contents are not shown)"
	fi
	
	# Verify commands copied recursively
	test -f "commands/ai-rizz/test-complex/top.md" || fail "Top command should be copied"
	test -f "commands/ai-rizz/test-complex/subs/nested.md" || fail "Nested command should be copied recursively"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

