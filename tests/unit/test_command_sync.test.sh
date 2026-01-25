#!/bin/sh
#
# test_command_sync.test.sh - Command sync test suite
#
# Tests that commands (*.md files) are synced to the correct subdirectories
# based on mode (.cursor/commands/{local,shared}/).
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_command_sync.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP - Create command files in source repo
# ============================================================================

create_command_in_source() {
    # Create a command file in the source repo's rules directory
    command_name="${1}"
    mkdir -p "${REPO_DIR}/rules"
    cat > "${REPO_DIR}/rules/${command_name}" << EOF
# Test Command: ${command_name}
This is a test command.
EOF
}

# ============================================================================
# COMMAND SYNC TO LOCAL MODE TESTS
# ============================================================================

test_command_syncs_to_local_commands_dir() {
    # Test: Adding a command in local mode syncs to .cursor/commands/local/
    # Expected: Command file exists in .cursor/commands/local/
    
    # Create command in source
    create_command_in_source "test-cmd.md"
    
    # Initialize and add command in local mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "test-cmd.md" --local
    
    # Verify command is in commands directory, not rules directory
    assertTrue "Command should be in .cursor/commands/local/" \
        "[ -f '.cursor/commands/local/test-cmd.md' ]"
    assertFalse "Command should NOT be in .cursor/rules/local/" \
        "[ -f '.cursor/rules/local/test-cmd.md' ]"
}

test_rule_syncs_to_local_rules_dir() {
    # Test: Adding a rule in local mode syncs to .cursor/rules/local/
    # Expected: Rule file exists in .cursor/rules/local/
    
    # Initialize and add rule in local mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Verify rule is in rules directory
    assertTrue "Rule should be in .cursor/rules/local/" \
        "[ -f '.cursor/rules/local/rule1.mdc' ]"
}

# ============================================================================
# COMMAND SYNC TO COMMIT MODE TESTS
# ============================================================================

test_command_syncs_to_commit_commands_dir() {
    # Test: Adding a command in commit mode syncs to .cursor/commands/shared/
    # Expected: Command file exists in .cursor/commands/shared/
    
    # Create command in source
    create_command_in_source "test-cmd.md"
    
    # Initialize and add command in commit mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "test-cmd.md" --commit
    
    # Verify command is in commands directory
    assertTrue "Command should be in .cursor/commands/shared/" \
        "[ -f '.cursor/commands/shared/test-cmd.md' ]"
    assertFalse "Command should NOT be in .cursor/rules/shared/" \
        "[ -f '.cursor/rules/shared/test-cmd.md' ]"
}

# ============================================================================
# COMMAND SYNC TO GLOBAL MODE TESTS
# ============================================================================

test_command_syncs_to_global_commands_dir() {
    # Test: Adding a command in global mode syncs to ~/.cursor/commands/ai-rizz/
    # Expected: Command file exists in global commands directory
    
    # Setup global test environment
    TEST_HOME="${TEST_DIR}/test_home"
    mkdir -p "${TEST_HOME}/.cursor/commands"
    mkdir -p "${TEST_HOME}/.cursor/rules"
    ORIGINAL_HOME="${HOME}"
    HOME="${TEST_HOME}"
    export HOME
    init_global_paths
    
    # Create command in source
    create_command_in_source "test-cmd.md"
    
    # Initialize and add command in global mode
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "test-cmd.md" --global
    
    # Verify command is in global commands directory
    assertTrue "Command should be in global commands dir" \
        "[ -f '${GLOBAL_COMMANDS_DIR}/test-cmd.md' ]"
    assertFalse "Command should NOT be in global rules dir" \
        "[ -f '${GLOBAL_RULES_DIR}/test-cmd.md' ]"
    
    # Cleanup
    HOME="${ORIGINAL_HOME}"
    export HOME
}

# ============================================================================
# MIXED ENTITY SYNC TESTS
# ============================================================================

test_mixed_entities_sync_correctly() {
    # Test: Rules and commands both sync to correct directories
    # Expected: Rules in rules dir, commands in commands dir
    
    # Create command in source
    create_command_in_source "my-command.md"
    
    # Initialize and add both
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "my-command.md" --local
    
    # Verify correct placement
    assertTrue "Rule should be in rules dir" \
        "[ -f '.cursor/rules/local/rule1.mdc' ]"
    assertTrue "Command should be in commands dir" \
        "[ -f '.cursor/commands/local/my-command.md' ]"
}

# ============================================================================
# SYNC OPERATION TESTS
# ============================================================================

test_sync_creates_commands_directory() {
    # Test: sync creates commands directory if it doesn't exist
    # Expected: .cursor/commands/{mode}/ created during sync
    
    # Create command in source
    create_command_in_source "test-cmd.md"
    
    # Initialize and add command
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    
    # Directory shouldn't exist yet
    assertFalse "Commands dir should not exist before add" \
        "[ -d '.cursor/commands/shared' ]"
    
    cmd_add_rule "test-cmd.md" --commit
    
    # Directory should now exist
    assertTrue "Commands dir should exist after add" \
        "[ -d '.cursor/commands/shared' ]"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
