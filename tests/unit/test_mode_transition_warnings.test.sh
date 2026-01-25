#!/bin/sh
#
# test_mode_transition_warnings.test.sh - Mode transition warning test suite
#
# Tests that warnings are displayed when entities are added to a different
# mode than they currently exist in, helping users understand scope changes.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_mode_transition_warnings.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST SETUP
# ============================================================================

create_test_rule() {
    ctr_rule_name="${1}"
    mkdir -p "${REPO_DIR}/rules"
    cat > "${REPO_DIR}/rules/${ctr_rule_name}" << 'EOF'
# Test Rule
This is a test rule.
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
# get_entity_installed_mode() TESTS
# ============================================================================

test_get_entity_installed_mode_returns_none_for_new_entity() {
    # Test: New entity that hasn't been added should return "none"
    # Expected: Returns "none"
    
    create_test_rule "new-rule.mdc"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    
    result=$(get_entity_installed_mode "rules/new-rule.mdc")
    
    assertEquals "New entity should return 'none'" "none" "$result"
}

test_get_entity_installed_mode_returns_commit_for_committed_rule() {
    # Test: Rule in commit mode should return "commit"
    # Expected: Returns "commit"
    
    create_test_rule "committed-rule.mdc"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "committed-rule.mdc" --commit
    
    result=$(get_entity_installed_mode "rules/committed-rule.mdc")
    
    assertEquals "Committed rule should return 'commit'" "commit" "$result"
}

test_get_entity_installed_mode_returns_local_for_local_rule() {
    # Test: Rule in local mode should return "local"
    # Expected: Returns "local"
    
    create_test_rule "local-rule.mdc"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "local-rule.mdc" --local
    
    result=$(get_entity_installed_mode "rules/local-rule.mdc")
    
    assertEquals "Local rule should return 'local'" "local" "$result"
}

test_get_entity_installed_mode_returns_global_for_global_rule() {
    # Test: Rule in global mode should return "global"
    # Expected: Returns "global"
    
    setup_global_test_environment
    create_test_rule "global-rule.mdc"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "global-rule.mdc" --global
    
    result=$(get_entity_installed_mode "rules/global-rule.mdc")
    
    assertEquals "Global rule should return 'global'" "global" "$result"
    
    teardown_global_test_environment
}

# ============================================================================
# MODE TRANSITION WARNING TESTS
# ============================================================================

test_warning_global_to_commit() {
    # Test: Adding entity from global mode to commit mode should warn
    # Expected: Warning message about scope change
    
    setup_global_test_environment
    create_test_rule "scope-rule.mdc"
    
    # First add to global
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "scope-rule.mdc" --global
    
    # Now init commit mode and add to commit - should warn
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    output=$(cmd_add_rule "scope-rule.mdc" --commit 2>&1)
    
    # Check for warning message
    echo "$output" | grep -qi "warning" && \
    echo "$output" | grep -qi "global.*commit" || \
        fail "Should warn about global to commit transition: $output"
    
    teardown_global_test_environment
}

test_warning_global_to_local() {
    # Test: Adding entity from global mode to local mode should warn
    # Expected: Warning message about scope change
    
    setup_global_test_environment
    create_test_rule "scope-rule.mdc"
    
    # First add to global
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "scope-rule.mdc" --global
    
    # Now init local mode and add to local - should warn
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    output=$(cmd_add_rule "scope-rule.mdc" --local 2>&1)
    
    # Check for warning message
    echo "$output" | grep -qi "warning" && \
    echo "$output" | grep -qi "global.*local" || \
        fail "Should warn about global to local transition: $output"
    
    teardown_global_test_environment
}

test_warning_commit_to_global() {
    # Test: Adding entity from commit mode to global mode should warn
    # Expected: Warning message about removing from repo for other devs
    
    setup_global_test_environment
    create_test_rule "scope-rule.mdc"
    
    # First add to commit
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "scope-rule.mdc" --commit
    
    # Now add to global - should warn
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    output=$(cmd_add_rule "scope-rule.mdc" --global 2>&1)
    
    # Check for warning message
    echo "$output" | grep -qi "warning" && \
    echo "$output" | grep -qi "commit.*global" || \
        fail "Should warn about commit to global transition: $output"
    
    teardown_global_test_environment
}

test_warning_local_to_global() {
    # Test: Adding entity from local mode to global mode should warn
    # Expected: Warning message about scope change
    
    setup_global_test_environment
    create_test_rule "scope-rule.mdc"
    
    # First add to local
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --local
    cmd_add_rule "scope-rule.mdc" --local
    
    # Now add to global - should warn
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    output=$(cmd_add_rule "scope-rule.mdc" --global 2>&1)
    
    # Check for warning message
    echo "$output" | grep -qi "warning" && \
    echo "$output" | grep -qi "local.*global" || \
        fail "Should warn about local to global transition: $output"
    
    teardown_global_test_environment
}

test_no_warning_for_new_entity() {
    # Test: Adding a new entity (not in any mode) should NOT warn
    # Expected: No warning message
    
    create_test_rule "brand-new.mdc"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    output=$(cmd_add_rule "brand-new.mdc" --commit 2>&1)
    
    # Should not contain warning
    if echo "$output" | grep -qi "warning"; then
        fail "Should not warn when adding new entity: $output"
    fi
}

test_no_warning_for_same_mode() {
    # Test: Re-adding entity to same mode should NOT warn
    # Expected: No warning message
    
    create_test_rule "existing-rule.mdc"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    cmd_add_rule "existing-rule.mdc" --commit
    
    # Add again to same mode
    output=$(cmd_add_rule "existing-rule.mdc" --commit 2>&1)
    
    # Should not contain warning about transition
    if echo "$output" | grep -qi "warning.*transition"; then
        fail "Should not warn about mode transition when adding to same mode: $output"
    fi
}

# ============================================================================
# RULESET MODE TRANSITION WARNING TESTS
# ============================================================================

create_test_ruleset() {
    ctrs_ruleset_name="${1}"
    mkdir -p "${REPO_DIR}/rulesets/${ctrs_ruleset_name}"
    cat > "${REPO_DIR}/rulesets/${ctrs_ruleset_name}/main.mdc" << 'EOF'
# Main Rule
This is the main rule.
EOF
}

test_ruleset_warning_global_to_commit() {
    # Test: Adding ruleset from global to commit should warn
    # Expected: Warning message
    
    setup_global_test_environment
    create_test_ruleset "my-ruleset"
    
    # First add to global
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_ruleset "my-ruleset" --global
    
    # Now add to commit - should warn
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    output=$(cmd_add_ruleset "my-ruleset" --commit 2>&1)
    
    echo "$output" | grep -qi "warning" && \
    echo "$output" | grep -qi "global.*commit" || \
        fail "Should warn about ruleset global to commit transition: $output"
    
    teardown_global_test_environment
}

test_ruleset_no_warning_for_new() {
    # Test: Adding new ruleset should NOT warn
    # Expected: No warning
    
    create_test_ruleset "brand-new-ruleset"
    
    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --commit
    output=$(cmd_add_ruleset "brand-new-ruleset" --commit 2>&1)
    
    if echo "$output" | grep -qi "warning.*transition"; then
        fail "Should not warn when adding new ruleset: $output"
    fi
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
