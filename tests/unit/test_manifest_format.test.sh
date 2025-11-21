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
    TEST_SOURCE_REPO="https://example.com/repo.git"
    TEST_TARGET_DIR=".cursor/rules"
    
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
    echo "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	custom_rules	custom_rulesets" > ai-rizz.skbd
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
    
    assertEquals "Source repo should be parsed correctly" "$TEST_SOURCE_REPO" "$source_repo"
    assertEquals "Target dir should be parsed correctly" "$TEST_TARGET_DIR" "$target_dir"
    assertEquals "Rules path should be custom_rules" "custom_rules" "$rules_path"
    assertEquals "Rulesets path should be custom_rulesets" "custom_rulesets" "$rulesets_path"
}

# Test reading old format manifest with backward compatibility
test_read_old_format_manifest() {
    # Create old format manifest
    echo "$TEST_SOURCE_REPO	$TEST_TARGET_DIR" > ai-rizz.inf
    echo "rules/test-rule.mdc" >> ai-rizz.inf
    
    # Read metadata using existing function
    metadata=$(read_manifest_metadata "ai-rizz.inf")
    
    # Verify correct format is read
    tab_count=$(echo "$metadata" | tr -cd '\t' | wc -c)
    assertEquals "Should detect 1 tab in old format" 1 "$tab_count"
    
    # This should work with existing code
    source_repo=$(echo "$metadata" | cut -f1)
    target_dir=$(echo "$metadata" | cut -f2)
    
    assertEquals "Source repo should be parsed correctly" "$TEST_SOURCE_REPO" "$source_repo"
    assertEquals "Target dir should be parsed correctly" "$TEST_TARGET_DIR" "$target_dir"
    
    # For old format, fields 3 and 4 should be empty when using cut
    rules_path=$(echo "$metadata" | cut -f3)
    rulesets_path=$(echo "$metadata" | cut -f4)
    
    assertEquals "Rules path should be empty for old format" "" "$rules_path"
    assertEquals "Rulesets path should be empty for old format" "" "$rulesets_path"
}

# Test writing manifest with custom paths - should now PASS
test_write_manifest_with_custom_paths() {
    # Test calling with old parameters (should default to V2 with default command paths)
    echo "" | write_manifest_with_entries "test_manifest_old.inf" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR"
    first_line=$(head -n 1 "test_manifest_old.inf")
    assertEquals "Should write V2 format with defaults" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	rules	rulesets	commands	commandsets" "$first_line"
    
    # Test calling with custom rule paths only (should use default command paths)
    echo "" | write_manifest_with_entries "test_manifest_partial.skbd" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples"
    first_line=$(head -n 1 "test_manifest_partial.skbd")
    assertEquals "Should write V2 format with custom rule paths and default command paths" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	docs	examples	commands	commandsets" "$first_line"
    
    # Test calling with all custom parameters
    echo "" | write_manifest_with_entries "test_manifest_new.skbd" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples" "cmds" "cmdsets"
    first_line=$(head -n 1 "test_manifest_new.skbd")
    assertEquals "Should write V2 format with all custom paths" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	docs	examples	cmds	cmdsets" "$first_line"
}

# Test initialization with custom paths
test_init_with_custom_paths() {
    # This should now work because cmd_init supports --rule-path and --ruleset-path
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --rule-path "docs" --ruleset-path "examples"
    assertTrue "cmd_init should succeed with custom path arguments" $?
    
    # Verify manifest has been created with new format
    test -f "$TEST_LOCAL_MANIFEST_FILE" 
    assertTrue "Local manifest file should exist" $?
    
    first_line=$(head -n 1 "$TEST_LOCAL_MANIFEST_FILE")
    # Should now use V2 format (6 fields) with default command paths
    assertEquals "Should use V2 format with custom rule paths and default command paths" "$TEST_SOURCE_REPO	$TEST_TARGET_DIR	docs	examples	commands	commandsets" "$first_line"
}

# Test that current manifest reading works and supports new fields
test_current_manifest_capabilities() {
    # Create a V2 format manifest with custom paths (6 fields)
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples" "cmds" "cmdsets" > ai-rizz.skbd
    echo "docs/test-rule.mdc" >> ai-rizz.skbd
    
    # Current read_manifest_metadata should work
    metadata=$(read_manifest_metadata "ai-rizz.skbd")
    assertNotNull "Should be able to read metadata line" "$metadata"
    
    # Current read_manifest_entries should work
    entries=$(read_manifest_entries "ai-rizz.skbd")
    assertEquals "Should read entries correctly" "docs/test-rule.mdc" "$entries"
    
    # Test that parse_manifest_metadata works with V2 format
    parse_manifest_metadata "ai-rizz.skbd"
    assertEquals "Should parse custom rules path" "docs" "$RULES_PATH"
    assertEquals "Should parse custom rulesets path" "examples" "$RULESETS_PATH"
    assertEquals "Should parse custom commands path" "cmds" "$COMMANDS_PATH"
    assertEquals "Should parse custom commandsets path" "cmdsets" "$COMMANDSETS_PATH"
}

# Test smart manifest filename parsing for CLI arguments
test_smart_manifest_filename_parsing() {
    # Test detecting local manifest names and deriving root
    
    # Test 1: ai-rizz.local.inf -> root: ai-rizz.inf, local: ai-rizz.local.inf
    result=$(parse_manifest_filename_argument "ai-rizz.local.inf")
    root=$(echo "$result" | cut -f1)
    local_name=$(echo "$result" | cut -f2)
    assertEquals "Should extract root from .local.ext" "ai-rizz.inf" "$root"
    assertEquals "Should keep local name" "ai-rizz.local.inf" "$local_name"
    
    # Test 2: foo.local.bar -> root: foo.bar, local: foo.local.bar
    result=$(parse_manifest_filename_argument "foo.local.bar")
    root=$(echo "$result" | cut -f1)
    local_name=$(echo "$result" | cut -f2)
    assertEquals "Should extract root from multi-extension" "foo.bar" "$root"
    assertEquals "Should keep local name" "foo.local.bar" "$local_name"
    
    # Test 3: Gyattfile.local -> root: Gyattfile, local: Gyattfile.local  
    result=$(parse_manifest_filename_argument "Gyattfile.local")
    root=$(echo "$result" | cut -f1)
    local_name=$(echo "$result" | cut -f2)
    assertEquals "Should extract root from extensionless" "Gyattfile" "$root"
    assertEquals "Should keep local name" "Gyattfile.local" "$local_name"
    
    # Test 4: ai-rizz.inf -> root: ai-rizz.inf, local: ai-rizz.local.inf
    result=$(parse_manifest_filename_argument "ai-rizz.inf")
    root=$(echo "$result" | cut -f1)
    local_name=$(echo "$result" | cut -f2)
    assertEquals "Should use as root when not local" "ai-rizz.inf" "$root"
    assertEquals "Should derive local name" "ai-rizz.local.inf" "$local_name"
    
    # Test 5: Gyattfile -> root: Gyattfile, local: Gyattfile.local
    result=$(parse_manifest_filename_argument "Gyattfile")
    root=$(echo "$result" | cut -f1)
    local_name=$(echo "$result" | cut -f2)
    assertEquals "Should use as root when extensionless" "Gyattfile" "$root"
    assertEquals "Should derive local name for extensionless" "Gyattfile.local" "$local_name"
}

# Test reading V2 format manifest (6 fields, 5 tabs)
test_read_v2_format_manifest() {
    # Create V2 format manifest with 6 fields (5 tabs)
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples" "cmds" "cmdsets" > ai-rizz.skbd
    echo "docs/test-rule.mdc" >> ai-rizz.skbd
    
    # Read metadata using existing function
    metadata=$(read_manifest_metadata "ai-rizz.skbd")
    
    # Verify correct format is read (should have 5 tabs for 6 fields)
    tab_count=$(echo "$metadata" | tr -cd '\t' | wc -c)
    assertEquals "Should detect 5 tabs in V2 format" 5 "$tab_count"
    
    # Parse the metadata fields
    source_repo=$(echo "$metadata" | cut -f1)
    target_dir=$(echo "$metadata" | cut -f2)
    rules_path=$(echo "$metadata" | cut -f3)
    rulesets_path=$(echo "$metadata" | cut -f4)
    commands_path=$(echo "$metadata" | cut -f5)
    commandsets_path=$(echo "$metadata" | cut -f6)
    
    assertEquals "Source repo should be parsed correctly" "$TEST_SOURCE_REPO" "$source_repo"
    assertEquals "Target dir should be parsed correctly" "$TEST_TARGET_DIR" "$target_dir"
    assertEquals "Rules path should be docs" "docs" "$rules_path"
    assertEquals "Rulesets path should be examples" "examples" "$rulesets_path"
    assertEquals "Commands path should be cmds" "cmds" "$commands_path"
    assertEquals "Commandsets path should be cmdsets" "cmdsets" "$commandsets_path"
}

# Test writing V2 format manifest (6 fields)
test_write_v2_format_manifest() {
    # Write manifest with all 6 parameters
    echo "" | write_manifest_with_entries "test_v2.skbd" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples" "cmds" "cmdsets"
    
    # Read the first line
    first_line=$(head -n 1 "test_v2.skbd")
    
    # Verify it has 5 tabs (6 fields)
    tab_count=$(echo "$first_line" | tr -cd '\t' | wc -c)
    assertEquals "Should write 5 tabs for V2 format" 5 "$tab_count"
    
    # Verify all fields are present
    expected_line=$(printf "%s\t%s\t%s\t%s\t%s\t%s" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples" "cmds" "cmdsets")
    assertEquals "Should write V2 format with all 6 fields" "$expected_line" "$first_line"
}

# Test parsing V2 manifest sets COMMANDS_PATH and COMMANDSETS_PATH globals
test_parse_v2_manifest_metadata() {
    # Create V2 format manifest
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "docs" "examples" "cmds" "cmdsets" > ai-rizz.skbd
    echo "docs/test-rule.mdc" >> ai-rizz.skbd
    
    # Parse using the function
    parse_manifest_metadata "ai-rizz.skbd"
    assertTrue "Should successfully parse V2 manifest" $?
    
    # Verify all global variables are set correctly
    assertEquals "RULES_PATH should be set to docs" "docs" "$RULES_PATH"
    assertEquals "RULESETS_PATH should be set to examples" "examples" "$RULESETS_PATH"
    assertEquals "COMMANDS_PATH should be set to cmds" "cmds" "$COMMANDS_PATH"
    assertEquals "COMMANDSETS_PATH should be set to cmdsets" "cmdsets" "$COMMANDSETS_PATH"
    assertEquals "SOURCE_REPO should be set" "$TEST_SOURCE_REPO" "$SOURCE_REPO"
    assertEquals "TARGET_DIR should be set" "$TEST_TARGET_DIR" "$TARGET_DIR"
}

# Test V1 to V2 auto-upgrade on write
test_v1_to_v2_auto_upgrade() {
    # Create V1 format manifest (4 fields, 3 tabs)
    printf "%s\t%s\t%s\t%s\n" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "rules" "rulesets" > ai-rizz.skbd
    echo "rules/test-rule.mdc" >> ai-rizz.skbd
    
    # Parse V1 manifest
    parse_manifest_metadata "ai-rizz.skbd"
    assertTrue "Should successfully parse V1 manifest" $?
    
    # Verify defaults are used for command paths
    assertEquals "COMMANDS_PATH should use default" "commands" "$COMMANDS_PATH"
    assertEquals "COMMANDSETS_PATH should use default" "commandsets" "$COMMANDSETS_PATH"
    
    # Now write a new manifest - should auto-upgrade to V2
    read_manifest_entries "ai-rizz.skbd" | write_manifest_with_entries "ai-rizz-v2.skbd" "$SOURCE_REPO" "$TARGET_DIR" "$RULES_PATH" "$RULESETS_PATH" "$COMMANDS_PATH" "$COMMANDSETS_PATH"
    
    # Verify the new manifest is V2 format
    first_line=$(head -n 1 "ai-rizz-v2.skbd")
    tab_count=$(echo "$first_line" | tr -cd '\t' | wc -c)
    assertEquals "Should auto-upgrade to V2 format with 5 tabs" 5 "$tab_count"
    
    # Verify all fields including command paths
    expected_line=$(printf "%s\t%s\t%s\t%s\t%s\t%s" "$TEST_SOURCE_REPO" "$TEST_TARGET_DIR" "rules" "rulesets" "commands" "commandsets")
    assertEquals "Should include default command paths" "$expected_line" "$first_line"
    
    # Verify entries are preserved
    entries=$(read_manifest_entries "ai-rizz-v2.skbd")
    assertEquals "Should preserve manifest entries" "rules/test-rule.mdc" "$entries"
}

# Include and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 