#!/bin/sh
#
# test_progressive_init.test.sh - Progressive initialization test suite
#
# Tests the progressive initialization system that allows ai-rizz to start
# with a single mode (local or commit) and later expand to dual-mode through
# lazy initialization. Validates manifest creation, directory structure,
# git exclude management, and idempotent re-initialization behavior.
#
# Test Coverage:
# Validates all aspects of progressive initialization including mode setup,
# directory creation, manifest formatting, git exclude management, and
# idempotent behavior across various configuration scenarios.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_progressive_init.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Main test functions
# ------------------

test_init_local_mode_only() {
    # Test: ai-rizz init $REPO -d $TARGET_DIR --local
    # Expected: Creates local manifest and directory only
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    assert_local_mode_exists
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_init_commit_mode_only() {
    # Test: ai-rizz init $REPO -d $TARGET_DIR --commit  
    # Expected: Creates commit manifest and directory only
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    
    assert_commit_mode_exists
    assert_file_not_exists "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
}

test_init_requires_mode_flag() {
    # Test: ai-rizz init $REPO (no mode flag, provide empty input to prompt)
    # Expected: Should prompt for mode selection
    
    output=$(echo "" | cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" 2>&1 || echo "ERROR_OCCURRED")
    
    # Expected: Should show prompt for mode selection
    echo "$output" | grep -q "mode\|local\|commit\|choose\|select" || fail "Should show mode selection prompt"
}

test_init_custom_target_dir() {
    # Test: ai-rizz init $REPO -d .custom/rules --local
    # Expected: Uses custom target directory
    
    custom_dir=".custom/rules"
    cmd_init "$SOURCE_REPO" -d "$custom_dir" --local
    
    assertTrue "Custom directory should exist" "[ -d '$custom_dir/$LOCAL_DIR' ]"
    assert_git_exclude_contains "$custom_dir/$LOCAL_DIR"
}

test_init_creates_correct_manifest_headers() {
    # Test both modes create proper headers
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    first_line=$(head -n1 "$LOCAL_MANIFEST_FILE")
    assertEquals "Local manifest header incorrect" "$SOURCE_REPO	$TARGET_DIR" "$first_line"
    
    # Clean up and test commit mode in separate directory
    tearDown
    setUp
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit  
    first_line=$(head -n1 "$COMMIT_MANIFEST_FILE")
    assertEquals "Commit manifest header incorrect" "$SOURCE_REPO	$TARGET_DIR" "$first_line"
}

test_init_local_creates_git_excludes() {
    # Test: Local mode should add entries to git exclude
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    
    # Verify git exclude entries were added
    assert_git_exclude_contains "$LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TARGET_DIR/$LOCAL_DIR"
}

test_init_commit_no_git_excludes() {
    # Test: Commit mode should NOT add entries to git exclude
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --commit
    
    # Verify no git exclude entries for commit mode files
    assert_git_exclude_not_contains "$COMMIT_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TARGET_DIR/$SHARED_DIR"
}

test_init_twice_same_mode_idempotent() {
    # Test: Running init twice with same mode should be idempotent
    
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    assert_local_mode_exists
    
    # Init again with same mode
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
    assert_local_mode_exists
    
    # Should still only have local mode
    assert_file_not_exists "$COMMIT_MANIFEST_FILE"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 