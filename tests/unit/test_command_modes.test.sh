#!/bin/sh
#
# test_command_modes.test.sh - Command mode restrictions test suite
#
# Tests that commands can be added in ALL modes (local, commit, global)
# and that the previous restriction on local mode for rulesets with 
# commands has been removed.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_command_modes.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP
# ============================================================================

create_command_in_source() {
    command_name="${1}"
    mkdir -p "${REPO_DIR}/rules"
    cat > "${REPO_DIR}/rules/${command_name}" << 'EOF'
# Test Command
This is a test command.
EOF
}

create_ruleset_with_commands() {
    ruleset_name="${1}"
    mkdir -p "${REPO_DIR}/rulesets/${ruleset_name}/commands"
    
    # Create a rule in the ruleset
    cat > "${REPO_DIR}/rulesets/${ruleset_name}/main.mdc" << 'EOF'
# Main Rule
This is the main rule.
EOF
    
    # Create a command in the ruleset
    cat > "${REPO_DIR}/rulesets/${ruleset_name}/commands/do-thing.md" << 'EOF'
# Do Thing Command
This command does a thing.
EOF
}

# Global test environment setup
setup_global_test_environment() {
    TEST_HOME="${TEST_DIR}/test_home"
    mkdir -p "${TEST_HOME}/.cursor/rules"
    mkdir -p "${TEST_HOME}/.cursor/commands"
    ORIGINAL_HOME="${HOME}"
    HOME="${TEST_HOME}"
    export HOME
    init_global_paths
}

teardown_global_test_environment() {
    if [ -n "${ORIGINAL_HOME}" ]; then
        HOME="${ORIGINAL_HOME}"
        export HOME
    fi
}

# ============================================================================
# COMMAND MODE TESTS - Commands work in all modes
# ============================================================================

test_command_can_be_added_in_local_mode() {
    # Test: Commands can be added in local mode (previously might have been restricted)
    # Expected: Successfully adds command to local mode
    
    create_command_in_source "local-cmd.md"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    
    # This should succeed (no restriction)
    output=$(cmd_add_rule "local-cmd.md" --local 2>&1)
    
    # Should not contain any error
    echo "$output" | grep -qi "error" && fail "Should not error when adding command to local mode"
    
    # Command should be synced
    assertTrue "Command should exist in local commands dir" \
        "[ -f '.cursor/commands/local/local-cmd.md' ]"
}

test_command_can_be_added_in_commit_mode() {
    # Test: Commands can be added in commit mode
    # Expected: Successfully adds command to commit mode
    
    create_command_in_source "commit-cmd.md"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "commit-cmd.md" --commit
    
    assertTrue "Command should exist in commit commands dir" \
        "[ -f '.cursor/commands/shared/commit-cmd.md' ]"
}

test_command_can_be_added_in_global_mode() {
    # Test: Commands can be added in global mode
    # Expected: Successfully adds command to global mode
    
    setup_global_test_environment
    create_command_in_source "global-cmd.md"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "global-cmd.md" --global
    
    assertTrue "Command should exist in global commands dir" \
        "[ -f '${GLOBAL_COMMANDS_DIR}/global-cmd.md' ]"
    
    teardown_global_test_environment
}

# ============================================================================
# RULESET WITH COMMANDS - No longer restricted to commit mode
# ============================================================================

test_ruleset_with_commands_can_be_added_local() {
    # Test: Rulesets containing commands can now be added in local mode
    # Expected: Successfully adds ruleset with commands to local mode
    
    create_ruleset_with_commands "my-ruleset"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    
    # This should succeed (restriction removed)
    output=$(cmd_add_ruleset "my-ruleset" --local 2>&1)
    
    # Should not contain the old error message
    echo "$output" | grep -qi "must be added in commit mode" && \
        fail "Should not show old commit-only restriction"
    
    # Rule should be synced to rules dir
    assertTrue "Rule should exist in local rules dir" \
        "[ -f '.cursor/rules/local/main.mdc' ]"
    
    # Command should be synced to commands dir
    assertTrue "Command should exist in local commands dir" \
        "[ -f '.cursor/commands/local/do-thing.md' ]"
}

test_ruleset_with_commands_can_be_added_commit() {
    # Test: Rulesets containing commands can be added in commit mode (still works)
    # Expected: Successfully adds ruleset with commands to commit mode
    
    create_ruleset_with_commands "my-ruleset"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_ruleset "my-ruleset" --commit
    
    # Rule should be synced
    assertTrue "Rule should exist in commit rules dir" \
        "[ -f '.cursor/rules/shared/main.mdc' ]"
    
    # Command should be synced
    assertTrue "Command should exist in commit commands dir" \
        "[ -f '.cursor/commands/shared/do-thing.md' ]"
}

test_ruleset_with_commands_can_be_added_global() {
    # Test: Rulesets containing commands can be added in global mode
    # Expected: Successfully adds ruleset with commands to global mode
    
    setup_global_test_environment
    create_ruleset_with_commands "my-ruleset"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_ruleset "my-ruleset" --global
    
    # Rule should be synced to global rules dir
    assertTrue "Rule should exist in global rules dir" \
        "[ -f '${GLOBAL_RULES_DIR}/main.mdc' ]"
    
    # Command should be synced to global commands dir
    assertTrue "Command should exist in global commands dir" \
        "[ -f '${GLOBAL_COMMANDS_DIR}/do-thing.md' ]"
    
    teardown_global_test_environment
}

# ============================================================================
# RESTRICTION REMOVAL VERIFICATION
# ============================================================================

test_show_ruleset_commands_error_removed() {
    # Test: The show_ruleset_commands_error function should be removed or unused
    # Expected: Function doesn't exist or isn't called
    
    # Verify function is removed by trying to call it
    # This should fail if the function is removed
    if type show_ruleset_commands_error >/dev/null 2>&1; then
        fail "show_ruleset_commands_error function should be removed"
    fi
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
