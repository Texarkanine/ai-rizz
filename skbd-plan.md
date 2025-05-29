# AI-Rizz Manifest Enhancement Plan

## Overview

This document outlines the plan for enhancing the AI-Rizz manifest format to support configurable paths for rules and rulesets, along with renaming the default manifest files.

## 🚧 IMPLEMENTATION PROGRESS REPORT (Current Status)

### ✅ **COMPLETED FEATURES**

#### 1. Core Manifest Format Enhancement
- **Status**: ✅ COMPLETE
- **Implementation**: Changed from 2-field to 4-field format
  - Old: `<source_repo>[TAB]<target_dir>`
  - New: `<source_repo>[TAB]<target_dir>[TAB]<rules_path>[TAB]<rulesets_path>`
- **Evidence**: Unit tests `test_manifest_format.test.sh` and `test_custom_path_operations.test.sh` passing

#### 2. Default Filename Changes  
- **Status**: ✅ COMPLETE
- **Implementation**: 
  - `ai-rizz.inf` → `ai-rizz.skbd`
  - `ai-rizz.local.inf` → `ai-rizz.local.skbd`
- **Evidence**: Hardcoded in global constants, all new manifests use .skbd extension

#### 3. Command-Line Arguments
- **Status**: ✅ COMPLETE  
- **Implementation**: Added `--rule-path` and `--ruleset-path` options to `cmd_init`
- **Evidence**: Custom path unit tests passing, arguments properly parsed and stored

#### 4. Path Construction with Variables
- **Status**: ✅ COMPLETE
- **Implementation**: 
  - Added `SOURCE_REPO_RULES_PATH` and `SOURCE_REPO_RULESETS_PATH` global variables
  - Replaced hardcoded "rules/" and "rulesets/" throughout codebase
  - Added `activate_local_mode_paths()` and `activate_commit_mode_paths()` functions
- **Evidence**: Custom path operations working in unit tests

#### 5. Backward Compatibility Reading
- **Status**: ✅ COMPLETE
- **Implementation**: `parse_manifest_metadata()` detects old vs new format by tab count
- **Evidence**: Can read both old 2-field and new 4-field manifests

#### 6. Enhanced Manifest Writing
- **Status**: ✅ COMPLETE
- **Implementation**: `write_manifest_with_entries()` supports optional rules/rulesets paths
- **Evidence**: All new manifests written in 4-field format with defaults

### ❌ **CRITICAL ISSUES IDENTIFIED**

#### 1. Integration Test Filename Mismatch
- **Problem**: Integration tests expect `.inf` files but implementation creates `.skbd` files
- **Impact**: 51 test failures across multiple integration test suites
- **Example Error**: `head: cannot open 'ai-rizz.local.inf' for reading: No such file or directory`
- **Root Cause**: Tests not updated to expect new filenames

#### 2. Integration Test Format Expectations  
- **Problem**: Tests expect old 2-field format but implementation uses 4-field format
- **Impact**: Manifest header assertion failures
- **Example Error**: 
  ```
  expected: <repo[TAB]target>
  actual:   <repo[TAB]target[TAB]rules[TAB]rulesets>
  ```
- **Root Cause**: Tests not updated for new format

#### 3. Inconsistent Test Expectations
- **Problem**: Some tests expect old behavior while implementation has new behavior
- **Impact**: Test failures across multiple suites
- **Root Cause**: Tests written for old format but not updated for new implementation

### 🧹 **HYGIENE ISSUES IDENTIFIED** 

#### 1. Redundant Path Activation Functions
- **Problem**: `activate_local_mode_paths()` and `activate_commit_mode_paths()` are wasteful
- **Current**: Two separate functions that just set two global variables each
- **Better**: Direct variable assignment where needed
- **Impact**: Unnecessary function call overhead and code bloat

#### 2. Manifest Function Duplication
- **Problem**: `parse_manifest_metadata()` and `read_manifest_metadata()` duplicate functionality
- **Current**: `parse_manifest_metadata` calls `read_manifest_metadata` then duplicates parsing logic
- **Better**: Consolidate into single, clear function hierarchy
- **Impact**: Code duplication and maintenance burden

#### 3. Lazy Init Could Reuse Manifest Functions
- **Problem**: `lazy_init_mode()` duplicates manifest reading/writing logic
- **Current**: Manual format detection and parsing in lazy_init_mode
- **Better**: Reuse existing `parse_manifest_metadata()` and `write_manifest_with_entries()`
- **Impact**: Code duplication and inconsistent behavior

#### 4. Incomplete Manifest Validation
- **Problem**: Only validates SOURCE_REPO matches between manifests, but entire header line must be identical
- **Current**: `validate_manifest_integrity()` only checks `COMMIT_SOURCE_REPO != LOCAL_SOURCE_REPO`
- **Required**: Both manifests must have identical header lines (source_repo, target_dir, rules_path, rulesets_path)
- **Impact**: Allows inconsistent configurations that should be errors

### 🔄 **PARTIALLY COMPLETE FEATURES**

#### 1. Automatic Manifest Upgrading
- **Status**: 🔄 PARTIAL - Logic exists but integration issues
- **Implementation**: `remove_manifest_entry_from_file()` upgrades old format to new
- **Issue**: May not be working properly with filename changes

#### 2. ~~Legacy Migration~~ **REMOVED FROM SCOPE**
- **Status**: ❌ **MISCONCEPTION** - Migration should NOT convert `.inf` → `.skbd`
- **Clarification**: If user has old `.inf` files with upgraded ai-rizz, they get an error message
- **Scope**: Auto-migration improvements are out of scope for this feature
- **Action Required**: Remove migration logic from current implementation plan

### 📋 **REMAINING WORK**

#### High Priority (Blocking)
1. **Fix Integration Test Expectations**
   - Update all integration tests to expect `.skbd` filenames instead of `.inf`
   - Update manifest format assertions to expect 4-field format
   - Update git exclude expectations

2. **Fix Hygiene Issues**
   - Remove redundant `activate_*_paths` functions
   - Consolidate `parse_manifest_metadata()` and `read_manifest_metadata()` duplication
   - Refactor `lazy_init_mode()` to reuse manifest functions
   - Enhance `validate_manifest_integrity()` to require identical header lines

3. **Resolve Test Consistency Issues**
   - Ensure all tests use consistent expectations for new format
   - Update any remaining hardcoded `.inf` references in tests
   - Fix migration test suite to match new behavior (no .inf → .skbd conversion)

#### Medium Priority  
4. **Validation & Edge Cases**
   - Test custom paths with spaces and special characters
   - Test deeply nested custom paths  
   - Verify manifest upgrade behavior in all scenarios

5. **Documentation Updates**
   - Update help text to show new command-line arguments (✅ appears complete)
   - Update README with custom path examples (not verified)

### 📊 **TEST SUITE STATUS**

**Passing (7/14 suites)**: ✅
- `unit/test_conflict_resolution.test.sh`
- `unit/test_custom_path_operations.test.sh` ⭐ (Core feature working)
- `unit/test_deinit_modes.test.sh`  
- `unit/test_error_handling.test.sh`
- `unit/test_lazy_initialization.test.sh`
- `unit/test_manifest_format.test.sh` ⭐ (Core feature working)
- `unit/test_mode_detection.test.sh`

**Failing (7/14 suites)**: ❌  
- `integration/test_cli_add_remove.test.sh` (20 failures)
- `integration/test_cli_deinit.test.sh` (12 failures)  
- `integration/test_cli_init.test.sh` (16 failures)
- `integration/test_cli_list_sync.test.sh` (3 failures)
- `unit/test_migration.test.sh` (32 failures) ⚠️ *Approach changing - no .inf→.skbd conversion*
- `unit/test_mode_operations.test.sh` (1 failure)
- `unit/test_progressive_init.test.sh` (2 failures)

### 🎯 **SUCCESS METRICS**

**Core Functionality**: ✅ 100% Complete
- Custom paths fully implemented and working
- New manifest format operational  
- Command-line arguments functional
- Path construction using variables

**Integration Readiness**: ❌ ~50% Complete  
- Core features work but integration tests need updating
- Migration logic needs fixes
- Test expectations need alignment

**Overall Progress**: 🔄 ~75% Complete
- Major implementation work done
- Primary remaining work is test fixes and migration logic

### 🔧 **IMMEDIATE ACTION PLAN**

#### Phase 1: Fix Integration Test Expectations (High Priority)

**Issue**: Integration tests expect old filenames (`.inf`) and old manifest format (2 fields)
**Files to Update**: All integration test files
**Required Changes**:

1. **Filename Updates** (Update these patterns in all integration tests):
   ```bash
   # OLD (failing)
   assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.inf' ]"
   assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.inf' ]"
   
   # NEW (required)  
   assertTrue "Local manifest should exist" "[ -f 'ai-rizz.local.skbd' ]"
   assertTrue "Commit manifest should exist" "[ -f 'ai-rizz.skbd' ]"
   ```

2. **Manifest Format Updates** (Update these patterns in all integration tests):
   ```bash
   # OLD (failing) - expects 2-field format
   assertEquals "Manifest header incorrect" "file://repo	.cursor/rules" "$first_line"
   
   # NEW (required) - expects 4-field format with defaults
   assertEquals "Manifest header incorrect" "file://repo	.cursor/rules	rules	rulesets" "$first_line"
   ```

3. **Git Exclude Updates**:
   ```bash
   # OLD (failing)
   assert_git_excludes "ai-rizz.local.inf"
   
   # NEW (required)
   assert_git_excludes "ai-rizz.local.skbd"
   ```

**Files to Update**:
- `tests/integration/test_cli_init.test.sh` ✏️
- `tests/integration/test_cli_add_remove.test.sh` ✏️  
- `tests/integration/test_cli_deinit.test.sh` ✏️
- `tests/integration/test_cli_list_sync.test.sh` ✏️

#### Phase 2: Fix Hygiene Issues (Critical)

**Issue**: Code contains redundant functions and duplication that impacts maintainability
**Required Changes**:

1. **Remove Redundant Path Activation Functions**:
   ```bash
   # OLD (wasteful) - Remove these functions entirely
   activate_local_mode_paths() { ... }
   activate_commit_mode_paths() { ... }
   
   # NEW (direct) - Replace calls with direct assignment
   SOURCE_REPO_RULES_PATH="${LOCAL_RULES_PATH}"
   SOURCE_REPO_RULESETS_PATH="${LOCAL_RULESETS_PATH}"
   ```

2. **Consolidate Manifest Function Duplication**:
   ```bash
   # REVIEW: parse_manifest_metadata() calls read_manifest_metadata() then duplicates parsing
   # SOLUTION: Streamline the function hierarchy or merge appropriately
   ```

3. **Refactor lazy_init_mode**:
   ```bash
   # OLD (duplicated) - Manual parsing in lazy_init_mode
   # NEW (reuse) - Use existing parse_manifest_metadata() and write_manifest_with_entries()
   ```

4. **Enhance Manifest Validation**:
   ```bash
   # OLD (incomplete) - Only checks source repo
   if [ "${COMMIT_SOURCE_REPO}" != "${LOCAL_SOURCE_REPO}" ]; then
   
   # NEW (complete) - Entire header line must match
   commit_header=$(read_manifest_metadata "${COMMIT_MANIFEST_FILE}")
   local_header=$(read_manifest_metadata "${LOCAL_MANIFEST_FILE}")
   if [ "${commit_header}" != "${local_header}" ]; then
   ```

**Files to Update**:
- `ai-rizz` main script functions
- `unit/test_migration.test.sh` expectations (no .inf → .skbd conversion)

#### Phase 3: Validation & Final Testing

1. **Run Full Test Suite**: Ensure all 14 test suites pass
2. **Manual Testing**: Verify end-to-end functionality with custom paths
3. **Backward Compatibility**: Test with existing `.inf` files
4. **Edge Cases**: Test custom paths with special characters

### 🚨 **CRITICAL DEPENDENCIES**

**Before proceeding with Phase 1**: Confirm the implementation behavior is correct:
- New manifests should use `.skbd` extension ✅ (Verified in code)
- New manifests should use 4-field format ✅ (Verified in code)  
- Old manifests should be readable ✅ (Unit tests passing)
- Migration should NOT convert `.inf` → `.skbd` ✅ (Clarified - out of scope)

**Risk Assessment**: Low risk - core functionality working, only test expectations and hygiene fixes needed

---

## Current vs. New Manifest Format

### Current Format
```
<source_repo>[TAB]<target_dir>
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

### New Format
```
<source_repo>[TAB]<target_dir>[TAB]path/to/rules[TAB]path/to/rulesets
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

## Implementation Plan

### 1. Test-Driven Development Approach

1. **Test Suite Preparation**
   - Create test cases for new manifest format parsing/writing
   - Develop tests for backward compatibility with old manifests
   - Build tests for new command-line arguments
   - Test custom paths work correctly in file operations

2. **Test Cases Required**
   - Test parsing of new format manifests
   - Test parsing of old format manifests (backward compatibility)
   - Test writing new format manifests
   - Test CLI with new arguments
   - Test rule operations with custom paths
   - Test ruleset operations with custom paths
   - Test mixed environment (old manifest in one mode, new in another)

### 2. Code Changes

#### 2.1 Manifest Handling

1. **Parsing Functions**
   - Update manifest parsing to handle additional fields
   - Add default values for rules/rulesets paths when not present
   - Set global variables for paths: `SOURCE_REPO_RULES_PATH` and `SOURCE_REPO_RULESETS_PATH`

2. **Writing Functions**
   - Modify manifest writing to include the new fields
   - Ensure old-format manifests are upgraded when written

#### 2.2 Command-Line Arguments

1. **New CLI Options**
   - Add `--rule-path <path>` option (default: "rules")
   - Add `--ruleset-path <path>` option (default: "rulesets")
   - Update help text and documentation

2. **Argument Parsing**
   - Update `parse_args` function to handle new options
   - Store values in appropriate variables

#### 2.3 Path Construction

1. **Rule Path Construction**
   - Replace hardcoded "rules/" with variable: `"${SOURCE_REPO_RULES_PATH}/"`
   - Find all instances like `cl_rule_path="rules/${cl_rule_name}"` and update

2. **Ruleset Path Construction**
   - Replace hardcoded "rulesets/" with variable: `"${SOURCE_REPO_RULESETS_PATH}/"`
   - Update all ruleset path constructions

#### 2.4 Default Filename Changes

1. **Update Default Filenames**
   - Change default from `ai-rizz.inf` to `ai-rizz.skbd`
   - Change default from `ai-rizz.local.inf` to `ai-rizz.local.skbd`
   - Update all references to these defaults

### 3. Backward Compatibility

1. **Reading Old Manifests**
   - Detect old format (fewer tab-separated fields)
   - Apply defaults for missing fields (rules="rules", rulesets="rulesets")

2. **Upgrading Manifests**
   - When writing to an old-format manifest, upgrade to new format
   - Preserve original source repo and target dir

### 4. Migration Considerations

1. **User Impact**
   - Existing manifests will continue to work (backward compatibility)
   - Users can gradually adopt new features
   - Document the new format and options

2. **Migration Path**
   - Automatic upgrade of manifests when modified
   - No manual migration required from users

### 5. Testing Strategy

#### 5.1 Unit Tests

1. **Manifest Parsing Tests**
   - Test parsing new format manifests
   - Test parsing old format manifests
   - Test default values when fields are missing

2. **Command-Line Argument Tests**
   - Test new arguments are correctly parsed
   - Test defaults when arguments are not provided

3. **Path Construction Tests**
   - Test rule paths are constructed correctly with custom paths
   - Test ruleset paths are constructed correctly with custom paths

#### 5.2 Integration Tests

1. **End-to-End Tests**
   - Test full workflow with new paths
   - Test backward compatibility scenarios
   - Test mixed environments (old and new manifests)

2. **Edge Cases**
   - Test with unusual paths (spaces, special characters)
   - Test with deeply nested paths
   - Test with empty paths (should revert to defaults)

## Detailed Test Plan

### Unit Tests

#### 1. Manifest Format Tests

```bash
# test_manifest_format.test.sh

test_read_new_manifest_format() {
  # Create a new format manifest file
  echo "https://example.com/repo.git	.cursor/rules	custom_rules	custom_rulesets" > test_manifest.skbd
  echo "custom_rules/test-rule.mdc" >> test_manifest.skbd
  
  # Test parsing
  source_metadata="$(read_manifest_metadata test_manifest.skbd)"
  
  # Extract values
  source_repo=$(echo "$source_metadata" | cut -f1)
  target_dir=$(echo "$source_metadata" | cut -f2)
  rules_path=$(echo "$source_metadata" | cut -f3)
  rulesets_path=$(echo "$source_metadata" | cut -f4)
  
  # Assertions
  assertEquals "https://example.com/repo.git" "$source_repo"
  assertEquals ".cursor/rules" "$target_dir"
  assertEquals "custom_rules" "$rules_path"
  assertEquals "custom_rulesets" "$rulesets_path"
  
  # Clean up
  rm test_manifest.skbd
}

test_read_old_manifest_format() {
  # Create an old format manifest file
  echo "https://example.com/repo.git	.cursor/rules" > test_manifest.inf
  echo "rules/test-rule.mdc" >> test_manifest.inf
  
  # Test parsing
  source_metadata="$(read_manifest_metadata test_manifest.inf)"
  
  # Ensure defaults are applied
  assertEquals "rules" "$SOURCE_REPO_RULES_PATH"
  assertEquals "rulesets" "$SOURCE_REPO_RULESETS_PATH"
  
  # Clean up
  rm test_manifest.inf
}

test_write_manifest_with_custom_paths() {
  # Test writing a manifest with custom paths
  echo "" | write_manifest_with_entries "test_write.skbd" "https://example.com/repo.git" ".cursor/rules" "docs" "examples"
  
  # Read and verify
  first_line=$(head -n 1 test_write.skbd)
  assertEquals "https://example.com/repo.git	.cursor/rules	docs	examples" "$first_line"
  
  # Clean up
  rm test_write.skbd
}
```

#### 2. Command-Line Argument Tests

```bash
# test_cli_arguments.test.sh

test_rule_path_argument() {
  # Test --rule-path argument
  output=$(cmd_init "https://example.com/repo.git" --local --rule-path "docs")
  
  # Verify custom path is used
  assertEquals "docs" "$SOURCE_REPO_RULES_PATH"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}

test_ruleset_path_argument() {
  # Test --ruleset-path argument
  output=$(cmd_init "https://example.com/repo.git" --local --ruleset-path "examples")
  
  # Verify custom path is used
  assertEquals "examples" "$SOURCE_REPO_RULESETS_PATH"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}

test_both_custom_paths() {
  # Test both custom paths
  output=$(cmd_init "https://example.com/repo.git" --local --rule-path "docs" --ruleset-path "examples")
  
  # Verify custom paths are used
  assertEquals "docs" "$SOURCE_REPO_RULES_PATH"
  assertEquals "examples" "$SOURCE_REPO_RULESETS_PATH"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}

test_default_paths() {
  # Test default paths when arguments not provided
  output=$(cmd_init "https://example.com/repo.git" --local)
  
  # Verify defaults are used
  assertEquals "rules" "$SOURCE_REPO_RULES_PATH"
  assertEquals "rulesets" "$SOURCE_REPO_RULESETS_PATH"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}
```

#### 3. Rule/Ruleset Operation Tests

```bash
# test_custom_path_operations.test.sh

test_add_rule_with_custom_path() {
  # Initialize with custom rule path
  cmd_init "https://example.com/repo.git" --local --rule-path "docs"
  
  # Mock the rule in the repository
  mkdir -p "$REPO_DIR/docs"
  touch "$REPO_DIR/docs/test-rule.mdc"
  
  # Add the rule
  cmd_add_rule "test-rule.mdc" "local"
  
  # Verify rule path construction is correct
  grep -q "docs/test-rule.mdc" "$LOCAL_MANIFEST_FILE"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}

test_add_ruleset_with_custom_path() {
  # Initialize with custom ruleset path
  cmd_init "https://example.com/repo.git" --local --ruleset-path "examples"
  
  # Mock the ruleset in the repository
  mkdir -p "$REPO_DIR/examples/test-ruleset"
  touch "$REPO_DIR/examples/test-ruleset/rule1.mdc"
  
  # Add the ruleset
  cmd_add_ruleset "test-ruleset" "local"
  
  # Verify ruleset path construction is correct
  grep -q "examples/test-ruleset" "$LOCAL_MANIFEST_FILE"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}
```

### Integration Tests

```bash
# test_integration.test.sh

test_full_workflow_with_custom_paths() {
  # Initialize with custom paths
  cmd_init "https://example.com/repo.git" --local --rule-path "docs" --ruleset-path "examples"
  
  # Mock repository content
  mkdir -p "$REPO_DIR/docs"
  mkdir -p "$REPO_DIR/examples/test-ruleset"
  touch "$REPO_DIR/docs/test-rule.mdc"
  touch "$REPO_DIR/examples/test-ruleset/rule1.mdc"
  
  # Add rule and ruleset
  cmd_add_rule "test-rule.mdc" "local"
  cmd_add_ruleset "test-ruleset" "local"
  
  # List and verify
  output=$(cmd_list)
  echo "$output" | grep -q "test-rule.mdc"
  echo "$output" | grep -q "test-ruleset"
  
  # Remove rule
  cmd_remove_rule "test-rule.mdc"
  output=$(cmd_list)
  echo "$output" | grep -qv "◐ test-rule.mdc"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}

test_backward_compatibility() {
  # Create old-style manifest
  mkdir -p ".cursor/rules/local"
  echo "https://example.com/repo.git	.cursor/rules" > ai-rizz.local.inf
  echo "rules/test-rule.mdc" >> ai-rizz.local.inf
  
  # List and verify rule is detected
  output=$(cmd_list)
  echo "$output" | grep -q "test-rule.mdc"
  
  # Add a new rule (should upgrade the manifest)
  mkdir -p "$REPO_DIR/rules"
  touch "$REPO_DIR/rules/new-rule.mdc"
  cmd_add_rule "new-rule.mdc" "local"
  
  # Verify manifest upgraded
  first_line=$(head -n 1 ai-rizz.local.inf)
  echo "$first_line" | grep -q "https://example.com/repo.git	.cursor/rules	rules	rulesets"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}

test_mixed_environment() {
  # Create old-style local manifest
  mkdir -p ".cursor/rules/local"
  echo "https://example.com/repo.git	.cursor/rules" > ai-rizz.local.inf
  echo "rules/local-rule.mdc" >> ai-rizz.local.inf
  
  # Create new-style commit manifest
  mkdir -p ".cursor/rules/shared"
  echo "https://example.com/repo.git	.cursor/rules	docs	examples" > ai-rizz.inf
  echo "docs/commit-rule.mdc" >> ai-rizz.inf
  
  # List and verify both rules detected
  output=$(cmd_list)
  echo "$output" | grep -q "local-rule.mdc"
  echo "$output" | grep -q "commit-rule.mdc"
  
  # Add a rule to local (should upgrade the manifest)
  mkdir -p "$REPO_DIR/rules"
  touch "$REPO_DIR/rules/new-local-rule.mdc"
  cmd_add_rule "new-local-rule.mdc" "local"
  
  # Verify local manifest upgraded
  first_line=$(head -n 1 ai-rizz.local.inf)
  echo "$first_line" | grep -q "https://example.com/repo.git	.cursor/rules	rules	rulesets"
  
  # Clean up
  cmd_deinit --all -y >/dev/null 2>&1
}
```

## Implementation Details

### 1. Global Variable Additions

Add new global variables to store the configurable paths:

```bash
# Configuration constants
COMMIT_MANIFEST_FILE="ai-rizz.skbd"                 # Changed from ai-rizz.inf
LOCAL_MANIFEST_FILE="ai-rizz.local.skbd"            # Changed from ai-rizz.local.inf
SHARED_DIR="shared"
LOCAL_DIR="local" 
CONFIG_DIR="$HOME/.config/ai-rizz"
DEFAULT_TARGET_DIR=".cursor/rules"
DEFAULT_RULES_PATH="rules"                          # Added for default rules path
DEFAULT_RULESETS_PATH="rulesets"                    # Added for default rulesets path

# Cached manifest metadata (set during initialization for efficiency)
COMMIT_SOURCE_REPO=""
LOCAL_SOURCE_REPO=""
COMMIT_TARGET_DIR=""
LOCAL_TARGET_DIR=""
COMMIT_RULES_PATH=""                                # Added for commit mode rules path
LOCAL_RULES_PATH=""                                 # Added for local mode rules path
COMMIT_RULESETS_PATH=""                             # Added for commit mode rulesets path
LOCAL_RULESETS_PATH=""                              # Added for local mode rulesets path

# Active paths (used for path construction)
SOURCE_REPO_RULES_PATH=""                           # Added for current operation
SOURCE_REPO_RULESETS_PATH=""                        # Added for current operation
```

### 2. Function Modifications

#### 2.1 Update `read_manifest_metadata()` Function

```bash
read_manifest_metadata() {
    rmm_manifest_file="${1}"
    
    if [ ! -f "${rmm_manifest_file}" ]; then
        return 1
    fi
    
    # Read first line
    read -r rmm_first_line < "${rmm_manifest_file}"
    
    # Validate format - must have at least one tab
    if ! echo "${rmm_first_line}" | grep -q "	"; then
        error "Invalid manifest format in ${rmm_manifest_file}: First line must be 'source_repo<tab>target_dir[<tab>rules_path<tab>rulesets_path]'"
    fi
    
    echo "${rmm_first_line}"
}
```

#### 2.2 Update `write_manifest_with_entries()` Function

```bash
write_manifest_with_entries() {
    wmwe_manifest_file="${1}"
    wmwe_source_repo="${2}"
    wmwe_target_dir="${3}"
    wmwe_rules_path="${4:-rules}"         # Default to "rules" if not provided
    wmwe_rulesets_path="${5:-rulesets}"    # Default to "rulesets" if not provided
    
    # Write header with all fields (new format)
    echo "${wmwe_source_repo}	${wmwe_target_dir}	${wmwe_rules_path}	${wmwe_rulesets_path}" > "${wmwe_manifest_file}"
    
    # Read from stdin and append if there's content
    while IFS= read -r wmwe_line; do
        if [ -n "${wmwe_line}" ]; then
            echo "${wmwe_line}" >> "${wmwe_manifest_file}"
        fi
    done
}
```

#### 2.3 Update `remove_manifest_entry_from_file()` Function

```bash
remove_manifest_entry_from_file() {
    rmeff_local_manifest_file="${1}"
    rmeff_entry="${2}"
    
    if [ ! -f "${rmeff_local_manifest_file}" ]; then
        return 0  # Nothing to remove
    fi
    
    # Get metadata
    if ! rmeff_metadata=$(read_manifest_metadata "${rmeff_local_manifest_file}"); then
        error "Failed to read manifest metadata from ${rmeff_local_manifest_file}"
    fi
    
    # Get entries excluding the one to remove
    rmeff_entries=$(read_manifest_entries "${rmeff_local_manifest_file}" | grep -v "^${rmeff_entry}$" || true)
    
    # Count tabs to determine format version
    rmeff_tab_count=$(echo "${rmeff_metadata}" | tr -cd '\t' | wc -c)
    
    # Extract fields based on format
    rmeff_source_repo=$(echo "${rmeff_metadata}" | cut -f1)
    rmeff_target_dir=$(echo "${rmeff_metadata}" | cut -f2)
    
    if [ "${rmeff_tab_count}" -eq 1 ]; then
        # Old format - upgrade to new format with defaults
        rmeff_rules_path="rules"
        rmeff_rulesets_path="rulesets"
    else
        # New format - extract values
        rmeff_rules_path=$(echo "${rmeff_metadata}" | cut -f3)
        rmeff_rulesets_path=$(echo "${rmeff_metadata}" | cut -f4)
    fi
    
    # Write header with all fields (new format)
    echo "${rmeff_source_repo}	${rmeff_target_dir}	${rmeff_rules_path}	${rmeff_rulesets_path}" > "${rmeff_local_manifest_file}"
    
    # Append entries if any exist
    if [ -n "${rmeff_entries}" ]; then
        echo "${rmeff_entries}" >> "${rmeff_local_manifest_file}"
    fi
}
```

#### 2.4 Update `cmd_init()` Function

```bash
cmd_init() {
    ci_source_repo=""
    ci_target_dir=""
    ci_mode=""
    ci_rule_path=""
    ci_ruleset_path=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -d)
                ci_target_dir="$2"
                shift 2
                ;;
            --local|-l)
                ci_mode="local"
                shift
                ;;
            --commit|-c)
                ci_mode="commit"
                shift
                ;;
            --rule-path)
                ci_rule_path="$2"
                shift 2
                ;;
            --ruleset-path)
                ci_ruleset_path="$2"
                shift 2
                ;;
            *)
                if [ -z "${ci_source_repo}" ]; then
                    ci_source_repo="$1"
                    shift
                else
                    error "Unknown argument: $1"
                fi
                ;;
        esac
    done
    
    # Use defaults if not provided
    if [ -z "${ci_rule_path}" ]; then
        ci_rule_path="${DEFAULT_RULES_PATH}"
    fi
    
    if [ -z "${ci_ruleset_path}" ]; then
        ci_ruleset_path="${DEFAULT_RULESETS_PATH}"
    fi
    
    # Rest of function remains similar, but use the new variables for manifest creation
    
    # Initialize the requested mode
    case "${ci_mode}" in
        local)
            # Create local mode structure
            mkdir -p "${ci_target_dir}/${LOCAL_DIR}"
            
            # Write empty manifest with metadata (including new fields)
            echo "" | write_manifest_with_entries "${LOCAL_MANIFEST_FILE}" "${ci_source_repo}" "${ci_target_dir}" "${ci_rule_path}" "${ci_ruleset_path}"
            
            # Update git excludes
            setup_local_mode_excludes "${ci_target_dir}"
            
            # Update mode state and cache
            HAS_LOCAL_MODE=true
            LOCAL_SOURCE_REPO="${ci_source_repo}"
            LOCAL_TARGET_DIR="${ci_target_dir}"
            LOCAL_RULES_PATH="${ci_rule_path}"
            LOCAL_RULESETS_PATH="${ci_ruleset_path}"
            ;;
            
        commit)
            # Create commit mode structure  
            mkdir -p "${ci_target_dir}/${SHARED_DIR}"
            
            # Write empty manifest with metadata (including new fields)
            echo "" | write_manifest_with_entries "${COMMIT_MANIFEST_FILE}" "${ci_source_repo}" "${ci_target_dir}" "${ci_rule_path}" "${ci_ruleset_path}"
            
            # Update mode state and cache
            HAS_COMMIT_MODE=true
            COMMIT_SOURCE_REPO="${ci_source_repo}"
            COMMIT_TARGET_DIR="${ci_target_dir}"
            COMMIT_RULES_PATH="${ci_rule_path}"
            COMMIT_RULESETS_PATH="${ci_ruleset_path}"
            ;;
    esac
    
    echo "Initialized ai-rizz with\n\tsource: ${ci_source_repo}\n\ttarget: ${ci_target_dir}\n\tmode: ${ci_mode}\n\trules path: ${ci_rule_path}\n\trulesets path: ${ci_ruleset_path}"
    return 0
}
```

#### 2.5 Update Path Construction Throughout Codebase

Replace all hardcoded path prefixes with the appropriate variables:

```bash
# Before
cl_rule_path="rules/${cl_rule_name}"
cars_ruleset_path="rulesets/${cars_ruleset_name}"

# After
cl_rule_path="${SOURCE_REPO_RULES_PATH}/${cl_rule_name}"
cars_ruleset_path="${SOURCE_REPO_RULESETS_PATH}/${cars_ruleset_name}"
```

#### 2.6 Update Command Mode Activation Functions

Update the functions that set active paths based on mode:

```bash
activate_local_mode() {
    # Set active paths to local mode values
    SOURCE_REPO_RULES_PATH="${LOCAL_RULES_PATH}"
    SOURCE_REPO_RULESETS_PATH="${LOCAL_RULESETS_PATH}"
}

activate_commit_mode() {
    # Set active paths to commit mode values
    SOURCE_REPO_RULES_PATH="${COMMIT_RULES_PATH}"
    SOURCE_REPO_RULESETS_PATH="${COMMIT_RULESETS_PATH}"
}
```

### 3. Helper Functions for Manifest Format Handling

Add a new function to parse manifest metadata and set global variables:

```bash
parse_manifest_metadata() {
    pmm_manifest_file="${1}"
    pmm_mode="${2}"  # "local" or "commit"
    
    if [ ! -f "${pmm_manifest_file}" ]; then
        return 1
    fi
    
    # Read metadata line
    pmm_metadata=$(read_manifest_metadata "${pmm_manifest_file}")
    
    # Count tabs to determine format version
    pmm_tab_count=$(echo "${pmm_metadata}" | tr -cd '\t' | wc -c)
    
    # Extract fields based on format
    pmm_source_repo=$(echo "${pmm_metadata}" | cut -f1)
    pmm_target_dir=$(echo "${pmm_metadata}" | cut -f2)
    
    if [ "${pmm_tab_count}" -eq 1 ]; then
        # Old format - use defaults
        pmm_rules_path="${DEFAULT_RULES_PATH}"
        pmm_rulesets_path="${DEFAULT_RULESETS_PATH}"
    else
        # New format - extract values
        pmm_rules_path=$(echo "${pmm_metadata}" | cut -f3)
        pmm_rulesets_path=$(echo "${pmm_metadata}" | cut -f4)
    fi
    
    # Set global variables based on mode
    case "${pmm_mode}" in
        local)
            LOCAL_SOURCE_REPO="${pmm_source_repo}"
            LOCAL_TARGET_DIR="${pmm_target_dir}"
            LOCAL_RULES_PATH="${pmm_rules_path}"
            LOCAL_RULESETS_PATH="${pmm_rulesets_path}"
            ;;
        commit)
            COMMIT_SOURCE_REPO="${pmm_source_repo}"
            COMMIT_TARGET_DIR="${pmm_target_dir}"
            COMMIT_RULES_PATH="${pmm_rules_path}"
            COMMIT_RULESETS_PATH="${pmm_rulesets_path}"
            ;;
    esac
    
    return 0
}
```

### 4. Initialize Variables in Main Script

Ensure all variables are properly initialized in the main script body:

```bash
# Initialize paths to defaults
SOURCE_REPO_RULES_PATH="${DEFAULT_RULES_PATH}"
SOURCE_REPO_RULESETS_PATH="${DEFAULT_RULESETS_PATH}"
LOCAL_RULES_PATH="${DEFAULT_RULES_PATH}"
LOCAL_RULESETS_PATH="${DEFAULT_RULESETS_PATH}"
COMMIT_RULES_PATH="${DEFAULT_RULES_PATH}"
COMMIT_RULESETS_PATH="${DEFAULT_RULESETS_PATH}"
```

## Documentation Updates

### README.md Updates

The README.md file needs to be updated to reflect the new options and manifest format. Here are the specific sections that need to be modified:

#### 1. Update Usage Section

```markdown
```
Usage: ai-rizz <command> [command-specific options]

Available commands:
  init [<source_repo>]     Initialize one mode in the repository
  deinit                   Deinitialize mode(s) from the repository
  list                     List available rules/rulesets with status
  add rule <rule>...       Add rule(s) to the repository
  add ruleset <ruleset>... Add ruleset(s) to the repository
  remove rule <rule>...    Remove rule(s) from the repository
  remove ruleset <ruleset>... Remove ruleset(s) from the repository
  sync                     Sync all initialized modes
  help                     Show this help

Command-specific options:
  init options:
    -c, --commit           Initialize commit mode (git-tracked)
    -d <target_dir>        Target directory (default: .cursor/rules)
    -f, --manifest <file>  Alias for --skibidi
    -l, --local            Initialize local mode (git-ignored)
    -s, --skibidi <file>   Use custom manifest filename
    --rule-path <path>     Source repository rules path (default: rules)
    --ruleset-path <path>  Source repository rulesets path (default: rulesets)

  add options:
    -c, --commit           Add to commit mode (auto-initializes if needed)
    -l, --local            Add to local mode (auto-initializes if needed)

  deinit options:
    -a, --all              Remove both modes completely
    -c, --commit           Remove commit mode only
    -l, --local            Remove local mode only
    -y                     Skip confirmation prompts
```
```

#### 2. Add New Example to Common Recipes Section

```markdown
**Custom path setup:**
```bash
# Use custom paths for rules and rulesets
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local --rule-path docs --ruleset-path collections
ai-rizz add rule project-standards.mdc      # Will look in docs/ directory
ai-rizz add ruleset web-development         # Will look in collections/ directory
```
```

#### 3. Add New Section to Advanced Usage

```markdown
### Custom Paths Configuration

ai-rizz allows customizing the source repository paths for rules and rulesets:

#### Repository Structure with Custom Paths

If your source repository uses non-standard paths:

```
docs/                      # Custom rules directory
├── project-standards.mdc
├── code-review.mdc
└── documentation.mdc

collections/              # Custom rulesets directory
├── web/
│   ├── html-style.mdc
│   ├── css-best-practices.mdc
│   └── javascript-patterns.mdc
└── backend/
    ├── api-design.mdc
    ├── database-patterns.mdc
    └── security-checklist.mdc
```

You can configure ai-rizz to use these paths:

```bash
# Initialize with custom paths
ai-rizz init https://example.com/repo.git --local --rule-path docs --ruleset-path collections

# Add rules and rulesets
ai-rizz add rule project-standards.mdc       # Looks in docs/
ai-rizz add ruleset web                      # Looks in collections/
```

#### Manifest Format with Custom Paths

The manifest file includes the custom paths:

```
https://example.com/repo.git[TAB].cursor/rules[TAB]docs[TAB]collections
docs/project-standards.mdc
collections/web
```

#### Backward Compatibility

When a repository has existing manifests with the old format, ai-rizz will:

1. Detect the old format automatically
2. Use default paths ("rules" and "rulesets")
3. Upgrade to new format on next write operation

```

#### 4. Update Developer Guide Section

```markdown
#### Manifest File Schema

Both manifest files use the same format:

**New Format (ai-rizz.skbd / ai-rizz.local.skbd):**
```
<source_repo>[TAB]<target_dir>[TAB]<rules_path>[TAB]<rulesets_path>
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

**Legacy Format (ai-rizz.inf / ai-rizz.local.inf):**
```
<source_repo>[TAB]<target_dir>
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

- First line: metadata including source repository URL, target directory, and paths
- Subsequent lines: installed rules/rulesets (one per line)
- Rule entries: path prefix + filename (matching configured rules_path)
- Ruleset entries: path prefix + name (matching configured rulesets_path)
```

### Script Help Text Updates

The script's help text also needs to be updated to include the new options:

```bash
show_help() {
    cat << EOF
Usage: ai-rizz <command> [command-specific options]

Available commands:
  init [<source_repo>]     Initialize one mode in the repository
  deinit                   Deinitialize mode(s) from the repository
  list                     List available rules/rulesets with status
  add rule <rule>...       Add rule(s) to the repository
  add ruleset <ruleset>... Add ruleset(s) to the repository
  remove rule <rule>...    Remove rule(s) from the repository
  remove ruleset <ruleset>... Remove ruleset(s) from the repository
  sync                     Sync all initialized modes
  help                     Show this help

Command-specific options:
  init options:
    -c, --commit           Initialize commit mode (git-tracked)
    -d <target_dir>        Target directory (default: .cursor/rules)
    -f, --manifest <file>  Alias for --skibidi
    -l, --local            Initialize local mode (git-ignored)
    -s, --skibidi <file>   Use custom manifest filename
    --rule-path <path>     Source repository rules path (default: rules)
    --ruleset-path <path>  Source repository rulesets path (default: rulesets)

  add options:
    -c, --commit           Add to commit mode (auto-initializes if needed)
    -l, --local            Add to local mode (auto-initializes if needed)

  deinit options:
    -a, --all              Remove both modes completely
    -c, --commit           Remove commit mode only
    -l, --local            Remove local mode only
    -y                     Skip confirmation prompts
EOF
}
```

## Implementation Order

1. Update manifest parsing to handle new format (with backward compatibility)
2. Add new command-line arguments
3. Update path construction throughout codebase
4. Update manifest writing to use new format
5. Change default filenames
6. Complete test suite
7. Update documentation

## Code Examples

### Manifest Parsing

```bash
parse_manifest() {
    local manifest_file="$1"
    if [ -f "$manifest_file" ]; then
        # Read first line to get configuration
        local first_line
        first_line=$(head -n 1 "$manifest_file")
        
        # Count tabs to determine format version
        local tab_count
        tab_count=$(echo "$first_line" | tr -cd '\t' | wc -c)
        
        if [ "$tab_count" -eq 1 ]; then
            # Old format: <source_repo>\t<target_dir>
            SOURCE_REPO=$(echo "$first_line" | cut -f 1)
            TARGET_DIR=$(echo "$first_line" | cut -f 2)
            SOURCE_REPO_RULES_PATH="rules"
            SOURCE_REPO_RULESETS_PATH="rulesets"
        else
            # New format: <source_repo>\t<target_dir>\t<rules_path>\t<rulesets_path>
            SOURCE_REPO=$(echo "$first_line" | cut -f 1)
            TARGET_DIR=$(echo "$first_line" | cut -f 2)
            SOURCE_REPO_RULES_PATH=$(echo "$first_line" | cut -f 3)
            SOURCE_REPO_RULESETS_PATH=$(echo "$first_line" | cut -f 4)
        fi
    fi
}
```

### Path Construction

```bash
# Before
cl_rule_path="rules/${cl_rule_name}"

# After
cl_rule_path="${SOURCE_REPO_RULES_PATH}/${cl_rule_name}"
```

### Command-Line Argument Handling

```bash
parse_init_args() {
    # Existing argument handling...
    
    # New arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --rule-path)
                shift
                RULE_PATH="$1"
                ;;
            --ruleset-path)
                shift
                RULESET_PATH="$1"
                ;;
            # Existing cases...
        esac
        shift
    done
    
    # Set defaults if not specified
    RULE_PATH="${RULE_PATH:-rules}"
    RULESET_PATH="${RULESET_PATH:-rulesets}"
}
```

## Timeline

1. **Day 1**: Set up test framework for new features
2. **Day 2**: Implement manifest parsing changes and command-line arguments
3. **Day 3**: Update path construction and manifest writing
4. **Day 4**: Change default filenames and finalize tests
5. **Day 5**: Update documentation and perform final testing 