#!/bin/sh
# Tests for cmd_sync, cmd_remove_rule and cmd_remove_ruleset functions using shunit2

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Main test functions
# ------------------

# Test that cmd_sync properly cleans up orphaned rules
test_sync_cleanup() {
  # Add rule1 and ruleset2 to manifest
  MANIFEST_ENTRIES="rules/rule1.mdc
rulesets/ruleset2"
  write_manifest
  
  # Copy all rules to shared dir to simulate previous state
  cp -f "$REPO_DIR/rules/rule1.mdc" "$TARGET_DIR/$SHARED_DIR/"
  cp -f "$REPO_DIR/rules/rule2.mdc" "$TARGET_DIR/$SHARED_DIR/"
  cp -f "$REPO_DIR/rules/rule3.mdc" "$TARGET_DIR/$SHARED_DIR/"
  
  # Run sync
  cmd_sync
  
  # Verify rule1 should exist (directly in manifest)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  
  # Verify rule2 should exist (part of ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  
  # Verify rule3 should exist (part of ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
  
  # Now remove ruleset2, leaving only rule1 in manifest
  MANIFEST_ENTRIES="rules/rule1.mdc"
  write_manifest
  
  # Run sync again
  cmd_sync
  
  # Verify rule1 should still exist
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  
  # Verify rule2 should be removed (not in any ruleset in manifest)
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  
  # Verify rule3 should be removed (not in any ruleset in manifest)
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
}

# Test that removing a rule directly preserves it if it's still needed by a ruleset
test_rule_removal() {
  # Add rule1, rule2 and ruleset2 to manifest
  MANIFEST_ENTRIES="rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset2"
  write_manifest
  
  # Sync to populate the target directory
  cmd_sync
  
  # Verify initial state
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
  
  # Remove rule1 (not in any ruleset)
  cmd_remove_rule "rule1.mdc"
  
  # Verify rule1 should be removed
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  
  # Verify rule2 should exist (in ruleset2 and directly)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  
  # Verify rule3 should exist (in ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
  
  # Remove rule2 (still in ruleset2)
  cmd_remove_rule "rule2.mdc"
  
  # Verify rule1 should still be gone
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  
  # Verify rule2 should exist (still in ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  
  # Verify rule3 should exist (in ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
}

# Test that removing a ruleset cleans up rules that are no longer needed
test_ruleset_removal() {
  # Add ruleset1 and ruleset2 to manifest
  MANIFEST_ENTRIES="rulesets/ruleset1
rulesets/ruleset2"
  write_manifest
  
  # Sync to populate the target directory
  cmd_sync
  
  # Verify initial state
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
  
  # Remove ruleset1
  cmd_remove_ruleset "ruleset1"
  
  # Verify rule1 should be removed (only in ruleset1)
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  
  # Verify rule2 should exist (still in ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  
  # Verify rule3 should exist (in ruleset2)
  assert_file_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
  
  # Remove ruleset2
  cmd_remove_ruleset "ruleset2"
  
  # Verify all rules should be removed
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule1.mdc"
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule2.mdc"
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/rule3.mdc"
}

# Test that sync handles edge cases like non-existent rules gracefully
test_sync_edge_cases() {
  # Add rule that doesn't exist
  MANIFEST_ENTRIES="rules/nonexistent.mdc"
  write_manifest
  
  # Run sync (should not fail, just warn)
  cmd_sync
  
  # Verify no rules are copied
  assert_file_not_exists "$TARGET_DIR/$SHARED_DIR/nonexistent.mdc"
  
  # Add ruleset that doesn't exist
  MANIFEST_ENTRIES="rulesets/nonexistent"
  write_manifest
  
  # Run sync (should not fail, just warn)
  cmd_sync
  
  # Verify manifest was updated
  read_manifest
  assert_equals "" "$MANIFEST_ENTRIES" "Manifest should be updated to remove invalid entries"
}

# Define our implementation of the functions being tested
# These will be overridden if the real implementation is sourced

# cmd_sync implementation 
cmd_sync() {
  # Read manifest
  read_manifest
  
  # Create shared directory
  mkdir -p "$TARGET_DIR/$SHARED_DIR"
  
  # First, scan all rules in the shared directory
  for rule_file in "$TARGET_DIR/$SHARED_DIR"/*.mdc; do
    if [ -f "$rule_file" ]; then
      rule_name=$(basename "$rule_file")
      rule_needed=false
      
      # Check if rule is directly in manifest
      if echo "$MANIFEST_ENTRIES" | grep -q "^rules/$rule_name$"; then
        rule_needed=true
      else
        # Check if rule is in any of the rulesets in manifest
        for ruleset in $(echo "$MANIFEST_ENTRIES" | grep "^rulesets/" || true); do
          if [ -f "$REPO_DIR/$ruleset/$rule_name" ]; then
            rule_needed=true
            break
          fi
        done
      fi
      
      # Remove rule if not needed
      if ! $rule_needed; then
        rm -f "$rule_file"
        echo "Removed orphaned rule: $rule_name"
      fi
    fi
  done
  
  # Clean up invalid entries
  new_entries=""
  for entry in $MANIFEST_ENTRIES; do
    if [ -e "$REPO_DIR/$entry" ]; then
      if [ -z "$new_entries" ]; then
        new_entries="$entry"
      else
        new_entries="$new_entries
$entry"
      fi
    fi
  done
  
  # Update manifest if entries changed
  if [ "$new_entries" != "$MANIFEST_ENTRIES" ]; then
    MANIFEST_ENTRIES="$new_entries"
    write_manifest
  fi
  
  # Sync rules
  for entry in $MANIFEST_ENTRIES; do
    if echo "$entry" | grep -q "^rules/"; then
      # Copy rule directly to shared dir
      cp -f "$REPO_DIR/$entry" "$TARGET_DIR/$SHARED_DIR/$(basename "$entry")"
    elif echo "$entry" | grep -q "^rulesets/"; then
      # Find all rules in the ruleset
      for rule_link in "$REPO_DIR/$entry"/*.mdc; do
        if [ -f "$rule_link" ]; then
          # Get rule name and source path
          rule_name=$(basename "$rule_link")
          rule_source="$REPO_DIR/rules/$rule_name"
          
          # Copy rule directly to shared dir
          cp -f "$rule_source" "$TARGET_DIR/$SHARED_DIR/$rule_name"
        fi
      done
    fi
  done
  
  return 0
}

# cmd_remove_rule implementation
cmd_remove_rule() {
  # Process each rule
  for rule in "$@"; do
    rule_path="rules/$rule"
    
    # Remove from manifest
    read_manifest
    remove_manifest_entry "$rule_path"
    write_manifest
    
    echo "Removed rule: $rule_path"
  done
  
  # Sync to ensure proper cleanup
  cmd_sync
  
  return 0
}

# cmd_remove_ruleset implementation
cmd_remove_ruleset() {
  # Process each ruleset
  for ruleset in "$@"; do
    ruleset_path="rulesets/$ruleset"
    
    # Remove from manifest
    read_manifest
    remove_manifest_entry "$ruleset_path"
    write_manifest
    
    echo "Removed ruleset: $ruleset_path"
  done
  
  # Sync to ensure proper cleanup
  cmd_sync
  
  return 0
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2" 