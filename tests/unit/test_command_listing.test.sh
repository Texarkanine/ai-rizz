#!/usr/bin/env bash
#
# Test Suite: Command Listing
#
# Tests the command listing functionality including:
# - Basic command listing
# - Filter arguments (rules, cmds, all)
# - Status glyphs (committed, uninstalled)
# - Edge cases (no commands, empty directories)

# Load test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/lib/framework.sh
. "${SCRIPT_DIR}/../lib/framework.sh"

# Test: List commands shows available commands from source repo
test_list_commands_shows_available_commands() {
	echo "STUB: Should list all .md files from commands/ directory"
	return 1
}

# Test: List commands shows proper glyph for installed commands
test_list_commands_shows_committed_glyph() {
	echo "STUB: Should show ● for commands in commit manifest"
	return 1
}

# Test: List commands shows proper glyph for uninstalled commands
test_list_commands_shows_uninstalled_glyph() {
	echo "STUB: Should show ○ for commands not in manifest"
	return 1
}

# Test: List with 'rules' filter shows only rules
test_list_with_rules_filter() {
	echo "STUB: Should show rules and rulesets but not commands"
	return 1
}

# Test: List with 'cmds' filter shows only commands
test_list_with_cmds_filter() {
	echo "STUB: Should show commands and commandsets but not rules"
	return 1
}

# Test: List with 'commands' filter (alias) shows only commands
test_list_with_commands_filter() {
	echo "STUB: Should accept 'commands' as alias for 'cmds'"
	return 1
}

# Test: List with no argument shows both rules and commands
test_list_default_shows_all() {
	echo "STUB: Should show both rules and commands when no filter specified"
	return 1
}

# Test: List with 'all' argument shows both rules and commands
test_list_all_shows_all() {
	echo "STUB: Should show both rules and commands with explicit 'all' filter"
	return 1
}

# Test: List handles missing commands directory gracefully
test_list_handles_missing_commands_directory() {
	echo "STUB: Should not error when source repo has no commands/ directory"
	return 1
}

# Test: List handles empty commands directory gracefully
test_list_handles_empty_commands_directory() {
	echo "STUB: Should show 'No commands found' when commands/ is empty"
	return 1
}

# Test: List commands in alphabetical order
test_list_commands_sorted() {
	echo "STUB: Should list commands in alphabetical order"
	return 1
}

# Run all tests
run_test_suite
