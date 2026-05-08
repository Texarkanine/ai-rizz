#!/bin/sh
#
# test_command_modes.test.sh - Command mode restrictions test suite
#
# Tests that rulesets with commands can be added in global mode. Local/commit
# command placement and rulesets-with-commands behavior are covered canonically
# in test_command_sync.test.sh and test_ruleset_commands.test.sh.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_command_modes.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP
# ============================================================================

create_ruleset_with_commands() {
    crwc_ruleset_name="${1}"
    mkdir -p "${REPO_DIR}/rulesets/${crwc_ruleset_name}/commands"
    
    # Create a rule in the ruleset
    cat > "${REPO_DIR}/rulesets/${crwc_ruleset_name}/main.mdc" << 'EOF'
# Main Rule
This is the main rule.
EOF
    
    # Create a command in the ruleset
    cat > "${REPO_DIR}/rulesets/${crwc_ruleset_name}/commands/do-thing.md" << 'EOF'
# Do Thing Command
This command does a thing.
EOF
}

# Global test environment setup
setup_global_test_environment() {
    sgte_test_home="${TEST_DIR}/test_home"
    mkdir -p "${sgte_test_home}/.cursor/rules"
    mkdir -p "${sgte_test_home}/.cursor/commands"
    SGTE_ORIGINAL_HOME="${HOME}"
    HOME="${sgte_test_home}"
    export HOME
    init_global_paths
}

teardown_global_test_environment() {
    if [ -n "${SGTE_ORIGINAL_HOME}" ]; then
        HOME="${SGTE_ORIGINAL_HOME}"
        export HOME
        init_global_paths
    fi
}

# ============================================================================
# RULESET WITH COMMANDS — global (canonical local/commit copies in test_ruleset_commands.test.sh)
# ============================================================================

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

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../../shunit2"
