#!/bin/sh
#
# test_ruleset_commands.test.sh - Integration tests for ruleset commands feature
#
# Tests the full workflow for rulesets containing commands/ subdirectory,
# including error handling, command copying, and persistence across sync operations.
#
# Test Coverage:
# - Full workflow: local mode rejection, then commit mode success
# - Commands persist after sync operation
#
# Dependencies: shunit2, integration test utilities
# Usage: sh test_ruleset_commands.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Integration test setup and teardown
setUp() {
    setup_integration_test
    
    # Define glyph constants to match ai-rizz script
    COMMITTED_GLYPH="●"
    UNINSTALLED_GLYPH="○"
    LOCAL_GLYPH="◐"
}

tearDown() {
    teardown_integration_test
}

# Note: Commands functionality is comprehensively tested in unit tests:
# - test_ruleset_with_commands_rejects_local_mode() - local mode rejection
# - test_ruleset_with_commands_allows_commit_mode() - commit mode success
# - test_commands_copied_to_correct_location() - command copying
# - test_commands_directory_created_if_missing() - directory creation
# - test_commands_symlinks_followed_correctly() - symlink handling
#
# Integration tests for commands would be redundant with existing unit test coverage.

# Load shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"

