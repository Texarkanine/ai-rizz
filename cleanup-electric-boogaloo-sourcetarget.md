# AI-Rizz Variable Consolidation Plan: Repository and Target Variables

## Executive Summary

This plan outlines the process to consolidate mode-specific repository variables (`LOCAL_SOURCE_REPO`/`COMMIT_SOURCE_REPO` and `LOCAL_TARGET_DIR`/`COMMIT_TARGET_DIR`) into single global variables (`SOURCE_REPO` and `TARGET_DIR`). The consolidation will simplify the codebase, reduce duplication, and make the code more maintainable while preserving all existing functionality and error handling.

## 1. Current State Analysis

### 1.1 Existing Mode-Specific Variables

Currently, the codebase maintains separate variables for local and commit modes:

```sh
# Local mode variables
LOCAL_SOURCE_REPO=""
LOCAL_TARGET_DIR=""

# Commit mode variables  
COMMIT_SOURCE_REPO=""
COMMIT_TARGET_DIR=""
```

These variables store identical values across modes, as noted in the comment at line 380:

```sh
# Note: We keep separate variables per mode even though they have the same values.
# This allows code to reference LOCAL_SOURCE_REPO or COMMIT_SOURCE_REPO based on context
# without having to track which mode is currently active. The redundancy makes the code
# more readable and less prone to bugs.
```

### 1.2 Current Initialization Pattern

Based on context, these variables are initialized in `parse_manifest_metadata()`:

```sh
parse_manifest_metadata() {
    # ... function code ...
    
    # Set mode-specific variables
    LOCAL_SOURCE_REPO="${pmm_source_repo}"
    LOCAL_TARGET_DIR="${pmm_target_dir}"
    COMMIT_SOURCE_REPO="${pmm_source_repo}"
    COMMIT_TARGET_DIR="${pmm_target_dir}"
}
```

### 1.3 Existing Unified Variables Pattern

The codebase already uses unified variables for paths within the repository:

```sh
# Source repository paths (set during initialization, identical across modes)
RULES_PATH=""        # Rules path from manifest
RULESETS_PATH=""     # Rulesets path from manifest
```

### 1.4 Manifest Integrity Check

The codebase includes manifest integrity checking to ensure both manifests (local and commit) have matching values. This is crucial functionality that must be preserved.

## 2. Proposed Changes

### 2.1 New Global Variables

Define two new global variables at the top of the script:

```sh
# Source repository information (set during initialization)
SOURCE_REPO=""      # Source repository URL
TARGET_DIR=""       # Target directory for rules
```

### 2.2 Initialization Changes

Modify `parse_manifest_metadata()` to set the new unified variables:

```sh
parse_manifest_metadata() {
    # ... existing code ...
    
    # Set unified variables
    SOURCE_REPO="${pmm_source_repo}"
    TARGET_DIR="${pmm_target_dir}"
    
    # For backward compatibility, keep setting mode-specific variables
    # These will be phased out in a future update
    LOCAL_SOURCE_REPO="${pmm_source_repo}"
    LOCAL_TARGET_DIR="${pmm_target_dir}"
    COMMIT_SOURCE_REPO="${pmm_source_repo}"
    COMMIT_TARGET_DIR="${pmm_target_dir}"
}
```

### 2.3 Manifest Integrity Check Preservation

The manifest integrity check will still function properly as it compares the values between modes before they're assigned to the unified variables. We'll ensure this is preserved through careful refactoring.

## 3. Implementation Scope and Breadth

### 3.1 Files and Functions to Modify

Based on the context provided, we'll need to:

1. **Modify Global Variable Declarations**:
   - Add new unified variables
   - Update documentation for existing variables

2. **Update Initialization Functions**:
   - Modify `parse_manifest_metadata()` to set the new unified variables
   - Ensure `initialize_ai_rizz()` handles the new variables correctly

3. **Replace Variable References**:
   - Identify all instances where mode-specific variables are referenced
   - Replace with unified variables where appropriate
   - Keep mode-specific logic where truly needed

4. **Update Documentation**:
   - Update all function headers that reference the old variables
   - Update comments explaining the variable consolidation strategy

5. **Preserve Error Handling**:
   - Ensure manifest integrity checks still function properly
   - Validate that error messages remain accurate

### 3.2 Functions Likely to Require Changes

Based on the provided context and common patterns in shell scripts, these functions will likely need modification:

1. **Initialization Functions**:
   - `initialize_ai_rizz()`
   - `parse_manifest_metadata()`
   - `ensure_initialized()`
   - `ensure_initialized_and_valid()`

2. **Command Functions**:
   - `cmd_init()`
   - `cmd_sync()`
   - `cmd_add_rule()`
   - `cmd_add_ruleset()`
   - `cmd_remove_rule()`
   - `cmd_remove_ruleset()`
   - `cmd_list()`
   - `cmd_deinit()`
   - Any other command functions that reference these variables

3. **Helper Functions**:
   - `show_manifest_integrity_error()`
   - `get_manifest_and_target()`
   - Any other helpers that work with manifests or repository paths

### 3.3 Estimated Change Scope

Based on the note that this consolidation "would require extensive changes throughout the codebase," we estimate:

- **~15-25 functions** will need modification
- **~50-100 lines** of code will be changed
- **~5-10 documentation blocks** will need updates

## 4. Implementation Strategy

### 4.1 Phased Approach

To minimize risk, we'll implement this change in phases:

#### Phase 1: Add Unified Variables (Parallel Implementation)
- Add new unified variables to the global scope
- Modify initialization functions to set both unified and mode-specific variables
- Add comments marking mode-specific variables as deprecated

#### Phase 2: Function Conversion
- Modify functions one by one to use the unified variables
- Update documentation for each modified function
- Maintain backward compatibility by preserving mode-specific variables

#### Phase 3: Clean-up and Finalization
- Remove backward compatibility layer once all functions use unified variables
- Update any remaining documentation
- Run final validation tests

### 4.2 Detailed Implementation Steps

1. **Add Unified Variables**:
   ```sh
   # Add to global variable section
   SOURCE_REPO=""      # Source repository URL
   TARGET_DIR=""       # Target directory for rules
   ```

2. **Update Initialization**:
   ```sh
   # Modify parse_manifest_metadata()
   SOURCE_REPO="${pmm_source_repo}"
   TARGET_DIR="${pmm_target_dir}"
   
   # Keep mode-specific variables for backward compatibility
   LOCAL_SOURCE_REPO="${pmm_source_repo}"
   LOCAL_TARGET_DIR="${pmm_target_dir}"
   COMMIT_SOURCE_REPO="${pmm_source_repo}"
   COMMIT_TARGET_DIR="${pmm_target_dir}"
   ```

3. **Modify Manifest Integrity Check**:
   Ensure it runs before setting unified variables, preserving the current behavior.

4. **Update Function References**:
   Replace mode-specific variables with unified variables in all functions.

5. **Test at Each Stage**:
   Run tests after each function modification to ensure behavior is preserved.

## 5. Function-by-Function Modification Plan

### 5.1 Initialization Functions

#### `parse_manifest_metadata()`
```sh
parse_manifest_metadata() {
    pmm_manifest_file="${1}"
    pmm_mode="${2}"
    
    # ... existing code ...
    
    # Set unified variables first
    SOURCE_REPO="${pmm_source_repo}"
    TARGET_DIR="${pmm_target_dir}"
    
    # For backward compatibility
    if [ "${pmm_mode}" = "local" ]; then
        LOCAL_SOURCE_REPO="${pmm_source_repo}"
        LOCAL_TARGET_DIR="${pmm_target_dir}"
    elif [ "${pmm_mode}" = "commit" ]; then
        COMMIT_SOURCE_REPO="${pmm_source_repo}"
        COMMIT_TARGET_DIR="${pmm_target_dir}"
    fi
    
    # ... rest of function ...
}
```

#### `initialize_ai_rizz()`
Ensure this function handles the new unified variables correctly if it references the repository variables.

### 5.2 Core Helper Functions

#### `get_manifest_and_target()`
```sh
get_manifest_and_target() {
    gmt_mode="${1}"
    
    # ... existing code ...
    
    # Use unified variables
    gmt_manifest_file="${MANIFEST_FILE_PREFIX}${gmt_mode}${MANIFEST_FILE_SUFFIX}"
    
    # Return values
    echo "${gmt_manifest_file}"
    echo "${TARGET_DIR}"
}
```

#### `show_manifest_integrity_error()`
This function likely references the mode-specific variables when showing the error. We may need to modify it to compare the same values between manifests.

### 5.3 Command Functions

For each command function that references the mode-specific variables, replace with unified variables:

```sh
# Example replacement in cmd_sync()
cs_target_dir="${TARGET_DIR}"
cs_repo="${SOURCE_REPO}"

# Instead of:
# if [ "${cs_mode}" = "local" ]; then
#     cs_target_dir="${LOCAL_TARGET_DIR}"
#     cs_repo="${LOCAL_SOURCE_REPO}"
# else
#     cs_target_dir="${COMMIT_TARGET_DIR}"
#     cs_repo="${COMMIT_SOURCE_REPO}"
# fi
```

## 6. Backward Compatibility Strategy

### 6.1 Phase 1: Maintain Both Sets of Variables

During initial implementation, we'll set both unified and mode-specific variables, allowing existing code to continue functioning correctly.

### 6.2 Phase 2: Deprecation Warnings

Add comments to mark mode-specific variables as deprecated:

```sh
# DEPRECATED: Use SOURCE_REPO instead
LOCAL_SOURCE_REPO="${SOURCE_REPO}"
COMMIT_SOURCE_REPO="${SOURCE_REPO}"

# DEPRECATED: Use TARGET_DIR instead
LOCAL_TARGET_DIR="${TARGET_DIR}"
COMMIT_TARGET_DIR="${TARGET_DIR}"
```

### 6.3 Phase 3: Complete Removal

In a future update, once all functions have been converted, we can remove the mode-specific variables entirely.

## 7. Testing and Validation Strategy

### 7.1 Test Cases

1. **Initialization Tests**:
   - Test initializing repository with local mode
   - Test initializing repository with commit mode
   - Test initializing repository with both modes

2. **Command Tests**:
   - Test all commands that use repository variables
   - Ensure they function correctly with the unified variables

3. **Error Handling Tests**:
   - Test manifest integrity error when manifests don't match
   - Ensure error messages are clear and accurate

### 7.2 Validation Process

1. Run shellcheck to ensure POSIX compliance
2. Execute the existing test suite
3. Manually test each modified function
4. Verify that all error conditions are properly handled

## 8. Risks and Mitigation

### 8.1 Potential Risks

1. **Manifest Integrity Check Failure**: Changes might break the integrity check that ensures manifests match.
   - **Mitigation**: Carefully preserve existing comparison logic and test thoroughly.

2. **Mode-Specific Logic**: Some functions might rely on mode-specific variables for more than just their values.
   - **Mitigation**: Carefully analyze each usage context before changing.

3. **Regression in Command Behavior**: Changes might subtly alter command behavior.
   - **Mitigation**: Comprehensive testing of each command after modifications.

4. **Documentation Inconsistencies**: Function headers might become inconsistent with implementation.
   - **Mitigation**: Update all documentation alongside code changes.

### 8.2 Mitigation Strategy

1. Make changes incrementally, testing after each modification
2. Preserve backward compatibility until all functions are updated
3. Comprehensive testing of all affected functionality
4. Review all error messages to ensure they remain accurate

## 9. Implementation Timeline

Given the scope of changes, this work should be planned across multiple sessions:

1. **Day 1**: Set up unified variables and modify initialization functions
2. **Day 2-3**: Update helper functions and core command functions
3. **Day 4**: Update remaining command functions
4. **Day 5**: Final testing, documentation updates, and clean-up

## 10. Conclusion

This variable consolidation will simplify the codebase and make it more maintainable by removing redundant mode-specific variables. While the changes are extensive, a careful phased approach with thorough testing will ensure that functionality is preserved while improving code quality.

The migration to unified SOURCE_REPO and TARGET_DIR variables follows the pattern already established with RULES_PATH and RULESETS_PATH, creating a more consistent variable handling strategy throughout the codebase. 