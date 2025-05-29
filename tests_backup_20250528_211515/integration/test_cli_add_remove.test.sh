#!/bin/sh
#
# test_cli_add_remove.test.sh - Integration tests for ai-rizz add/remove commands
#
# Tests the public CLI interface for add and remove commands by executing ai-rizz
# directly and verifying the resulting system state. Validates rule and ruleset
# operations across different modes, lazy initialization behavior, mode migration
# logic, error handling for nonexistent items, and smart mode selection in
# dual-mode environments.
#
# Dependencies: shunit2, integration test utilities
# Usage: sh test_cli_add_remove.test.sh

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

# Test: ai-rizz add rule <rule> in local mode
# Expected: Adds rule to local manifest and syncs to local directory
test_add_rule_to_local_mode() {
    # Initialize local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Init should succeed" 0 $?
    
    # Add rule
    run_ai_rizz add rule rule1
    assertEquals "Add rule should succeed" 0 $?
    
    # Verify rule added to manifest
    assert_manifest_contains "ai-rizz.local.skbd" "rules/rule1.mdc"
    
    # Verify rule deployed to local directory
    assert_rule_deployed ".cursor/rules/local" "rule1"
    
    # Verify commit mode not affected
    assertFalse "Commit manifest should not exist" "[ -f 'ai-rizz.skbd' ]"
    assertFalse "Shared directory should not exist" "[ -d '.cursor/rules/shared' ]"
}

# Test: ai-rizz add rule <rule> in commit mode
# Expected: Adds rule to commit manifest and syncs to shared directory
test_add_rule_to_commit_mode() {
    # Initialize commit mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Init should succeed" 0 $?
    
    # Add rule
    run_ai_rizz add rule rule2
    assertEquals "Add rule should succeed" 0 $?
    
    # Verify rule added to manifest
    assert_manifest_contains "ai-rizz.skbd" "rules/rule2.mdc"
    
    # Verify rule deployed to shared directory
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    
    # Verify local mode not affected
    assertFalse "Local manifest should not exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertFalse "Local directory should not exist" "[ -d '.cursor/rules/local' ]"
}

# Test: ai-rizz add ruleset <ruleset> in local mode
# Expected: Adds ruleset to local manifest and syncs all rules to local directory
test_add_ruleset_to_local_mode() {
    # Initialize local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Init should succeed" 0 $?
    
    # Add ruleset
    run_ai_rizz add ruleset basic
    assertEquals "Add ruleset should succeed" 0 $?
    
    # Verify ruleset added to manifest
    assert_manifest_contains "ai-rizz.local.skbd" "rulesets/basic"
    
    # Verify all rules from ruleset deployed (basic contains rule1 and rule2)
    assert_rule_deployed ".cursor/rules/local" "rule1"
    assert_rule_deployed ".cursor/rules/local" "rule2"
    assert_directory_file_count ".cursor/rules/local" 2
}

# Test: ai-rizz add ruleset <ruleset> in commit mode
# Expected: Adds ruleset to commit manifest and syncs all rules to shared directory
test_add_ruleset_to_commit_mode() {
    # Initialize commit mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Init should succeed" 0 $?
    
    # Add ruleset
    run_ai_rizz add ruleset advanced
    assertEquals "Add ruleset should succeed" 0 $?
    
    # Verify ruleset added to manifest
    assert_manifest_contains "ai-rizz.skbd" "rulesets/advanced"
    
    # Verify all rules from ruleset deployed (advanced contains rule2 and rule3)
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    assert_rule_deployed ".cursor/rules/shared" "rule3"
    assert_directory_file_count ".cursor/rules/shared" 2
}

# Test: ai-rizz remove rule <rule> from local mode
# Expected: Removes rule from local manifest and local directory
test_remove_rule_from_local_mode() {
    # Initialize and add rule
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz add rule rule1
    assertEquals "Setup should succeed" 0 $?
    
    # Verify rule is present
    assert_manifest_contains "ai-rizz.local.skbd" "rules/rule1.mdc"
    assert_rule_deployed ".cursor/rules/local" "rule1"
    
    # Remove rule
    run_ai_rizz remove rule rule1
    assertEquals "Remove rule should succeed" 0 $?
    
    # Verify rule removed from manifest
    assert_manifest_not_contains "ai-rizz.local.skbd" "rules/rule1.mdc"
    
    # Verify rule removed from directory
    assert_rule_not_deployed ".cursor/rules/local" "rule1"
    assert_directory_file_count ".cursor/rules/local" 0
}

# Test: ai-rizz remove rule <rule> from commit mode
# Expected: Removes rule from commit manifest and shared directory
test_remove_rule_from_commit_mode() {
    # Initialize and add rule
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add rule rule2
    assertEquals "Setup should succeed" 0 $?
    
    # Verify rule is present
    assert_manifest_contains "ai-rizz.skbd" "rules/rule2.mdc"
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    
    # Remove rule
    run_ai_rizz remove rule rule2
    assertEquals "Remove rule should succeed" 0 $?
    
    # Verify rule removed from manifest
    assert_manifest_not_contains "ai-rizz.skbd" "rules/rule2.mdc"
    
    # Verify rule removed from directory
    assert_rule_not_deployed ".cursor/rules/shared" "rule2"
    assert_directory_file_count ".cursor/rules/shared" 0
}

# Test: ai-rizz remove ruleset <ruleset> from local mode
# Expected: Removes ruleset from local manifest and all its rules from local directory
test_remove_ruleset_from_local_mode() {
    # Initialize and add ruleset
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz add ruleset basic
    assertEquals "Setup should succeed" 0 $?
    
    # Verify ruleset is present
    assert_manifest_contains "ai-rizz.local.skbd" "rulesets/basic"
    assert_rule_deployed ".cursor/rules/local" "rule1"
    assert_rule_deployed ".cursor/rules/local" "rule2"
    
    # Remove ruleset
    run_ai_rizz remove ruleset basic
    assertEquals "Remove ruleset should succeed" 0 $?
    
    # Verify ruleset removed from manifest
    assert_manifest_not_contains "ai-rizz.local.skbd" "rulesets/basic"
    
    # Verify all rules removed from directory
    assert_rule_not_deployed ".cursor/rules/local" "rule1"
    assert_rule_not_deployed ".cursor/rules/local" "rule2"
    assert_directory_file_count ".cursor/rules/local" 0
}

# Test: ai-rizz remove ruleset <ruleset> from commit mode
# Expected: Removes ruleset from commit manifest and all its rules from shared directory
test_remove_ruleset_from_commit_mode() {
    # Initialize and add ruleset
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add ruleset team
    assertEquals "Setup should succeed" 0 $?
    
    # Verify ruleset is present
    assert_manifest_contains "ai-rizz.skbd" "rulesets/team"
    assert_rule_deployed ".cursor/rules/shared" "rule3"
    assert_rule_deployed ".cursor/rules/shared" "rule4"
    
    # Remove ruleset
    run_ai_rizz remove ruleset team
    assertEquals "Remove ruleset should succeed" 0 $?
    
    # Verify ruleset removed from manifest
    assert_manifest_not_contains "ai-rizz.skbd" "rulesets/team"
    
    # Verify all rules removed from directory
    assert_rule_not_deployed ".cursor/rules/shared" "rule3"
    assert_rule_not_deployed ".cursor/rules/shared" "rule4"
    assert_directory_file_count ".cursor/rules/shared" 0
}

# Test: ai-rizz add rule <nonexistent>
# Expected: Should succeed but show warning and not add to manifest
test_add_nonexistent_rule_fails() {
    # Initialize local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Init should succeed" 0 $?
    
    # Try to add nonexistent rule
    local output
    output=$(run_ai_rizz add rule nonexistent --local 2>&1)
    local exit_code=$?
    
    # Command should succeed but show warning
    assertEquals "Add nonexistent rule should succeed" 0 $exit_code
    assert_output_contains "$output" "Warning\|not found"
    
    # Should not add anything to manifest
    assert_manifest_not_contains "ai-rizz.local.skbd" "rules/nonexistent.mdc"
    
    # Should not create any files
    assert_directory_file_count ".cursor/rules/local" 0
}

# Test: ai-rizz remove rule <nonexistent>
# Expected: Should warn but not fail
test_remove_nonexistent_rule_warns() {
    # Initialize local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Init should succeed" 0 $?
    
    # Try to remove nonexistent rule
    local output
    output=$(run_ai_rizz remove rule nonexistent 2>&1)
    local exit_code=$?
    
    # Command should succeed (graceful handling)
    assertEquals "Remove nonexistent should not fail" 0 $exit_code
    
    # Should show warning about not found
    assert_output_contains "$output" "not found\|Warning"
}

# Test: ai-rizz add rule with lazy initialization
# Expected: Should initialize missing mode and add rule
test_add_rule_with_lazy_initialization() {
    # Initialize only local mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Local init should succeed" 0 $?
    
    # Add rule to commit mode (should trigger lazy initialization)
    run_ai_rizz add rule rule3 --commit
    assertEquals "Add to commit mode should succeed" 0 $?
    
    # Verify both modes now exist
    assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
    assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
    assertTrue "Local directory should exist" "[ -d '.cursor/rules/local' ]"
    assertTrue "Shared directory should exist" "[ -d '.cursor/rules/shared' ]"
    
    # Verify rule added to commit mode
    assert_manifest_contains "ai-rizz.skbd" "rules/rule3.mdc"
    assert_rule_deployed ".cursor/rules/shared" "rule3"
    
    # Verify local mode unchanged
    assert_directory_file_count ".cursor/rules/local" 0
}

# Test: ai-rizz add rule without mode flag in dual mode
# Expected: Should require mode selection or use smart default
test_add_rule_dual_mode_requires_mode() {
    # Initialize both modes
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Dual mode init should succeed" 0 $?
    
    # Try to add rule without mode flag
    local output
    output=$(run_ai_rizz add rule rule4 2>&1 || echo "COMMAND_FAILED")
    
    # Should either fail with mode requirement or succeed with smart default
    if echo "$output" | grep -q "COMMAND_FAILED"; then
        # Command failed - should show mode selection error
        assert_output_contains "$output" "mode\|local\|commit"
    else
        # Command succeeded - should have used smart default
        # Rule should be in one of the modes
        local in_local in_commit
        in_local=$(grep -q "rules/rule4.mdc" ai-rizz.local.skbd 2>/dev/null && echo "true" || echo "false")
        in_commit=$(grep -q "rules/rule4.mdc" ai-rizz.skbd 2>/dev/null && echo "true" || echo "false")
        
        # Should be in exactly one mode
        if [ "$in_local" = "true" ] && [ "$in_commit" = "false" ]; then
            assert_rule_deployed ".cursor/rules/local" "rule4"
        elif [ "$in_local" = "false" ] && [ "$in_commit" = "true" ]; then
            assert_rule_deployed ".cursor/rules/shared" "rule4"
        else
            fail "Rule should be in exactly one mode"
        fi
    fi
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 