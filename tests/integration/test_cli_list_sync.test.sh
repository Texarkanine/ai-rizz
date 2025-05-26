#!/bin/sh
#
# test_cli_list_sync.test.sh - Integration tests for ai-rizz list/sync commands
#
# Tests the public CLI interface for list and sync commands by executing ai-rizz
# directly and verifying the resulting system state. Validates glyph display
# behavior across different mode configurations, sync operations for target
# directory updates, repository failure handling, and conflict resolution
# logic with commit-wins policy.
#
# Dependencies: shunit2, integration test utilities
# Usage: sh test_cli_list_sync.test.sh

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

# Test: ai-rizz list in local-only mode
# Expected: Shows correct glyphs for local-only state (○ and ◐)
test_list_shows_correct_glyphs_local_only() {
    # Initialize local mode and add some rules
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz add rule rule1 --local
    run_ai_rizz add ruleset basic --local
    assertEquals "Setup should succeed" 0 $?
    
    # Run list command
    local output
    output=$(run_ai_rizz list 2>&1)
    assertEquals "List should succeed" 0 $?
    
    # Should show local glyph for installed items
    assert_output_contains "$output" "$LOCAL_GLYPH.*rule1.mdc\|rule1.mdc.*$LOCAL_GLYPH"
    assert_output_contains "$output" "$LOCAL_GLYPH.*basic\|basic.*$LOCAL_GLYPH"
    
    # Should show uninstalled glyph for non-installed items
    assert_output_contains "$output" "$UNINSTALLED_GLYPH.*rule3.mdc\|rule3.mdc.*$UNINSTALLED_GLYPH"
    assert_output_contains "$output" "$UNINSTALLED_GLYPH.*advanced\|advanced.*$UNINSTALLED_GLYPH"
    
    # Should NOT show committed glyph since no commit mode
    assert_output_not_contains "$output" "$COMMITTED_GLYPH"
}

# Test: ai-rizz list in commit-only mode
# Expected: Shows correct glyphs for commit-only state (○ and ●)
test_list_shows_correct_glyphs_commit_only() {
    # Initialize commit mode and add some rules
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add rule rule2 --commit
    run_ai_rizz add ruleset advanced --commit
    assertEquals "Setup should succeed" 0 $?
    
    # Run list command
    local output
    output=$(run_ai_rizz list 2>&1)
    assertEquals "List should succeed" 0 $?
    
    # Should show committed glyph for installed items
    assert_output_contains "$output" "$COMMITTED_GLYPH.*rule2.mdc\|rule2.mdc.*$COMMITTED_GLYPH"
    assert_output_contains "$output" "$COMMITTED_GLYPH.*advanced\|advanced.*$COMMITTED_GLYPH"
    
    # Should show uninstalled glyph for non-installed items
    assert_output_contains "$output" "$UNINSTALLED_GLYPH.*rule1.mdc\|rule1.mdc.*$UNINSTALLED_GLYPH"
    assert_output_contains "$output" "$UNINSTALLED_GLYPH.*basic\|basic.*$UNINSTALLED_GLYPH"
    
    # Should NOT show local glyph since no local mode
    assert_output_not_contains "$output" "$LOCAL_GLYPH"
}

# Test: ai-rizz list in dual mode
# Expected: Shows all three glyphs (○, ◐, ●) based on installation state
test_list_shows_correct_glyphs_dual_mode() {
    # Initialize both modes
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    
    # Add different rules to different modes
    run_ai_rizz add rule rule1 --local      # Should show ◐
    run_ai_rizz add rule rule2 --commit     # Should show ●
    # rule3 and rule4 not added - should show ○
    run_ai_rizz add ruleset basic --local   # Should show ◐
    run_ai_rizz add ruleset team --commit   # Should show ●
    # advanced ruleset not added - should show ○
    assertEquals "Setup should succeed" 0 $?
    
    # Run list command
    local output
    output=$(run_ai_rizz list 2>&1)
    assertEquals "List should succeed" 0 $?
    
    # Should show all three glyph types
    assert_output_contains "$output" "$LOCAL_GLYPH.*rule1.mdc\|rule1.mdc.*$LOCAL_GLYPH"      # Local only (from basic)
    assert_output_contains "$output" "$COMMITTED_GLYPH.*rule2.mdc\|rule2.mdc.*$COMMITTED_GLYPH"      # Committed (migrated)
    assert_output_contains "$output" "$COMMITTED_GLYPH.*rule3.mdc\|rule3.mdc.*$COMMITTED_GLYPH"      # Committed (from team)
    assert_output_contains "$output" "$COMMITTED_GLYPH.*rule4.mdc\|rule4.mdc.*$COMMITTED_GLYPH"      # Committed (from team)
    assert_output_contains "$output" "$LOCAL_GLYPH.*basic\|basic.*$LOCAL_GLYPH"     # Local only
    assert_output_contains "$output" "$COMMITTED_GLYPH.*team\|team.*$COMMITTED_GLYPH"       # Committed
    assert_output_contains "$output" "$UNINSTALLED_GLYPH.*advanced\|advanced.*$UNINSTALLED_GLYPH" # Uninstalled
}

# Test: ai-rizz sync updates target directories
# Expected: Sync command updates both local and shared directories correctly
test_sync_updates_target_directories() {
    # Initialize dual mode and add rules
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    run_ai_rizz add rule rule1 --local
    run_ai_rizz add rule rule2 --commit
    assertEquals "Setup should succeed" 0 $?
    
    # Verify initial state
    assert_rule_deployed ".cursor/rules/local" "rule1"
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    
    # Manually remove deployed files to simulate out-of-sync state
    rm -f .cursor/rules/local/rule1.mdc
    rm -f .cursor/rules/shared/rule2.mdc
    
    # Verify files are gone
    assert_rule_not_deployed ".cursor/rules/local" "rule1"
    assert_rule_not_deployed ".cursor/rules/shared" "rule2"
    
    # Run sync command
    run_ai_rizz sync
    assertEquals "Sync should succeed" 0 $?
    
    # Verify files are restored
    assert_rule_deployed ".cursor/rules/local" "rule1"
    assert_rule_deployed ".cursor/rules/shared" "rule2"
}

# Test: ai-rizz sync handles repository failures gracefully
# Expected: Sync should handle network/repository issues without crashing
test_sync_handles_repository_failures() {
    # Initialize with valid repository first
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    assertEquals "Init should succeed" 0 $?
    
    # Manually corrupt the manifest to point to invalid repository
    echo "invalid://nonexistent	.cursor/rules" > ai-rizz.local.inf
    
    # Remove repository cache to force fresh clone attempt with invalid URL
    # The repository cache is at ~/.config/ai-rizz/repos/{project_name}/repo
    # where project_name is the basename of the git root directory
    project_name=$(basename "$(pwd)")
    rm -rf ~/.config/ai-rizz/repos/"$project_name"
    
    # Try to sync - should fail gracefully
    local output
    output=$(run_ai_rizz sync 2>&1 || echo "SYNC_FAILED")
    
    # Should fail but not crash
    assert_output_contains "$output" "SYNC_FAILED\|Warning\|Failed"
    
    # Should not create any deployed files
    assert_directory_file_count ".cursor/rules/local" 0
}

# Test: ai-rizz sync resolves conflicts with commit wins policy
# Expected: When same rule exists in both modes, commit mode wins
test_sync_resolves_conflicts_commit_wins() {
    # Initialize dual mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Dual mode init should succeed" 0 $?
    
    # Add same rule to both modes (this creates a conflict)
    run_ai_rizz add rule rule2 --local
    run_ai_rizz add rule rule2 --commit
    assertEquals "Adding conflicting rules should succeed" 0 $?
    
    # Note: The second add should have migrated the rule from local to commit
    # So we expect the rule to be in commit mode only after the second add
    
    # Verify the rule was migrated to commit mode
    assert_manifest_not_contains "ai-rizz.local.inf" "rules/rule2.mdc"
    assert_manifest_contains "ai-rizz.inf" "rules/rule2.mdc"
    
    # Rule should be deployed to shared directory
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    
    # Rule should NOT be deployed to local directory
    assert_rule_not_deployed ".cursor/rules/local" "rule2"
}

# Test: ai-rizz sync without initialization
# Expected: Should show appropriate error message
test_sync_without_initialization() {
    # Try to sync without any initialization
    local output
    output=$(run_ai_rizz sync 2>&1 || echo "SYNC_FAILED")
    
    # Should fail with helpful error
    assert_output_contains "$output" "SYNC_FAILED\|No ai-rizz configuration\|init"
}

# Test: ai-rizz list without initialization
# Expected: Should show appropriate error message
test_list_without_initialization() {
    # Try to list without any initialization
    local output
    output=$(run_ai_rizz list 2>&1 || echo "LIST_FAILED")
    
    # Should fail with helpful error
    assert_output_contains "$output" "LIST_FAILED\|No ai-rizz configuration\|init"
}

# Test: ai-rizz sync with partial ruleset conflicts
# Expected: Individual rules from rulesets should be handled correctly
test_sync_partial_ruleset_conflicts() {
    # Initialize dual mode
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --local
    run_ai_rizz init "file://$MOCK_REPO_DIR" -d .cursor/rules --commit
    assertEquals "Dual mode init should succeed" 0 $?
    
    # Add ruleset to local mode (contains rule1 and rule2)
    run_ai_rizz add ruleset basic --local
    
    # Add individual rule to commit mode that conflicts with ruleset
    run_ai_rizz add rule rule2 --commit
    assertEquals "Adding conflicting rule should succeed" 0 $?
    
    # Run sync to resolve conflicts
    run_ai_rizz sync
    assertEquals "Sync should succeed" 0 $?
    
    # rule2 should be in shared directory (commit wins)
    assert_rule_deployed ".cursor/rules/shared" "rule2"
    assert_rule_not_deployed ".cursor/rules/local" "rule2"
    
    # rule1 should remain in local directory (no conflict)
    assert_rule_deployed ".cursor/rules/local" "rule1"
    assert_rule_not_deployed ".cursor/rules/shared" "rule1"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 