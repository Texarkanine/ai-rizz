#!/bin/sh
#
# test_ruleset_removal_and_structure.test.sh - Ruleset removal and structure preservation test suite
#
# Tests for two bug fixes:
# 1. Commands not removed when ruleset is removed
# 2. File rules in subdirectories are flattened instead of preserving directory structure
#
# Test Coverage:
# - Commands removed when ruleset removed
# - File rules in subdirectories preserve structure
# - Symlinked rules in subdirectories copied flat
# - Commands removed even with conflicting paths (error condition)
# - Complex ruleset with commands, file rules, and symlinked rules
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_ruleset_removal_and_structure.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# BUG 1: COMMANDS NOT REMOVED WHEN RULESET REMOVED
# ============================================================================

# Test that commands are removed when ruleset is removed
# Expected: Commands should be removed from .cursor/commands/ when their ruleset is removed
test_commands_removed_when_ruleset_removed() {
	# Setup: Create ruleset with commands (including nested commands)
	mkdir -p "$REPO_DIR/rulesets/test-remove-cmd/commands/subdir"
	echo "command1" > "$REPO_DIR/rulesets/test-remove-cmd/commands/cmd1.md"
	echo "nested" > "$REPO_DIR/rulesets/test-remove-cmd/commands/subdir/nested.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-remove-cmd/rule1.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset, then remove it
	cmd_add_ruleset "test-remove-cmd" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Verify commands copied (namespaced)
	test -f "commands/ai-rizz/test-remove-cmd/cmd1.md" || fail "cmd1.md should be copied"
	test -f "commands/ai-rizz/test-remove-cmd/subdir/nested.md" || fail "Nested command should be copied"
	
	# Remove ruleset
	cmd_remove_ruleset "test-remove-cmd"
	assertTrue "Should remove ruleset successfully" $?
	
	# Expected: Commands should be removed
	test ! -f "commands/ai-rizz/test-remove-cmd/cmd1.md" || fail "cmd1.md should be removed"
	test ! -f "commands/ai-rizz/test-remove-cmd/subdir/nested.md" || fail "Nested command should be removed"
	# CURRENTLY FAILS: Commands remain after ruleset removal
}

# Test that commands are removed even if multiple rulesets have same path (error condition)
# Expected: Command removed when its ruleset is removed, even if another ruleset has same path
test_commands_removed_even_with_conflicts() {
	# Setup: Create two rulesets with same command path (error condition, but we handle it)
	mkdir -p "$REPO_DIR/rulesets/test-cmd1/commands"
	mkdir -p "$REPO_DIR/rulesets/test-cmd2/commands"
	echo "cmd1 content" > "$REPO_DIR/rulesets/test-cmd1/commands/shared.md"
	echo "cmd2 content" > "$REPO_DIR/rulesets/test-cmd2/commands/shared.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-cmd1/rule1.mdc"
	ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-cmd2/rule2.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add both rulesets (last one wins for the file)
	cmd_add_ruleset "test-cmd1" --commit
	cmd_add_ruleset "test-cmd2" --commit
	
	# Verify command exists (last one wins)
	test -f "commands/ai-rizz/test-cmd2/shared.md" || fail "shared.md should exist"
	assertEquals "Content should be from last ruleset" "cmd2 content" "$(cat commands/ai-rizz/test-cmd2/shared.md)"
	
	# Remove first ruleset
	cmd_remove_ruleset "test-cmd1"
	
	# Expected: Command file was removed, but sync restores it from test-cmd2
	# Note: This is an error condition - rulesets shouldn't have overlapping command paths
	# When test-cmd1 is removed, shared.md is deleted, but sync restores it from test-cmd2
	# So the file will exist after sync (from test-cmd2)
	test -f "commands/ai-rizz/test-cmd2/shared.md" || fail "shared.md should exist (restored from test-cmd2 by sync)"
	assertEquals "Content should be from test-cmd2" "cmd2 content" "$(cat commands/ai-rizz/test-cmd2/shared.md)"
	
	# Remove second ruleset
	cmd_remove_ruleset "test-cmd2"
	
	# Expected: Command should now be removed (both rulesets removed)
	test ! -f "commands/ai-rizz/test-cmd1/shared.md" || fail "shared.md from test-cmd1 should be removed"
	test ! -f "commands/ai-rizz/test-cmd2/shared.md" || fail "shared.md from test-cmd2 should be removed"
}

# ============================================================================
# BUG 2: FILE RULES IN SUBDIRECTORIES FLATTENED
# ============================================================================

# Test that file rules in subdirectories preserve directory structure
# Expected: File rules in subdirectories should preserve structure (e.g., Core/memory-bank-paths.mdc)
test_file_rules_in_subdirectories_preserve_structure() {
	# Setup: Create ruleset with file rule in subdirectory (should preserve structure)
	mkdir -p "$REPO_DIR/rulesets/test-structure/supporting"
	echo "subdir rule" > "$REPO_DIR/rulesets/test-structure/supporting/subrule.mdc"
	echo "root rule" > "$REPO_DIR/rulesets/test-structure/rootrule.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset (should succeed)
	cmd_add_ruleset "test-structure" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: File rules preserve directory structure
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root rule should be copied"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/subrule.mdc" || fail "Subdirectory file rule should preserve structure"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/subrule.mdc" || fail "Subdirectory file rule should NOT be flattened"
	# CURRENTLY FAILS: Rules are flattened to root level
}

# Test that symlinked rules in subdirectories are copied flat
# Expected: Symlinked rules should be copied flat (all instances are the same rule)
test_symlinked_rules_in_subdirectories_copied_flat() {
	# Setup: Create ruleset with symlinked rule in subdirectory (should be copied flat)
	mkdir -p "$REPO_DIR/rulesets/test-symlink/supporting"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-symlink/supporting/rule1.mdc"
	ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/test-symlink/rule2.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset (should succeed)
	cmd_add_ruleset "test-symlink" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Symlinked rules copied flat (all instances are the same rule)
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc" || fail "rule1.mdc should be copied (flat)"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule2.mdc" || fail "rule2.mdc should be copied (flat)"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/supporting/rule1.mdc" || fail "Symlinked rules should NOT preserve structure"
	
	# Expected: List shows top-level .mdc files and top-level subdirs (but NOT subdir contents)
	# List display rules:
	# - All top-level .mdc files are shown
	# - All top-level subdirs are shown (but NONE of their children are shown)
	# - "commands" subdir gets special treatment (one level shown)
	output=$(cmd_list)
	# rule2.mdc is at top level - should appear
	echo "$output" | grep -A 10 "test-symlink" | grep -q "rule2.mdc" || fail "rule2.mdc should appear in list (top-level)"
	# supporting/ is a top-level subdir - should appear as directory name only
	echo "$output" | grep -A 10 "test-symlink" | grep -q "supporting" || fail "supporting/ directory should appear in list"
	# rule1.mdc is in supporting/ subdirectory - should NOT appear (subdir contents not shown)
	if echo "$output" | grep -A 15 "test-symlink" | grep -A 5 "supporting" | grep -q "rule1.mdc"; then
		fail "rule1.mdc should NOT appear under supporting/ in list (subdir contents are not shown)"
	fi
	# rule1.mdc should also NOT appear at top level in list (it's in a subdir in source, even though deployed flat)
	# Note: rule1.mdc is deployed flat, but list shows SOURCE structure, so it won't appear at top level either
}

# Test complex ruleset with commands, file rules, and symlinked rules
# Expected: Commands preserved, file rules preserve structure, symlinked rules flat, all removed correctly
test_complex_ruleset_structure_preserved() {
	# Setup: Ruleset with commands, file rules in subdirs, and symlinked rules
	mkdir -p "$REPO_DIR/rulesets/test-complex/commands/subs"
	mkdir -p "$REPO_DIR/rulesets/test-complex/Core"
	echo "command" > "$REPO_DIR/rulesets/test-complex/commands/top.md"
	echo "nested" > "$REPO_DIR/rulesets/test-complex/commands/subs/nested.md"
	echo "file rule" > "$REPO_DIR/rulesets/test-complex/Core/core-rule.mdc"
	echo "rootrule" > "$REPO_DIR/rulesets/test-complex/rootrule.mdc"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-complex/symlinked-rule.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset
	cmd_add_ruleset "test-complex" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Expected: Commands preserved, file rules preserve structure, symlinked rules flat
	test -f "commands/ai-rizz/test-complex/top.md" || fail "Top command should be copied"
	test -f "commands/ai-rizz/test-complex/subs/nested.md" || fail "Nested command should be copied"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Root file rule should be copied"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/Core/core-rule.mdc" || fail "Subdirectory file rule should preserve structure"
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/symlinked-rule.mdc" || fail "Symlinked rule should be copied (flat)"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/Core/symlinked-rule.mdc" || fail "Symlinked rule should NOT preserve structure"
	
	# Remove ruleset
	cmd_remove_ruleset "test-complex"
	
	# Expected: Commands removed, rules removed
	test ! -f "commands/ai-rizz/test-complex/top.md" || fail "Commands should be removed"
	test ! -f "commands/ai-rizz/test-complex/subs/nested.md" || fail "Nested commands should be removed"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rootrule.mdc" || fail "Rules should be removed"
	test ! -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/Core/core-rule.mdc" || fail "Structured rules should be removed"
}

# Test list display shows correct structure (top-level only, commands/ special)
# Expected: List shows top-level .mdc files, top-level subdirs (no contents), commands/ one level
test_list_display_shows_correct_structure() {
	# Setup: Create ruleset matching the example from tasks.md
	mkdir -p "$REPO_DIR/rulesets/test-list-display/commands/subs"
	mkdir -p "$REPO_DIR/rulesets/test-list-display/Core"
	echo "rootrule" > "$REPO_DIR/rulesets/test-list-display/rootrule.mdc"
	echo "symlinked-rule" > "$REPO_DIR/rulesets/test-list-display/symlinked-rule.mdc"
	echo "file rule" > "$REPO_DIR/rulesets/test-list-display/Core/core-rule.mdc"
	echo "command" > "$REPO_DIR/rulesets/test-list-display/commands/top.md"
	echo "nested" > "$REPO_DIR/rulesets/test-list-display/commands/subs/nested.md"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset and list
	cmd_add_ruleset "test-list-display" --commit
	assertTrue "Should add ruleset successfully" $?
	
	output=$(cmd_list)
	
	# Expected: Top-level .mdc files are shown
	echo "$output" | grep -A 15 "test-list-display" | grep -q "rootrule.mdc" || fail "rootrule.mdc should appear in list (top-level)"
	echo "$output" | grep -A 15 "test-list-display" | grep -q "symlinked-rule.mdc" || fail "symlinked-rule.mdc should appear in list (top-level)"
	
	# Expected: Top-level subdirs are shown (but NO contents)
	echo "$output" | grep -A 15 "test-list-display" | grep -q "Core" || fail "Core/ directory should appear in list"
	# Core/ subdir contents should NOT appear
	if echo "$output" | grep -A 20 "test-list-display" | grep -A 5 "Core" | grep -q "core-rule.mdc"; then
		fail "core-rule.mdc should NOT appear under Core/ in list (subdir contents are not shown)"
	fi
	
	# Expected: commands/ subdir gets special treatment (one level shown)
	echo "$output" | grep -A 15 "test-list-display" | grep -q "commands" || fail "commands/ directory should appear in list"
	# Top-level files in commands/ should appear
	echo "$output" | grep -A 20 "test-list-display" | grep -A 10 "commands" | grep -q "top.md" || fail "top.md should appear in commands/ expansion"
	# Subdirs in commands/ should appear
	echo "$output" | grep -A 20 "test-list-display" | grep -A 10 "commands" | grep -q "subs" || fail "subs/ subdir should appear in commands/ expansion"
	# But subdir contents in commands/ should NOT appear
	if echo "$output" | grep -A 25 "test-list-display" | grep -A 15 "commands" | grep -A 5 "subs" | grep -q "nested.md"; then
		fail "nested.md should NOT appear under commands/subs/ in list (subdir contents in commands/ are not shown)"
	fi
}

# Test that rules in subdirectories of rulesets are detected as installed
# Expected: Rule in subdirectory of installed ruleset should show as installed
# Bug: check_rulesets_for_item() only checks top-level, not subdirectories
test_rule_in_subdirectory_shows_as_installed() {
	# Setup: Create ruleset with symlinked rule in subdirectory
	mkdir -p "$REPO_DIR/rulesets/test-subdir-installed/supporting"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-subdir-installed/supporting/rule1.mdc"
	
	# Commit and initialize
	cd "$REPO_DIR" && git add . && git commit --no-gpg-sign -m "test" >/dev/null 2>&1
	cd "$TEST_DIR/app" && cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
	
	# Action: Add ruleset (should succeed)
	cmd_add_ruleset "test-subdir-installed" --commit
	assertTrue "Should add ruleset successfully" $?
	
	# Verify rule was copied (symlink copied flat)
	test -f "$TEST_TARGET_DIR/$TEST_SHARED_DIR/rule1.mdc" || fail "rule1.mdc should be copied (flat)"
	
	# Expected: Rule should show as installed in list (even though it's in a subdirectory)
	output=$(cmd_list)
	# rule1.mdc should show as installed (committed glyph ●)
	echo "$output" | grep -q "●.*rule1.mdc" || fail "rule1.mdc should show as installed (it's in installed ruleset, even in subdirectory)"
	# Should NOT show as uninstalled
	if echo "$output" | grep -q "○.*rule1.mdc"; then
		fail "rule1.mdc should NOT show as uninstalled (it's in installed ruleset)"
	fi
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

