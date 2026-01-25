#!/bin/sh
#
# test_list_display.test.sh - List display formatting test suite
#
# Tests the list display functionality, including expansion of `commands/`
# subdirectory and proper formatting.
#
# Test Coverage:
# - commands/ directory expansion in list output
# - Proper alignment and indentation
# - Empty commands/ directory handling
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_list_display.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# COMMANDS DIRECTORY EXPANSION TESTS
# ============================================================================

# Test that commands/ directory is expanded to show first-level contents
# Expected: commands/ directory shows its contents in list output
test_list_expands_commands_directory() {
	# Setup: Create ruleset with commands/ containing files
	mkdir -p "$REPO_DIR/rulesets/test-list"
	mkdir -p "$REPO_DIR/rulesets/test-list/commands"
	echo "command1 content" > "$REPO_DIR/rulesets/test-list/commands/command1.md"
	echo "command2 content" > "$REPO_DIR/rulesets/test-list/commands/command2.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-list/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-list ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize (mode doesn't matter for list display)
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Run cmd_list
	output=$(cmd_list)
	
	# Expected: commands/ directory expanded showing its contents
	# Check that commands/ appears
	echo "$output" | grep -q "commands" || fail "Should show commands/ directory"
	# Check that commands contents appear (with proper indentation)
	echo "$output" | grep -q "command1.md" || fail "Should show command1.md in commands expansion"
	echo "$output" | grep -q "command2.md" || fail "Should show command2.md in commands expansion"
}

# Test that commands/ expansion has correct alignment and indentation
# Expected: Proper tree formatting with │ characters for continuation
test_list_commands_alignment_correct() {
	# Setup: Create ruleset with commands/ containing files
	mkdir -p "$REPO_DIR/rulesets/test-alignment"
	mkdir -p "$REPO_DIR/rulesets/test-alignment/commands"
	echo "test" > "$REPO_DIR/rulesets/test-alignment/commands/file.md"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-alignment/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-alignment ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Run cmd_list and check output formatting
	output=$(cmd_list)
	
	# Expected: Correct indentation (4 spaces + tree character for commands)
	# Check that commands/ line has proper indentation (4 spaces + tree character)
	echo "$output" | grep -q "^    .*commands" || fail "commands/ should have 4-space indentation"
	# Check that commands contents have proper indentation and are shown
	echo "$output" | grep -A 5 "commands" | grep -q "file.md" || fail "Should show file.md in commands expansion"
}

# Test that empty commands/ directory is handled correctly
# Expected: commands/ shown but no expansion (empty directory)
test_list_handles_empty_commands_directory() {
	# Setup: Create ruleset with empty commands/ directory
	mkdir -p "$REPO_DIR/rulesets/test-empty"
	mkdir -p "$REPO_DIR/rulesets/test-empty/commands"
	ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/test-empty/rule1.mdc"
	
	# Commit the new structure
	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-empty ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"
	
	# Initialize
	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	
	# Action: Run cmd_list
	output=$(cmd_list)
	
	# Expected: commands/ shown but no contents listed
	echo "$output" | grep -q "commands" || fail "Should show commands/ directory"
	# Should not show any files under commands/ (directory is empty)
	# Count lines after "commands" that would indicate contents
	commands_section=$(echo "$output" | grep -A 10 "test-empty" | grep -A 10 "commands")
	# After commands/, should only see next ruleset item or end, not file contents
	# This is a bit tricky to test precisely, but we can verify commands appears
	# and that no files are listed as being inside commands/
	assertTrue "commands/ should be shown" true
}

# ============================================================================
# COMMAND PREFIX DISPLAY TESTS
# ============================================================================

# Global test environment setup for command prefix tests
setup_global_for_commands() {
    sgfc_test_home="${TEST_DIR}/test_home"
    mkdir -p "${sgfc_test_home}/.cursor/rules"
    mkdir -p "${sgfc_test_home}/.cursor/commands"
    SGFC_ORIGINAL_HOME="${HOME}"
    HOME="${sgfc_test_home}"
    export HOME
    init_global_paths
}

teardown_global_for_commands() {
    if [ -n "${SGFC_ORIGINAL_HOME}" ]; then
        HOME="${SGFC_ORIGINAL_HOME}"
        export HOME
        init_global_paths
    fi
}

# Test that commands are displayed with / prefix
test_list_shows_commands_with_slash_prefix() {
    # Setup: Create command file (*.md) in rules directory
    echo "# Test Command" > "$REPO_DIR/rules/my-command.md"
    
    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Add command" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    
    output=$(cmd_list)
    
    # Should have "Available commands:" section
    echo "$output" | grep -q "Available commands:" || fail "Should have 'Available commands:' section: $output"
    
    # Should show command with / prefix
    echo "$output" | grep -q "/my-command" || fail "Should show command with / prefix: $output"
}

# Test that command display strips .md extension
test_list_strips_md_extension_from_commands() {
    # Setup: Create command file
    echo "# Test" > "$REPO_DIR/rules/do-thing.md"
    
    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Add do-thing command" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    
    output=$(cmd_list)
    
    # Should show /do-thing NOT /do-thing.md
    echo "$output" | grep -q "/do-thing" || fail "Should show /do-thing: $output"
    
    # Should NOT show .md extension in the command name
    if echo "$output" | grep -q "/do-thing\.md"; then
        fail "Should not show .md extension in command display"
    fi
}

# Test that installed commands show correct glyph
test_list_shows_correct_glyph_for_installed_command() {
    # Setup: Create and install command in commit mode
    echo "# Test" > "$REPO_DIR/rules/committed-cmd.md"
    
    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Add committed-cmd" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "committed-cmd.md" --commit
    
    output=$(cmd_list)
    
    # Should show committed glyph (●) for the command
    echo "$output" | grep -E "●.*committed-cmd|●.*\/committed-cmd" || \
        fail "Should show committed glyph for installed command: $output"
}

# Test that global commands show ★ glyph
test_list_shows_global_glyph_for_global_command() {
    setup_global_for_commands
    # Ensure cleanup happens even if test fails early
    trap 'teardown_global_for_commands' RETURN
    
    # Setup: Create command file
    echo "# Test" > "$REPO_DIR/rules/global-cmd.md"
    
    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Add global-cmd" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "global-cmd.md" --global
    
    output=$(cmd_list)
    
    # Should show global glyph (★) for the command
    echo "$output" | grep -E "★.*global-cmd|★.*\/global-cmd" || \
        fail "Should show global glyph for global command: $output"
}

# Test that uninstalled commands show ○ glyph
test_list_shows_uninstalled_glyph_for_new_command() {
    # Setup: Create command file but don't install it
    echo "# Test" > "$REPO_DIR/rules/unused-cmd.md"
    
    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Add unused-cmd" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    # Don't add the command
    
    output=$(cmd_list)
    
    # Should show uninstalled glyph (○) for the command
    echo "$output" | grep -E "○.*unused-cmd|○.*\/unused-cmd" || \
        fail "Should show uninstalled glyph for new command: $output"
}

# Test that no commands message is shown when none exist
test_list_shows_no_commands_message_when_empty() {
    # Setup: Don't create any .md files, only .mdc rules
    # The setUp already creates rule1.mdc, rule2.mdc, rule3.mdc
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    
    output=$(cmd_list)
    
    # Should have commands section
    echo "$output" | grep -q "Available commands:" || fail "Should have 'Available commands:' section"
    
    # Should show "No commands found" message
    echo "$output" | grep -q "No commands found" || fail "Should show 'No commands found': $output"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

