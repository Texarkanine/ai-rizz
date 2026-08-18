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
. "$(dirname "$0")/../../common.sh"

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
	
	# Action: Run cmd_list --all
	output=$(cmd_list --all)
	
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
	
	# Action: Run cmd_list --all and check output formatting
	output=$(cmd_list --all)
	
	# Expected: Correct indentation (4 spaces + tree character for commands)
	# Check that commands/ line has proper indentation (4 spaces + tree character)
	echo "$output" | grep -q "^    .*commands" || fail "commands/ should have 4-space indentation"
	# Check that commands contents have proper indentation and are shown
	echo "$output" | grep -A 5 "commands" | grep -q "file.md" || fail "Should show file.md in commands expansion"
}

# Test that nested children under a last-sibling commands/ use a blank stem
# (spaces), not a dangling │. Fixture: sibling sorts before "commands" so
# commands/ is └── and its children must not continue with │.
test_list_commands_last_sibling_uses_blank_stem() {
	mkdir -p "$REPO_DIR/rulesets/test-cmd-last/commands"
	echo "cmd" > "$REPO_DIR/rulesets/test-cmd-last/commands/nested.md"
	# "aaa.mdc" sorts before "commands" → commands is last sibling (└──)
	echo "rule" > "$REPO_DIR/rulesets/test-cmd-last/aaa.mdc"

	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-cmd-last ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"

	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	output=$(cmd_list --all)

	echo "$output" | grep -q "└── commands" || \
		fail "commands/ should be last sibling (└──): $output"
	echo "$output" | grep -q "^        └── nested.md$" || \
		fail "child under last-sibling commands/ should use blank stem (spaces), not │: $output"
	if echo "$output" | grep -q "^    │   .*nested.md"; then
		fail "child under last-sibling commands/ must not use │ stem: $output"
	fi
}

# Test that nested children under a non-last commands/ keep the │ stem.
# Fixture: sibling sorts after "commands" so commands/ is ├──.
test_list_commands_middle_sibling_keeps_pipe_stem() {
	mkdir -p "$REPO_DIR/rulesets/test-cmd-mid/commands"
	echo "cmd" > "$REPO_DIR/rulesets/test-cmd-mid/commands/nested.md"
	# "zzz.mdc" sorts after "commands" → commands is middle sibling (├──)
	echo "rule" > "$REPO_DIR/rulesets/test-cmd-mid/zzz.mdc"

	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-cmd-mid ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"

	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	output=$(cmd_list --all)

	echo "$output" | grep -q "├── commands" || \
		fail "commands/ should be non-last sibling (├──): $output"
	echo "$output" | grep -q "^    │   └── nested.md$" || \
		fail "child under non-last commands/ should keep │ stem: $output"
}

# Test that nested children under a last-sibling skills/ use a blank stem.
# Fixture: sibling sorts before "skills" so skills/ is └──.
test_list_skills_last_sibling_uses_blank_stem() {
	mkdir -p "$REPO_DIR/rulesets/test-skl-last/skills/nested-skill"
	echo "# Nested" > "$REPO_DIR/rulesets/test-skl-last/skills/nested-skill/SKILL.md"
	echo "rule" > "$REPO_DIR/rulesets/test-skl-last/aaa.mdc"

	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-skl-last ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"

	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	output=$(cmd_list --all)

	echo "$output" | grep -A 20 "test-skl-last" | grep -q "└── skills" || \
		fail "skills/ should be last sibling (└──): $output"
	echo "$output" | grep -q "^        └── nested-skill$" || \
		fail "child under last-sibling skills/ should use blank stem (spaces), not │: $output"
	if echo "$output" | grep -q "^    │   .*nested-skill"; then
		fail "child under last-sibling skills/ must not use │ stem: $output"
	fi
}

# Test that nested children under a non-last skills/ keep the │ stem.
# Fixture: sibling sorts after "skills" so skills/ is ├──.
test_list_skills_middle_sibling_keeps_pipe_stem() {
	mkdir -p "$REPO_DIR/rulesets/test-skl-mid/skills/nested-skill"
	echo "# Nested" > "$REPO_DIR/rulesets/test-skl-mid/skills/nested-skill/SKILL.md"
	echo "rule" > "$REPO_DIR/rulesets/test-skl-mid/zzz.mdc"

	cd "$REPO_DIR" || fail "Failed to change to repo directory"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add test-skl-mid ruleset" >/dev/null 2>&1
	cd "$TEST_DIR/app" || fail "Failed to change to app directory"

	cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
	output=$(cmd_list --all)

	echo "$output" | grep -A 20 "test-skl-mid" | grep -q "├── skills" || \
		fail "skills/ should be non-last sibling (├──): $output"
	echo "$output" | grep -q "^    │   └── nested-skill$" || \
		fail "child under non-last skills/ should keep │ stem: $output"
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
	
	# Action: Run cmd_list --all
	output=$(cmd_list --all)
	
	# Expected: commands/ shown but no command files listed beneath it (SLOBAC: oracle on cmd_list --all output)
	echo "$output" | grep -q "commands" || fail "Should show commands/ directory"
	echo "$output" | grep -q "test-empty" || fail "Should show test-empty ruleset"
	# Slice: test-empty ruleset subtree; under the commands/ line there must be no *.md command entries
	# (use /\.md$ so rule1.mdc does not match as "contains .md")
	if echo "$output" | grep -A 50 "test-empty" | grep -A 15 "commands" | grep -qE '\.md$'; then
		fail "cmd_list --all should not list .md command files under empty commands/; output was: $output"
	fi
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
    
    output=$(cmd_list --all)
    
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
    
    output=$(cmd_list --all)
    
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
    
    # Run test in subshell to ensure cleanup on early failure
    (
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
    )
    tlsggfgc_status=$?
    
    teardown_global_for_commands
    
    return $tlsggfgc_status
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
    
    output=$(cmd_list --all)
    
    # Should show uninstalled glyph (○) for the command
    echo "$output" | grep -E "○.*unused-cmd|○.*\/unused-cmd" || \
        fail "Should show uninstalled glyph for new command: $output"
}

# Test that the commands section is omitted entirely when no commands exist
test_list_empty_commands_section_omitted() {
    # Setup: Remove any .md files to ensure no commands exist
    # The common setUp creates command1.md and command2.md for other tests
    rm -f "$REPO_DIR/rules/"*.md

    # Commit the removal
    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Remove command files for empty test" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit

    output=$(cmd_list --all)

    # When no commands exist, the section header and "No commands found" must be absent
    assertFalse "Available commands: section must not appear when empty" \
        "echo '${output}' | grep -q 'Available commands:'"
    assertFalse "No commands found message must not appear" \
        "echo '${output}' | grep -q 'No commands found'"
}

# Test that the rules section is omitted entirely when no rules exist
test_list_empty_rules_section_omitted() {
    # Setup: Remove all .mdc rule files so the rules section is empty
    rm -f "$REPO_DIR/rules/"*.mdc

    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Remove rules for empty-section test" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit

    output=$(cmd_list --all)

    assertFalse "Available rules: section must not appear when empty" \
        "echo '${output}' | grep -q 'Available rules:'"
    assertFalse "No rules found message must not appear" \
        "echo '${output}' | grep -q 'No rules found'"
}

# Test that the skills section is omitted entirely when no standalone skills exist
test_list_empty_skills_section_omitted() {
    # The base test repo (setUp) has rules but no skill directories, so the
    # "Available skills:" section must be absent from cmd_list --all output.
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit

    output=$(cmd_list --all)

    assertFalse "Available skills: section must not appear when empty" \
        "echo '${output}' | grep -q 'Available skills:'"
    assertFalse "No skills found message must not appear" \
        "echo '${output}' | grep -q 'No skills found'"
}

# Test that the rulesets section is omitted entirely when no rulesets exist
test_list_empty_rulesets_section_omitted() {
    # Remove the rulesets created by setUp so the section is empty.
    rm -rf "$REPO_DIR/rulesets"
    mkdir -p "$REPO_DIR/rulesets"

    cd "$REPO_DIR" || fail "Failed to cd to repo"
    git add . >/dev/null 2>&1
    git commit --no-gpg-sign -m "Remove rulesets for empty-section test" >/dev/null 2>&1
    cd "$TEST_DIR/app" || fail "Failed to cd to app"

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit

    output=$(cmd_list --all)

    assertFalse "Available rulesets: section must not appear when empty" \
        "echo '${output}' | grep -q 'Available rulesets:'"
    assertFalse "No rulesets found message must not appear" \
        "echo '${output}' | grep -q 'No rulesets found'"
}

# Count uninstalled glyph rows in list output (top-level ○ lines).
#
# Arguments:
#   $1 - list output
#
# Outputs:
#   Stdout: integer count with no leading spaces
_count_uninstalled_rows() {
	printf '%s\n' "${1}" | grep -F "${UNINSTALLED_GLYPH}" | wc -l | tr -d ' \t'
}

# ============================================================================
# DEFAULT INVENTORY / --all CATALOG
# ============================================================================

test_list_default_hides_uninstalled_and_prints_footer() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "rule1.mdc" --commit

	all_output=$(cmd_list --all)
	output=$(cmd_list)

	echo "${output}" | grep -q "${COMMITTED_GLYPH}.*rule1" || \
		fail "default list should show installed rule1: ${output}"
	if echo "${output}" | grep -q "${UNINSTALLED_GLYPH}"; then
		fail "default list must not show uninstalled rows: ${output}"
	fi
	hidden=$(_count_uninstalled_rows "${all_output}")
	echo "${output}" | grep -qx "${hidden} available, not shown" || \
		fail "expected footer '${hidden} available, not shown': ${output}"
}

test_list_omits_header_when_section_has_no_installed_members() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "rule1.mdc" --commit

	output=$(cmd_list)

	echo "${output}" | grep -q "Available rules:" || \
		fail "installed rule should keep the rules header: ${output}"
	if echo "${output}" | grep -q "Available commands:"; then
		fail "commands header must be omitted when none are installed: ${output}"
	fi
}

test_list_nothing_installed_is_footer_only() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	all_output=$(cmd_list --all)
	output=$(cmd_list)

	if echo "${output}" | grep -q "Available "; then
		fail "no section headers when nothing is installed: ${output}"
	fi
	hidden=$(_count_uninstalled_rows "${all_output}")
	echo "${output}" | grep -qx "${hidden} available, not shown" || \
		fail "expected footer-only output '${hidden} available, not shown': ${output}"
}

test_list_no_footer_when_everything_installed() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "rule1.mdc" --commit
	cmd_add_rule "rule2.mdc" --commit
	cmd_add_rule "rule3.mdc" --commit
	cmd_add_rule "command1.md" --commit
	cmd_add_rule "command2.md" --commit
	cmd_add_ruleset "ruleset1" --commit
	cmd_add_ruleset "ruleset2" --commit

	output=$(cmd_list)

	if echo "${output}" | grep -q "available, not shown"; then
		fail "no footer when every catalog item is installed: ${output}"
	fi
}

test_list_all_has_uninstalled_rows_and_no_footer() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list --all)

	echo "${output}" | grep -q "${UNINSTALLED_GLYPH}" || \
		fail "--all should show uninstalled glyphs: ${output}"
	if echo "${output}" | grep -q "available, not shown"; then
		fail "--all must not print the hidden footer: ${output}"
	fi
}

test_list_dash_a_matches_all() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	all_output=$(cmd_list --all)
	dash_output=$(cmd_list -a)

	assertEquals "-a should match --all" "${all_output}" "${dash_output}"
}

test_list_unknown_argument_errors() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list --installed 2>&1)
	status=$?

	assertNotEquals "unknown list arg should exit nonzero" "0" "${status}"
	echo "${output}" | grep -q "Unknown argument: --installed" || \
		fail "unknown list arg should name the token: ${output}"
}

test_list_installed_ruleset_expands_and_omits_sibling() {
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "ruleset1" --commit

	output=$(cmd_list)

	echo "${output}" | grep -q "ruleset1" || \
		fail "installed ruleset should appear: ${output}"
	echo "${output}" | grep -q "rule1.mdc" || \
		fail "installed ruleset should still expand its tree: ${output}"
	if echo "${output}" | grep -q "ruleset2"; then
		fail "uninstalled sibling ruleset must be omitted: ${output}"
	fi
}

test_list_empty_catalog_prints_nothing() {
	rm -f "${REPO_DIR}/rules/"*.mdc "${REPO_DIR}/rules/"*.md
	rm -rf "${REPO_DIR}/rulesets"
	mkdir -p "${REPO_DIR}/rulesets"
	cl_empty_skill_dirs=$(find "${REPO_DIR}/rules" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
	if [ -n "${cl_empty_skill_dirs}" ]; then
		rm -rf ${cl_empty_skill_dirs}
	fi

	cd "${REPO_DIR}" || fail "Failed to cd to repo"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Empty the catalog" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	output=$(cmd_list)

	[ -z "${output}" ] || fail "empty catalog should print nothing: ${output}"
}

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../../shunit2"

