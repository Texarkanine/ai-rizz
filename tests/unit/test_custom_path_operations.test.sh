#!/bin/sh
#
# test_custom_path_operations.test.sh - Custom path operations test suite
#
# Tests for operations that use custom paths for rules and rulesets,
# including adding, removing, and listing rules with non-default paths.
#
# Test Coverage:
# - Adding rules with custom paths
# - Removing rules with custom paths
# - Listing rules with custom paths
# - Syncing repositories with custom paths
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_custom_path_operations.test.sh

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
    TEST_SOURCE_REPO="https://example.com/repo.git"
    TEST_TARGET_DIR=".cursor/rules"
    
    # Create repository structure with custom paths
    mkdir -p "$REPO_DIR/docs"
    mkdir -p "$REPO_DIR/kb/sections"
    
    # Create some test rules in custom locations
    echo "Test rule content" > "$REPO_DIR/docs/test-rule.mdc"
    echo "Another rule content" > "$REPO_DIR/docs/another-rule.mdc"
    
    # Create a ruleset in custom location
    mkdir -p "$REPO_DIR/kb/sections/test-ruleset"
    echo "Ruleset rule 1" > "$REPO_DIR/kb/sections/test-ruleset/rule1.mdc"
    echo "Ruleset rule 2" > "$REPO_DIR/kb/sections/test-ruleset/rule2.mdc"
    
    # Also create standard structure for compatibility testing
    mkdir -p "$REPO_DIR/rules"
    mkdir -p "$REPO_DIR/rulesets/standard-ruleset"
    echo "Standard rule content" > "$REPO_DIR/rules/standard-rule.mdc"
    echo "Standard ruleset rule" > "$REPO_DIR/rulesets/standard-ruleset/rule.mdc"
    
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

# Test that cmd_init works with custom path arguments
test_init_works_with_custom_path_args() {
    # This should now work because --rule-path and --ruleset-path are implemented
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --rule-path "docs" --ruleset-path "kb/sections"
    assertTrue "cmd_init should work with custom path arguments" $?
    
    # Verify manifest has correct format
    test -f "$TEST_LOCAL_MANIFEST_FILE"
    assertTrue "Local manifest should be created" $?
    
    first_line=$(head -n 1 "$TEST_LOCAL_MANIFEST_FILE")
    assertEquals "Should use custom paths in manifest" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	docs	kb/sections" "$first_line"
}

# Test that standard initialization still works (baseline test)
test_standard_init_works() {
    # This should work with current implementation
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assertTrue "Standard init should work" $?
    
    # Verify standard structure is created
    test -f "$TEST_LOCAL_MANIFEST_FILE"
    assertTrue "Local manifest should be created" $?
    
    test -d "$TEST_TARGET_DIR/local"
    assertTrue "Local directory should be created" $?
    
    # Verify manifest has standard format with defaults
    first_line=$(head -n 1 "$TEST_LOCAL_MANIFEST_FILE")
    assertEquals "Should use standard format with defaults" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	rules	rulesets" "$first_line"
}

# Test adding rule with custom paths
test_add_rule_uses_custom_paths() {
    # Initialize with custom paths
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --rule-path "docs" --ruleset-path "kb/sections"
    
    # Add a rule from the custom "docs" directory
    cmd_add_rule "test-rule.mdc" "--local"
    assertTrue "Should be able to add rule from docs directory" $?
    
    # Verify rule was added to manifest with "docs/" prefix
    grep -q "docs/test-rule.mdc" "$TEST_LOCAL_MANIFEST_FILE"
    assertTrue "Manifest should contain rule with docs/ prefix" $?
    
    # Verify rule file exists in target
    test -f "$TEST_TARGET_DIR/local/test-rule.mdc"
    assertTrue "Rule file should exist in target directory" $?
}

# Test that list command shows rules from custom paths
test_list_shows_custom_paths() {
    # Initialize with custom paths
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --rule-path "docs" --ruleset-path "kb/sections"
    
    # Add a rule from custom location
    cmd_add_rule "test-rule.mdc" "--local"
    
    # List rules
    list_output=$(cmd_list)
    
    # Should show the rule from custom docs directory
    echo "$list_output" | grep -q "test-rule.mdc"
    assertTrue "Should show rule from docs directory" $?
}

# Test adding ruleset with custom paths - should now PASS
test_add_ruleset_uses_custom_paths() {
    # Initialize with custom paths
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --rule-path "docs" --ruleset-path "kb/sections"
    
    # Add a ruleset from the custom "kb/sections" directory (should now work)
    cmd_add_ruleset "test-ruleset" "--local"
    assertTrue "Should be able to add ruleset from kb/sections directory" $?
    
    # Verify ruleset was added to manifest with "kb/sections/" prefix
    grep -q "kb/sections/test-ruleset" "$TEST_LOCAL_MANIFEST_FILE"
    assertTrue "Manifest should contain ruleset with kb/sections/ prefix" $?
    
    # Verify ruleset files exist in target
    test -f "$TEST_TARGET_DIR/local/rule1.mdc"
    assertTrue "Ruleset rule1 file should exist in target directory" $?
    
    test -f "$TEST_TARGET_DIR/local/rule2.mdc"
    assertTrue "Ruleset rule2 file should exist in target directory" $?
}

# Test that new manifest format can be read and used
test_new_manifest_format_fully_functional() {
    # Create a manifest with new format manually
    echo "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	docs	kb/sections" > "$TEST_LOCAL_MANIFEST_FILE"
    echo "docs/test-rule.mdc" >> "$TEST_LOCAL_MANIFEST_FILE"
    
    # Verify we can read the metadata
    metadata=$(read_manifest_metadata "$TEST_LOCAL_MANIFEST_FILE")
    assertNotNull "Should be able to read new format metadata" "$metadata"
    
    # Verify we can read the entries
    entries=$(read_manifest_entries "$TEST_LOCAL_MANIFEST_FILE")
    assertEquals "Should read entries correctly" "docs/test-rule.mdc" "$entries"
    
    # Test that the implementation now USES the custom paths in the metadata
    # Initialize the mode state to simulate having this manifest loaded
    mkdir -p "$TEST_TARGET_DIR/local"
    HAS_LOCAL_MODE=true
    cache_manifest_metadata
    
    # Try to add another rule - it should use the "docs/" prefix from the manifest
    cmd_add_rule "another-rule.mdc" "--local"
    
    # Check what prefix was actually used
    new_entries=$(read_manifest_entries "$TEST_LOCAL_MANIFEST_FILE")
    
    # This should now work correctly with custom paths
    echo "$new_entries" | grep -q "docs/another-rule.mdc"
    assertTrue "Should use docs/ prefix from manifest" $?
}

# Include and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 