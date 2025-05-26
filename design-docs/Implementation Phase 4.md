# AI-Rizz Implementation Phase 4 - Advanced Features (REVISED)

## Overview

Phase 4 implements only the essential features needed to achieve 100% unit test passing. Based on analysis of failing tests and user feedback, this focuses on **conflict resolution during sync** and **missing ruleset migration logic**.

## Current Status Analysis

**Test Results**: 6/8 test suites passing (75% pass rate)

**Failing Test Suites**:
1. `test_conflict_resolution.test.sh` - 5/10 tests failing
2. `test_error_handling.test.sh` - 6/18 tests failing

**Root Cause Analysis**:
- **Conflict Resolution**: Missing duplicate entry resolution during sync operations (the `test_resolve_duplicate_entries_commit_wins` test)
- **Ruleset Migration**: `cmd_add_ruleset()` has migration logic but it's not handling complex overlapping scenarios correctly
- **Error Handling**: Missing basic validation for corrupted manifests and invalid formats

## Phase 4 Implementation Plan

### Step 1: Enhanced Conflict Resolution Logic
**Objective**: Implement duplicate entry resolution during sync operations

**Issue**: The test `test_resolve_duplicate_entries_commit_wins()` manually adds a duplicate entry to the local manifest and expects `cmd_sync` to resolve it by removing the local duplicate (commit mode wins).

**Current Problem**: `sync_all_modes()` doesn't check for duplicates across manifests.

#### 1.1 Implement `resolve_conflicts()` Function
**Location**: Add to ai-rizz script in utilities section

```bash
# Detect and resolve conflicts (Phase 4)
# Committed mode wins, local entries silently removed
resolve_conflicts() {
    if [ "$HAS_COMMIT_MODE" = "false" ] || [ "$HAS_LOCAL_MODE" = "false" ]; then
        return 0  # No conflicts possible with single mode
    fi
    
    if [ ! -f "$COMMIT_MANIFEST_FILE" ] || [ ! -f "$LOCAL_MANIFEST_FILE" ]; then
        return 0  # Can't have conflicts if manifests don't exist
    fi
    
    # Get entries from both manifests
    commit_entries=$(read_manifest_entries "$COMMIT_MANIFEST_FILE" 2>/dev/null || true)
    
    if [ -n "$commit_entries" ]; then
        # For each commit entry, remove it from local manifest if it exists there
        echo "$commit_entries" | while IFS= read -r entry; do
            if [ -n "$entry" ]; then
                remove_manifest_entry_from_file "$LOCAL_MANIFEST_FILE" "$entry"
            fi
        done
    fi
}
```

#### 1.2 Integrate Conflict Resolution into Sync
**Location**: Modify `sync_all_modes()` function

```bash
# Enhanced sync_all_modes() with conflict resolution
sync_all_modes() {
    sync_success=true
    
    # Resolve conflicts first (commit mode wins)
    resolve_conflicts
    
    # Sync commit mode if initialized
    if [ "$HAS_COMMIT_MODE" = "true" ]; then
        sync_manifest_to_directory "$COMMIT_MANIFEST_FILE" "$COMMIT_TARGET_DIR/$SHARED_DIR" || sync_success=false
    fi
    
    # Sync local mode if initialized  
    if [ "$HAS_LOCAL_MODE" = "true" ]; then
        sync_manifest_to_directory "$LOCAL_MANIFEST_FILE" "$LOCAL_TARGET_DIR/$LOCAL_DIR" || sync_success=false
    fi
    
    # Handle any cleanup needed
    if [ "$sync_success" = "false" ]; then
        handle_sync_cleanup
    fi
}
```

### Step 2: Fix Ruleset Migration Logic
**Objective**: Fix the complex ruleset scenario in `test_migrate_complex_ruleset_scenario`

**Analysis**: The test scenario works as follows:
1. Add `ruleset1` (contains rule1, rule2) to local mode → local directory gets `rule1.mdc`, `rule2.mdc`
2. Add individual `rule3.mdc` to local mode → local directory gets `rule3.mdc`  
3. Add `ruleset2` (contains rule2, rule3) to commit mode → commit directory gets `rule2.mdc`, `rule3.mdc`
4. After sync, both directories have `rule2.mdc` and `rule3.mdc` (conflict!)

**Root Cause**: The current `cmd_add_ruleset()` logic is correct - it adds the ruleset entry and calls `sync_all_modes()`. However, the sync doesn't resolve conflicts between overlapping files from different rulesets.

**Solution**: The `resolve_conflicts()` function added in Step 1 should fix this. When `sync_all_modes()` runs after adding `ruleset2`, it will:
1. Copy `rule2.mdc` and `rule3.mdc` to commit directory (from `ruleset2`)
2. Call `resolve_conflicts()` which will remove duplicates from local directory
3. Result: `rule2.mdc` and `rule3.mdc` only in commit directory, `rule1.mdc` remains in local directory

**Expected**: No additional code needed - Step 1's conflict resolution should fix this test.

### Step 3: Enhanced Error Handling (Minimal)
**Objective**: Add only essential error handling for failing tests

#### 3.1 Manifest Validation (Minimal)
**Location**: Add to ai-rizz script in utilities section

```bash
# Validate manifest file format (minimal implementation)
validate_manifest_format() {
    manifest_file="$1"
    
    if [ ! -f "$manifest_file" ]; then
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$manifest_file" ]; then
        warn "Manifest file $manifest_file is empty"
        return 1
    fi
    
    # Check first line format
    first_line=$(head -n1 "$manifest_file")
    if ! echo "$first_line" | grep -q "	"; then
        warn "Invalid manifest format in $manifest_file: First line must be 'source_repo<tab>target_dir'"
        return 1
    fi
    
    return 0
}
```

#### 3.2 Integrate Validation into Manifest Reading
**Location**: Modify `read_manifest_entries()` and related functions to call validation

### Step 4: Investigation and Debugging
**Objective**: Understand why existing migration logic isn't working for the failing tests

Before implementing new code, let's debug the existing implementation:

1. **Check why `test_resolve_duplicate_entries_commit_wins` fails**: The sync should remove duplicates
2. **Check why `test_migrate_complex_ruleset_scenario` fails**: The ruleset migration should work
3. **Check why `test_migrate_updates_git_tracking` fails**: The git exclude logic should work

## Revised Implementation Steps Summary

1. **Step 1**: Implement `resolve_conflicts()` and integrate into sync operations
2. **Step 2**: Debug and fix existing ruleset migration logic (may not need new code)
3. **Step 3**: Add minimal error handling for manifest validation
4. **Step 4**: Debug and fix any remaining issues

## What We're NOT Implementing (Based on User Feedback)

- ❌ **`migrate_rule_mode()` function**: Redundant with existing `cmd_add_rule/ruleset` logic
- ❌ **Source repository validation**: Trust the user, let git handle URL validation
- ❌ **Concurrent modification detection**: ai-rizz is human-facing, one instance at a time
- ❌ **Complex git tracking updates**: Directory structure should handle this automatically
- ❌ **Enhanced ruleset migration logic**: Current logic should work, need to debug instead

## Expected Outcomes

After Phase 4 completion:
- ✅ **100% unit test passing rate** (8/8 test suites)
- ✅ **Duplicate entry resolution** during sync operations
- ✅ **Working ruleset migration** for complex scenarios
- ✅ **Basic error handling** for corrupted manifests
- ✅ **No unnecessary complexity** or redundant functions

## Success Criteria

Phase 4 is complete when:
1. All unit tests pass (8/8 test suites)
2. Duplicate entries are resolved correctly during sync
3. Complex ruleset scenarios work correctly
4. Basic manifest validation prevents crashes
5. No regressions in existing functionality
6. No unnecessary code added 