#!/bin/sh
#
# test_command_entity_detection.test.sh - Command entity detection test suite
#
# Tests the entity type detection logic that distinguishes rules (*.mdc)
# from commands (*.md) based on file extension.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_command_entity_detection.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# ENTITY TYPE DETECTION TESTS
# ============================================================================

test_is_command_returns_true_for_md_files() {
    # Test: is_command() returns true for .md files
    # Expected: "true" for *.md files
    
    result=$(is_command "my-command.md")
    assertEquals "Should detect .md as command" "true" "${result}"
    
    result=$(is_command "niko/plan.md")
    assertEquals "Should detect nested .md as command" "true" "${result}"
}

test_is_command_returns_false_for_mdc_files() {
    # Test: is_command() returns false for .mdc files
    # Expected: "false" for *.mdc files
    
    result=$(is_command "my-rule.mdc")
    assertEquals "Should not detect .mdc as command" "false" "${result}"
    
    result=$(is_command "niko/main.mdc")
    assertEquals "Should not detect nested .mdc as command" "false" "${result}"
}

test_is_command_returns_false_for_other_extensions() {
    # Test: is_command() returns false for other file extensions
    # Expected: "false" for non-.md files
    
    result=$(is_command "readme.txt")
    assertEquals "Should not detect .txt as command" "false" "${result}"
    
    result=$(is_command "config.json")
    assertEquals "Should not detect .json as command" "false" "${result}"
}

test_get_entity_type_rule() {
    # Test: get_entity_type() returns "rule" for .mdc files
    # Expected: "rule" for *.mdc files
    
    result=$(get_entity_type "my-rule.mdc")
    assertEquals "Should return rule for .mdc" "rule" "${result}"
}

test_get_entity_type_command() {
    # Test: get_entity_type() returns "command" for .md files
    # Expected: "command" for *.md files
    
    result=$(get_entity_type "my-command.md")
    assertEquals "Should return command for .md" "command" "${result}"
}

test_get_entity_type_directory_is_rule() {
    # Test: get_entity_type() returns "rule" for directories (rulesets)
    # Expected: "rule" since rulesets are primarily rules
    
    # Create test directory
    mkdir -p "${REPO_DIR}/rulesets/test-ruleset"
    
    result=$(get_entity_type "rulesets/test-ruleset")
    assertEquals "Should return rule for directory" "rule" "${result}"
}

# ============================================================================
# COMMAND TARGET DIRECTORY TESTS
# ============================================================================

test_get_commands_target_dir_local() {
    # Test: get_commands_target_dir() returns local commands directory
    # Expected: TARGET_DIR/.cursor/commands/local for local mode
    
    # Setup local mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    result=$(get_commands_target_dir "local")
    assertEquals "Should return local commands dir" ".cursor/commands/local" "${result}"
}

test_get_commands_target_dir_commit() {
    # Test: get_commands_target_dir() returns commit commands directory
    # Expected: TARGET_DIR/.cursor/commands/shared for commit mode
    
    # Setup commit mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    result=$(get_commands_target_dir "commit")
    assertEquals "Should return commit commands dir" ".cursor/commands/shared" "${result}"
}

test_get_commands_target_dir_global() {
    # Test: get_commands_target_dir() returns global commands directory
    # Expected: ~/.cursor/commands/ai-rizz for global mode
    
    # Setup global test environment
    TEST_HOME="${TEST_DIR}/test_home"
    mkdir -p "${TEST_HOME}/.cursor/commands"
    ORIGINAL_HOME="${HOME}"
    HOME="${TEST_HOME}"
    export HOME
    init_global_paths
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    
    result=$(get_commands_target_dir "global")
    assertEquals "Should return global commands dir" "${GLOBAL_COMMANDS_DIR}" "${result}"
    
    # Cleanup
    HOME="${ORIGINAL_HOME}"
    export HOME
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
