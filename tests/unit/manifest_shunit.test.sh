#!/bin/sh
# Tests for manifest operations using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Test functions
# -------------

# Test that write_manifest correctly writes the manifest file
test_write_manifest() {
  # Set up test data
  SOURCE_REPO="https://github.com/example/rules.git"
  TARGET_DIR=".cursor/rules"
  MANIFEST_ENTRIES="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  
  # Run the function
  write_manifest
  
  # Read the file content
  actual=$(cat "$MANIFEST_FILE")
  
  # Verify content
  expected="https://github.com/example/rules.git	.cursor/rules
rules/foo.mdc
rules/bar.mdc
rulesets/code"
  
  assertEquals "Manifest file content should match" "$expected" "$actual"
}

# Test that read_manifest correctly reads the manifest file
test_read_manifest() {
  # Set up test data
  cat > "$MANIFEST_FILE" << EOF
https://github.com/example/rules.git	.cursor/rules
rules/foo.mdc
rules/bar.mdc
rulesets/code
EOF
  
  # Run the function
  read_manifest
  
  # Verify results
  assertEquals "SOURCE_REPO should be set correctly" "https://github.com/example/rules.git" "$SOURCE_REPO"
  assertEquals "TARGET_DIR should be set correctly" ".cursor/rules" "$TARGET_DIR"
  
  expected="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  assertEquals "MANIFEST_ENTRIES should be set correctly" "$expected" "$MANIFEST_ENTRIES"
}

# Test that add_manifest_entry correctly adds entries
test_add_manifest_entry() {
  # Set up test data
  MANIFEST_ENTRIES="rules/foo.mdc
rules/bar.mdc"
  
  # Run the function
  add_manifest_entry "rulesets/code"
  
  # Verify results
  expected="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  assertEquals "Entry should be added correctly" "$expected" "$MANIFEST_ENTRIES"
  
  # Test duplicate entry
  add_manifest_entry "rules/foo.mdc"
  assertEquals "Duplicate entry should not be added" "$expected" "$MANIFEST_ENTRIES"
}

# Test that remove_manifest_entry correctly removes entries
test_remove_manifest_entry() {
  # Set up test data
  MANIFEST_ENTRIES="rules/foo.mdc
rules/bar.mdc
rulesets/code"
  
  # Run the function
  remove_manifest_entry "rules/bar.mdc"
  
  # Verify results
  expected="rules/foo.mdc
rulesets/code"
  assertEquals "Entry should be removed correctly" "$expected" "$MANIFEST_ENTRIES"
  
  # Test nonexistent entry
  remove_manifest_entry "nonexistent"
  assertEquals "Nonexistent entry removal should be a no-op" "$expected" "$MANIFEST_ENTRIES"
}

# Test edge cases in manifest operations
test_manifest_edge_cases() {
  # Test empty manifest
  MANIFEST_ENTRIES=""
  SOURCE_REPO="https://github.com/example/rules.git"
  TARGET_DIR=".cursor/rules"
  
  # Write and read back
  write_manifest
  read_manifest
  
  assertEquals "Empty manifest should remain empty" "" "$MANIFEST_ENTRIES"
  
  # Test adding to empty manifest
  add_manifest_entry "rules/first.mdc"
  assertEquals "First entry should be added without newlines" "rules/first.mdc" "$MANIFEST_ENTRIES"
  
  # Test adding a second entry
  add_manifest_entry "rules/second.mdc"
  expected="rules/first.mdc
rules/second.mdc"
  assertEquals "Second entry should be added with proper formatting" "$expected" "$MANIFEST_ENTRIES"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 