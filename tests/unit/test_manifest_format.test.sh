#!/bin/sh
#
# test_manifest_format.test.sh - Manifest format test suite
#
# Tests for the enhanced manifest format that supports configurable
# paths for rules and rulesets. Validates parsing and writing of both
# old and new format manifests, handling custom paths, and backward compatibility.
#
# Test Coverage:
# - Reading new format manifests with custom rule/ruleset paths
# - Reading old format manifests with backward compatibility
# - Writing manifests with custom paths
# - Initialization with custom paths
# - Path construction using custom prefixes
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_manifest_format.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Setup - run before each test
setUp() {
    # Create a temporary test directory
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR" || fail "Failed to change to test directory"
    
    # Set up source ai-rizz for testing
    source_ai_rizz
    
    # Reset ai-rizz state
    reset_ai_rizz_state
    
    # Setup test repository structure
    REPO_DIR=$(get_repo_dir)
    mkdir -p "$REPO_DIR"
    SOURCE_REPO="https://example.com/repo.git"
    TARGET_DIR=".cursor/rules"
    
    # Create repository structure with custom paths
    mkdir -p "$REPO_DIR/docs"
    mkdir -p "$REPO_DIR/examples/web-dev"
    echo "Test rule content" > "$REPO_DIR/docs/test-rule.mdc"
    echo "Another rule content" > "$REPO_DIR/docs/another-rule.mdc"
    mkdir -p "$REPO_DIR/examples/web-dev"
    echo "Ruleset rule 1" > "$REPO_DIR/examples/web-dev/rule1.mdc"
    
    # Initialize git repo
    git init . >/dev/null 2>&1
    git config user.email "test@example.com" >/dev/null 2>&1
    git config user.name "Test User" >/dev/null 2>&1
    
    # Create initial git structure
    mkdir -p .git/info
    touch .git/info/exclude
    
    # Make initial commit
    echo "Test repository" > README.md
    git add README.md >/dev/null 2>&1
    git commit -m "Initial test setup" >/dev/null 2>&1
}

# Teardown - run after each test
tearDown() {
    # Return to original directory before removing test directory
    cd / || fail "Failed to return to root directory"
    
    # Remove test directory and all contents
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Test reading new format manifest
test_read_new_format_manifest() {
    # Create new format manifest (new-style with custom paths)
    echo "$SOURCE_REPO	$TARGET_DIR	custom_rules	custom_rulesets" > ai-rizz.skbd
    echo "custom_rules/test-rule.mdc" >> ai-rizz.skbd
    
    # Read metadata using existing function (this should work)
    metadata=$(read_manifest_metadata "ai-rizz.skbd")
    
    # Verify correct format is read
    tab_count=$(echo "$metadata" | tr -cd '\t' | wc -c)
    assertEquals "Should detect 3 tabs in new format" 3 "$tab_count"
    
    # Parse the metadata fields
    source_repo=$(echo "$metadata" | cut -f1)
    target_dir=$(echo "$metadata" | cut -f2) 
    rules_path=$(echo "$metadata" | cut -f3)
    rulesets_path=$(echo "$metadata" | cut -f4)
    
    assertEquals "Source repo should be parsed correctly" "$SOURCE_REPO" "$source_repo"
    assertEquals "Target dir should be parsed correctly" "$TARGET_DIR" "$target_dir"
    assertEquals "Rules path should be custom_rules" "custom_rules" "$rules_path"
    assertEquals "Rulesets path should be custom_rulesets" "custom_rulesets" "$rulesets_path"
}

# Test reading old format manifest with backward compatibility
test_read_old_format_manifest() {
    # Create old format manifest
    echo "$SOURCE_REPO	$TARGET_DIR" > ai-rizz.inf
    echo "rules/test-rule.mdc" >> ai-rizz.inf
    
    # Read metadata using existing function
    metadata=$(read_manifest_metadata "ai-rizz.inf")
    
    # Verify correct format is read
    tab_count=$(echo "$metadata" | tr -cd '\t' | wc -c)
    assertEquals "Should detect 1 tab in old format" 1 "$tab_count"
    
    # This should work with existing code
    source_repo=$(echo "$metadata" | cut -f1)
    target_dir=$(echo "$metadata" | cut -f2)
    
    assertEquals "Source repo should be parsed correctly" "$SOURCE_REPO" "$source_repo"
    assertEquals "Target dir should be parsed correctly" "$TARGET_DIR" "$target_dir"
    
    # For old format, fields 3 and 4 should be empty when using cut
    rules_path=$(echo "$metadata" | cut -f3)
    rulesets_path=$(echo "$metadata" | cut -f4)
    
    assertEquals "Rules path should be empty for old format" "" "$rules_path"
    assertEquals "Rulesets path should be empty for old format" "" "$rulesets_path"
}

# Test writing manifest with custom paths - should now PASS
test_write_manifest_with_custom_paths() {
    # Test calling with old parameters first
    echo "" | write_manifest_with_entries "test_manifest_old.inf" "$SOURCE_REPO" "$TARGET_DIR"
    first_line=$(head -n 1 "test_manifest_old.inf")
    assertEquals "Old format should work with defaults" "$SOURCE_REPO	$TARGET_DIR	rules	rulesets" "$first_line"
    
    # Test calling with new parameters
    echo "" | write_manifest_with_entries "test_manifest_new.skbd" "$SOURCE_REPO" "$TARGET_DIR" "docs" "examples"
    first_line=$(head -n 1 "test_manifest_new.skbd")
    assertEquals "New format should include custom paths" "$SOURCE_REPO	$TARGET_DIR	docs	examples" "$first_line"
}

# Test initialization with custom paths
test_init_with_custom_paths() {
    # This should now work because cmd_init supports --rule-path and --ruleset-path
    cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local --rule-path "docs" --ruleset-path "examples"
    assertTrue "cmd_init should succeed with custom path arguments" $?
    
    # Verify manifest has been created with new format
    test -f "$LOCAL_MANIFEST_FILE" 
    assertTrue "Local manifest file should exist" $?
    
    first_line=$(head -n 1 "$LOCAL_MANIFEST_FILE")
    assertEquals "Should use new format with custom paths" "$SOURCE_REPO	$TARGET_DIR	docs	examples" "$first_line"
}

# Test that current manifest reading works and supports new fields
test_current_manifest_capabilities() {
    # Create a new format manifest with custom paths
    echo "$SOURCE_REPO	$TARGET_DIR	docs	examples" > ai-rizz.skbd
    echo "docs/test-rule.mdc" >> ai-rizz.skbd
    
    # Current read_manifest_metadata should work
    metadata=$(read_manifest_metadata "ai-rizz.skbd")
    assertNotNull "Should be able to read metadata line" "$metadata"
    
    # Current read_manifest_entries should work
    entries=$(read_manifest_entries "ai-rizz.skbd")
    assertEquals "Should read entries correctly" "docs/test-rule.mdc" "$entries"
    
    # Test that parse_manifest_metadata works with the new format
    parse_manifest_metadata "ai-rizz.skbd" "commit"
    assertEquals "Should parse custom rules path" "docs" "$COMMIT_RULES_PATH"
    assertEquals "Should parse custom rulesets path" "examples" "$COMMIT_RULESETS_PATH"
}

# Include and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 