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
    ccis_command_name="${1}"
    mkdir -p "${REPO_DIR}/rules"
    cat > "${REPO_DIR}/rules/${ccis_command_name}" << EOF
# Test Command: ${ccis_command_name}
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
    tcstgcd_test_home="${TEST_DIR}/test_home"
    mkdir -p "${tcstgcd_test_home}/.cursor/commands"
    mkdir -p "${tcstgcd_test_home}/.cursor/rules"
    tcstgcd_original_home="${HOME}"
    HOME="${tcstgcd_test_home}"
    export HOME
    init_global_paths
    
    # Ensure cleanup happens even if test fails early
    tcstgcd_cleanup() {
        HOME="${tcstgcd_original_home}"
        export HOME
        init_global_paths
    }
    trap 'tcstgcd_cleanup' RETURN
    
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

# ============================================================================
# EXTENSIONLESS ADD/REMOVE TESTS
# ============================================================================

test_extensionless_add_finds_command() {
    # Test: 'add rule foo' finds foo.md when foo.mdc doesn't exist
    # Expected: Successfully adds rules/foo.md
    
    # Create ONLY a command (no .mdc version)
    create_command_in_source "only-cmd.md"
    
    # Initialize
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    
    # Add without extension - should find .md
    output=$(cmd_add_rule "only-cmd" --local 2>&1)
    
    # Should succeed and mention .md
    echo "$output" | grep -q "rules/only-cmd.md" || fail "Should add only-cmd.md: $output"
    assertTrue "Command should be in commands dir" \
        "[ -f '.cursor/commands/local/only-cmd.md' ]"
}

test_extensionless_add_prefers_rule_over_command() {
    # Test: When both foo.mdc and foo.md exist, 'add rule foo' prefers .mdc
    # Expected: Adds rules/foo.mdc, not rules/foo.md
    
    # Create both versions
    echo "Rule content" > "${REPO_DIR}/rules/both.mdc"
    create_command_in_source "both.md"
    
    # Initialize
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    
    # Add without extension - should prefer .mdc
    output=$(cmd_add_rule "both" --local 2>&1)
    
    echo "$output" | grep -q "rules/both.mdc" || fail "Should prefer .mdc: $output"
    assertTrue "Rule should be in rules dir" \
        "[ -f '.cursor/rules/local/both.mdc' ]"
}

test_extensionless_remove_finds_command() {
    # Test: 'remove rule foo' finds foo.md when foo.mdc doesn't exist
    # Expected: Successfully removes rules/foo.md from manifest
    
    # Create ONLY a command
    create_command_in_source "removable-cmd.md"
    
    # Initialize and add
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "removable-cmd.md" --local
    
    # Verify it's there
    assertTrue "Command should exist before remove" \
        "[ -f '.cursor/commands/local/removable-cmd.md' ]"
    
    # Remove without extension - should find .md
    output=$(cmd_remove_rule "removable-cmd" --local 2>&1)
    
    echo "$output" | grep -q "rules/removable-cmd.md" || fail "Should remove .md: $output"
}

# ============================================================================
# COMMAND REMOVAL FILE CLEANUP TESTS
# ============================================================================

test_remove_command_deletes_file_local_mode() {
    # Test: Removing a command also deletes the file, not just manifest entry
    # Expected: File is deleted from .cursor/commands/local/
    
    # Create command
    create_command_in_source "delete-me.md"
    
    # Initialize and add
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "delete-me.md" --local
    
    # Verify file exists
    assertTrue "Command file should exist before remove" \
        "[ -f '.cursor/commands/local/delete-me.md' ]"
    
    # Remove
    cmd_remove_rule "delete-me.md" --local
    
    # File should be deleted
    assertFalse "Command file should be deleted after remove" \
        "[ -f '.cursor/commands/local/delete-me.md' ]"
}

test_remove_command_deletes_file_commit_mode() {
    # Test: Removing a command in commit mode deletes the file
    # Expected: File is deleted from .cursor/commands/shared/
    
    # Create command
    create_command_in_source "delete-commit.md"
    
    # Initialize and add
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "delete-commit.md" --commit
    
    # Verify file exists
    assertTrue "Command file should exist before remove" \
        "[ -f '.cursor/commands/shared/delete-commit.md' ]"
    
    # Remove
    cmd_remove_rule "delete-commit.md" --commit
    
    # File should be deleted
    assertFalse "Command file should be deleted after remove" \
        "[ -f '.cursor/commands/shared/delete-commit.md' ]"
}

test_remove_command_deletes_file_global_mode() {
    # Test: Removing a command in global mode deletes the file
    # Expected: File is deleted from ~/.cursor/commands/ai-rizz/
    # BUG: This was failing - file persisted after remove
    
    # Setup global test environment
    trcdfgm_test_home="${TEST_DIR}/test_home"
    mkdir -p "${trcdfgm_test_home}/.cursor/commands"
    mkdir -p "${trcdfgm_test_home}/.cursor/rules"
    trcdfgm_original_home="${HOME}"
    HOME="${trcdfgm_test_home}"
    export HOME
    init_global_paths
    
    # Ensure cleanup happens even if test fails early
    trcdfgm_cleanup() {
        HOME="${trcdfgm_original_home}"
        export HOME
        init_global_paths
    }
    trap 'trcdfgm_cleanup' RETURN
    
    # Create command
    create_command_in_source "delete-global.md"
    
    # Initialize and add
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "delete-global.md" --global
    
    # Verify file exists
    assertTrue "Command file should exist before remove" \
        "[ -f '${GLOBAL_COMMANDS_DIR}/delete-global.md' ]"
    
    # Remove using --global flag
    cmd_remove_rule "delete-global.md" --global
    
    # File should be deleted
    assertFalse "Command file should be deleted after remove" \
        "[ -f '${GLOBAL_COMMANDS_DIR}/delete-global.md' ]"
}

test_remove_rule_deletes_file() {
    # Test: Removing a rule also deletes the file
    # Expected: File is deleted from .cursor/rules/local/
    
    # Initialize and add
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Verify file exists
    assertTrue "Rule file should exist before remove" \
        "[ -f '.cursor/rules/local/rule1.mdc' ]"
    
    # Remove
    cmd_remove_rule "rule1.mdc" --local
    
    # File should be deleted
    assertFalse "Rule file should be deleted after remove" \
        "[ -f '.cursor/rules/local/rule1.mdc' ]"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
