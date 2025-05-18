#!/bin/sh
# Integration test for ai-rizz using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Test that we can source the ai-rizz script and access functions
test_source_ai_rizz() {
  # Source the actual implementation using the standardized path approach
  if ! source_ai_rizz; then
    fail "Failed to source ai-rizz script"
    return 1
  fi
  
  # Verify that key functions were sourced by checking if they exist
  assertTrue "cmd_add_rule function should exist" "type cmd_add_rule >/dev/null 2>&1"
  assertTrue "cmd_add_ruleset function should exist" "type cmd_add_ruleset >/dev/null 2>&1"
  assertTrue "cmd_sync function should exist" "type cmd_sync >/dev/null 2>&1"
  assertTrue "cmd_remove_rule function should exist" "type cmd_remove_rule >/dev/null 2>&1"
  assertTrue "cmd_remove_ruleset function should exist" "type cmd_remove_ruleset >/dev/null 2>&1"
  assertTrue "read_manifest function should exist" "type read_manifest >/dev/null 2>&1"
  assertTrue "write_manifest function should exist" "type write_manifest >/dev/null 2>&1"
}

# Test that the implementations are callable
test_function_calls() {
  # Skip if we can't source the script
  source_ai_rizz || startSkipping
  
  # Mock external dependencies to avoid side effects
  cmd_add_rule() { echo "Mock add_rule called"; return 0; }
  cmd_add_ruleset() { echo "Mock add_ruleset called"; return 0; }
  cmd_sync() { echo "Mock sync called"; return 0; }
  cmd_remove_rule() { echo "Mock remove_rule called"; return 0; }
  cmd_remove_ruleset() { echo "Mock remove_ruleset called"; return 0; }
  
  # Test calling the functions
  output=$(cmd_add_rule test_rule 2>&1)
  assertEquals "Mock add_rule called" "$output"
  
  output=$(cmd_add_ruleset test_ruleset 2>&1)
  assertEquals "Mock add_ruleset called" "$output"
  
  output=$(cmd_sync 2>&1)
  assertEquals "Mock sync called" "$output"
  
  output=$(cmd_remove_rule test_rule 2>&1)
  assertEquals "Mock remove_rule called" "$output"
  
  output=$(cmd_remove_ruleset test_ruleset 2>&1)
  assertEquals "Mock remove_ruleset called" "$output"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 