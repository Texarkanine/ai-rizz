#!/bin/sh
#
# test_help_and_usage.test.sh - Integration tests for help and usage display
#
# Tests the public CLI interface for help command and usage message display by
# executing ai-rizz directly and verifying that help content is shown. Validates
# that help is accessible and informative without locking into specific text
# formats to avoid test brittleness.
#
# Dependencies: shunit2, integration test utilities  
# Usage: sh test_help_and_usage.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Integration test setup and teardown
setUp() {
    setup_integration_test
}

tearDown() {
    teardown_integration_test
}

# Test: ai-rizz help
# Expected: Shows help content with commands and options
test_help_command_shows_content() {
    # Execute help command
    output=$(run_ai_rizz help 2>&1)
    exit_code=$?
    
    # Should succeed
    assertEquals "Help command should succeed" 0 $exit_code
    
    # Should produce some output
    assertNotNull "Help should produce output" "$output"
    
    # Should contain basic help content (very loose checks)
    assert_output_contains "$output" "Usage\|usage\|USAGE"
    assert_output_contains "$output" "command\|Command\|COMMAND"
}

# Test: ai-rizz with no arguments  
# Expected: Shows usage information (may succeed or fail, but should show helpful content)
test_no_arguments_shows_usage() {
    # Execute with no arguments
    output=$(run_ai_rizz 2>&1)
    exit_code=$?
    
    # Should produce output regardless of exit code
    assertNotNull "No arguments should produce output" "$output"
    
    # Should contain usage information
    assert_output_contains "$output" "Usage\|usage\|USAGE\|help\|Help\|HELP"
}

# Test: ai-rizz invalid-command
# Expected: Shows error and usage information, should fail with non-zero exit
test_invalid_command_shows_help() {
    # Execute with invalid command
    output=$(run_ai_rizz invalid-command 2>&1)
    exit_code=$?
    
    # Should fail (non-zero exit code)
    assertNotEquals "Invalid command should fail" 0 $exit_code
    
    # Should produce output
    assertNotNull "Invalid command should produce output" "$output"
    
    # Should indicate error or unknown command
    assert_output_contains "$output" "Unknown\|unknown\|Invalid\|invalid\|Error\|error"
    # Should also suggest help
    assert_output_contains "$output" "help\|Help"
}

# Test: ai-rizz --help (unsupported flag)
# Expected: Shows error message suggesting correct help usage, should fail
test_help_flag_shows_error() {
    # Execute with --help flag (which is not supported)
    output=$(run_ai_rizz --help 2>&1)
    exit_code=$?
    
    # Should fail (--help is not a supported flag)
    assertNotEquals "Unsupported --help flag should fail" 0 $exit_code
    
    # Should produce output
    assertNotNull "Help flag should produce output" "$output"
    
    # Should indicate error and suggest correct help command
    assert_output_contains "$output" "Unknown\|unknown\|Error\|error"
    assert_output_contains "$output" "help"
}

# Test: ai-rizz -h (unsupported flag)
# Expected: Shows error message suggesting correct help usage, should fail
test_short_help_flag_shows_error() {
    # Execute with -h flag (which is not supported)
    output=$(run_ai_rizz -h 2>&1)
    exit_code=$?
    
    # Should fail (-h is not a supported flag)
    assertNotEquals "Unsupported -h flag should fail" 0 $exit_code
    
    # Should produce output
    assertNotNull "Short help flag should produce output" "$output"
    
    # Should indicate error and suggest correct help command
    assert_output_contains "$output" "Unknown\|unknown\|Error\|error"
    assert_output_contains "$output" "help"
}

# Test: Help output contains key commands
# Expected: Help mentions main ai-rizz commands
test_help_mentions_key_commands() {
    # Get help output
    output=$(run_ai_rizz help 2>&1)
    exit_code=$?
    
    # Help command should succeed
    assertEquals "Help command should succeed" 0 $exit_code
    
    # Should mention some key commands (loose check for at least one)
    if echo "$output" | grep -q "init\|add\|remove\|list\|sync\|deinit"; then
        : # Test passes - found at least one expected command
    else
        fail "Help should mention at least one key command (init, add, remove, list, sync, deinit)"
    fi
}

# Test: Help is accessible from any directory
# Expected: Help works regardless of current directory
test_help_works_from_any_directory() {
    # Create a subdirectory and run help from there
    mkdir -p subdir
    cd subdir || fail "Failed to change to subdirectory"
    
    # Execute help command from subdirectory
    output=$(run_ai_rizz help 2>&1)
    exit_code=$?
    
    # Should succeed and show help
    assertEquals "Help should work from subdirectory" 0 $exit_code
    assertNotNull "Help should produce output from subdirectory" "$output"
    assert_output_contains "$output" "Usage\|usage\|command\|Command"
    
    # Return to test directory
    cd .. || fail "Failed to return to test directory"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 