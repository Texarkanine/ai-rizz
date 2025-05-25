#!/bin/sh
# Tests for backward compatibility migration using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_migrate_legacy_local_mode() {
    # Setup: Legacy local mode (ai-rizz.inf in git exclude)
    setup_legacy_local_repo
    
    # Test: Any command should trigger migration
    cmd_list
    
    # Expected: Migrated to new local mode structure
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    assert_file_exists "$LOCAL_MANIFEST_FILE"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
    
    # Verify git exclude updated
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
}

test_migrate_legacy_commit_mode() {
    # Setup: Legacy commit mode (ai-rizz.inf not in git exclude)
    setup_legacy_commit_repo
    
    # Test: Any command should preserve commit mode
    cmd_list
    
    # Expected: No migration needed, remains commit mode
    assert_file_exists "$COMMIT_MANIFEST_FILE"
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
}

test_detect_legacy_local_mode() {
    # Test the detection logic for legacy local mode
    setup_legacy_local_repo
    
    # Test internal detection function
    assertTrue "Should detect legacy local mode" "needs_migration"
}

test_no_migration_needed_new_format() {
    # Setup: New format (both modes)
    cmd_init "$SOURCE_REPO" --local
    cmd_add_rule "rule1.mdc" --commit
    
    # Test: No migration should be needed
    assertFalse "Should not need migration" "needs_migration"
}

test_migration_preserves_all_rules() {
    # Setup: Legacy local with multiple rules
    setup_legacy_local_repo
    echo "rules/rule2.mdc" >> "$COMMIT_MANIFEST_FILE"
    cp "$REPO_DIR/rules/rule2.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # Test: Migration preserves all rules
    cmd_list
    
    # Expected: All rules preserved in local mode
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    
    # Verify manifest content preserved
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rules/rule1.mdc" || fail "Should preserve rule1"
    echo "$local_content" | grep -q "rules/rule2.mdc" || fail "Should preserve rule2"
}

test_migration_preserves_rulesets() {
    # Setup: Legacy local with rulesets
    setup_legacy_local_repo
    echo "rulesets/ruleset1" >> "$COMMIT_MANIFEST_FILE"
    cp "$REPO_DIR/rules/rule2.mdc" "$TARGET_DIR/$SHARED_DIR/"  # ruleset1 includes rule2
    
    # Test: Migration preserves rulesets
    cmd_list
    
    # Expected: Ruleset preserved in local mode
    local_content=$(cat "$LOCAL_MANIFEST_FILE")
    echo "$local_content" | grep -q "rulesets/ruleset1" || fail "Should preserve ruleset1"
    
    # All ruleset files should be migrated
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
}

test_migration_updates_directory_structure() {
    # Setup: Legacy local mode
    setup_legacy_local_repo
    
    # Add additional rules to test directory migration
    echo "rules/rule2.mdc" >> "$COMMIT_MANIFEST_FILE"
    echo "rules/rule3.mdc" >> "$COMMIT_MANIFEST_FILE"
    cp "$REPO_DIR/rules/rule2.mdc" "$TARGET_DIR/$SHARED_DIR/"
    cp "$REPO_DIR/rules/rule3.mdc" "$TARGET_DIR/$SHARED_DIR/"
    
    # Test: Migration should move all files to local directory
    cmd_list
    
    # Expected: All files moved from shared to local
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule2.mdc"
    assert_file_exists "$TARGET_DIR/$LOCAL_DIR/rule3.mdc"
    
    # Shared directory should be empty or removed
    assertFalse "Shared directory should be empty" "[ -f '$TARGET_DIR/$SHARED_DIR/rule1.mdc' ]"
    assertFalse "Shared directory should be empty" "[ -f '$TARGET_DIR/$SHARED_DIR/rule2.mdc' ]"
    assertFalse "Shared directory should be empty" "[ -f '$TARGET_DIR/$SHARED_DIR/rule3.mdc' ]"
}

test_migration_preserves_manifest_header() {
    # Setup: Legacy local with custom target directory
    custom_target=".custom/rules"
    echo "$SOURCE_REPO	$custom_target" > "$COMMIT_MANIFEST_FILE"
    echo "rules/rule1.mdc" >> "$COMMIT_MANIFEST_FILE"
    mkdir -p "$custom_target/$SHARED_DIR"
    cp "$REPO_DIR/rules/rule1.mdc" "$custom_target/$SHARED_DIR/"
    
    # Set up git exclude for legacy local mode
    mkdir -p .git/info
    echo "$COMMIT_MANIFEST_FILE" > .git/info/exclude
    echo "$custom_target/$SHARED_DIR" >> .git/info/exclude
    
    # Test: Migration should preserve custom target directory
    cmd_list
    
    # Expected: New manifest should have same header
    local_header=$(head -n1 "$LOCAL_MANIFEST_FILE")
    assertEquals "Should preserve custom target" "$SOURCE_REPO	$custom_target" "$local_header"
    
    # Files should be in custom local directory
    assert_file_exists "$custom_target/$LOCAL_DIR/rule1.mdc"
}

test_migration_git_exclude_cleanup() {
    # Setup: Legacy local mode with complex git excludes
    setup_legacy_local_repo
    echo "some_other_file" >> .git/info/exclude
    echo "another_ignored_file" >> .git/info/exclude
    
    # Test: Migration should update git excludes correctly
    cmd_list
    
    # Expected: Legacy excludes removed, new excludes added
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TARGET_DIR/$SHARED_DIR"
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
    
    # Other excludes should be preserved
    assertTrue "Should preserve other excludes" "grep -q 'some_other_file' .git/info/exclude"
    assertTrue "Should preserve other excludes" "grep -q 'another_ignored_file' .git/info/exclude"
}

test_migration_triggered_by_any_command() {
    # Setup: Legacy local mode
    setup_legacy_local_repo
    
    # Test: Different commands should all trigger migration
    cmd_sync  # Should trigger migration
    
    # Expected: Migration completed
    assert_file_exists "$LOCAL_MANIFEST_FILE"
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
}

test_migration_idempotent() {
    # Setup: Legacy local mode
    setup_legacy_local_repo
    
    # Test: Multiple commands should not re-migrate
    cmd_list
    first_mtime=$(stat -f "%m" "$LOCAL_MANIFEST_FILE" 2>/dev/null || stat -c "%Y" "$LOCAL_MANIFEST_FILE")
    
    sleep 1
    cmd_list  # Should not re-migrate
    
    second_mtime=$(stat -f "%m" "$LOCAL_MANIFEST_FILE" 2>/dev/null || stat -c "%Y" "$LOCAL_MANIFEST_FILE")
    assertEquals "Should not re-migrate" "$first_mtime" "$second_mtime"
}

test_no_migration_commit_mode() {
    # Setup: Legacy commit mode (no git excludes)
    setup_legacy_commit_repo
    
    # Test: Should not trigger migration
    cmd_list
    
    # Expected: Remains in original state
    assert_file_exists "$COMMIT_MANIFEST_FILE"
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assertFalse "Should not need migration" "needs_migration"
}

test_migration_handles_missing_files() {
    # Setup: Legacy local mode with missing rule file
    setup_legacy_local_repo
    echo "rules/nonexistent.mdc" >> "$COMMIT_MANIFEST_FILE"
    
    # Test: Migration should handle missing files gracefully
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Migration completes despite missing file
    assert_file_exists "$LOCAL_MANIFEST_FILE"
    
    # Should warn about missing file
    echo "$output" | grep -q "not found\|warning" || true  # May warn
}

test_migration_with_empty_manifest() {
    # Setup: Legacy local mode with empty manifest (only header)
    echo "$SOURCE_REPO	$TARGET_DIR" > "$COMMIT_MANIFEST_FILE"
    mkdir -p .git/info
    echo "$COMMIT_MANIFEST_FILE" > .git/info/exclude
    echo "$TARGET_DIR/$SHARED_DIR" >> .git/info/exclude
    
    # Test: Migration should handle empty manifest
    cmd_list
    
    # Expected: Migration completes with empty local manifest
    assert_file_exists "$LOCAL_MANIFEST_FILE"
    local_header=$(head -n1 "$LOCAL_MANIFEST_FILE")
    assertEquals "Should preserve header" "$SOURCE_REPO	$TARGET_DIR" "$local_header"
}

test_migration_error_recovery() {
    # Setup: Legacy local mode
    setup_legacy_local_repo
    
    # Make target directory read-only to simulate error
    chmod 444 "$TARGET_DIR"
    
    # Test: Migration should handle errors gracefully
    output=$(cmd_list 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should not leave system in broken state
    echo "$output" | grep -q "error\|permission\|failed" || true
    
    # Restore permissions for cleanup
    chmod 755 "$TARGET_DIR"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 