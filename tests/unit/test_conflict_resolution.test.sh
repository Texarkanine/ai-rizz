#!/bin/sh
# Tests for mode migration and conflict resolution using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_migrate_rule_local_to_commit() {
    # Setup: Rule in local mode
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    
    # Test: Add same rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Rule moved from local to commit
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Verify manifests updated
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rule1.mdc" && fail "Rule should be removed from local manifest"
    
    commit_content=$(cat "$COMMIT_MANIFEST_FILE")
    echo "$commit_content" | grep -q "rule1.mdc" || fail "Rule should be in commit manifest"
}

test_migrate_rule_commit_to_local() {
    # Setup: Rule in commit mode
    cmd_init "$SOURCE_REPO" --commit
    cmd_add_rule "rule1.mdc" --commit
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Test: Add same rule to local mode
    cmd_add_rule "rule1.mdc" --local
    
    # Expected: Rule moved from commit to local
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_migrate_ruleset_with_all_rules() {
    # Setup: Ruleset in local mode
    cmd_init "$SOURCE_REPO" --local
    cmd_add_ruleset "ruleset1" --local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    
    # Test: Add same ruleset to commit mode
    cmd_add_ruleset "ruleset1" --commit
    
    # Expected: All rules moved to commit mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

test_migrate_preserves_other_rules() {
    # Setup: Multiple rules in local mode
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --local
    cmd_add_rule "rule3.mdc" --local
    
    # Test: Migrate only one rule to commit mode
    cmd_add_rule "rule2.mdc" --commit
    
    # Expected: Only rule2 migrated, others remain local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule3.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
}

test_resolve_duplicate_entries_commit_wins() {
    # Setup: Manually create duplicate entries (simulates user error)
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule1.mdc" --commit  # Should migrate, but manually add back to local
    
    # Manually add duplicate entry to simulate user editing error
    echo "rules/rule1.mdc" >> "$LOCAL_MANIFEST_FILE"
    
    # Test: Sync should resolve conflict
    cmd_sync
    
    # Expected: Commit mode wins, local entry silently removed
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rule1.mdc" && fail "Duplicate should be removed from local"
}

test_migrate_updates_git_tracking() {
    # Setup: Rule in local mode (git-ignored)
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Initialize git tracking to verify changes
    git add .git/info/exclude >/dev/null 2>&1
    git commit -m "Initial local setup" >/dev/null 2>&1
    
    # Test: Migrate to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: File should now be tracked by git
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # The file should be eligible for git tracking (not ignored)
    git check-ignore "$TARGET_DIR/$SHARED_DIR/rule1.mdc" 2>/dev/null && fail "File should not be git-ignored after migration"
}

test_migrate_complex_ruleset_scenario() {
    # Setup: Complex scenario with overlapping rulesets
    cmd_init "$SOURCE_REPO" --local
    cmd_add_ruleset "ruleset1" --local  # Contains rule1, rule2
    cmd_add_rule "rule3.mdc" --local    # Individual rule
    
    # Test: Migrate ruleset that has some overlap
    cmd_add_ruleset "ruleset2" --commit  # Contains rule2, rule3
    
    # Expected: All affected rules moved to commit mode
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule3.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
    
    # Rule1 should remain local (only in ruleset1)
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_migrate_sync_after_modification() {
    # Setup: Rules in both modes
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --local
    cmd_add_rule "rule2.mdc" --commit
    
    # Test: Migrate rule and verify sync is called
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Migration should trigger immediate sync
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
    assert_file_not_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
}

test_migrate_nonexistent_rule_graceful() {
    # Setup: Local mode only
    cmd_init "$SOURCE_REPO" --local
    
    # Test: Try to migrate nonexistent rule
    output=$(cmd_add_rule "nonexistent.mdc" --commit 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should handle gracefully (warn but not fail)
    echo "$output" | grep -q "not found\|warning" || fail "Should warn about missing rule"
    
    # Should still create commit mode even if rule doesn't exist
    assert_commit_mode_exists
}

test_migrate_preserves_manifest_headers() {
    # Setup: Local mode with custom target directory
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    cmd_add_rule "rule1.mdc" --local
    
    # Test: Migrate rule to commit mode
    cmd_add_rule "rule1.mdc" --commit
    
    # Expected: Both manifests should have matching headers
    local_header=$(head -n1 "$LOCAL_MANIFEST_FILE")
    commit_header=$(head -n1 "$COMMIT_MANIFEST_FILE")
    assertEquals "Headers should match after migration" "$local_header" "$commit_header"
    
    # Should use custom directory for both modes
    assert_file_exists "$custom_dir/$SHARED_DIR/rule1.mdc"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 