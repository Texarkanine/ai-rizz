# Phase 3.1 Refactoring Plan: Consolidating Duplicated Logic

## Analysis of Previous Attempt

### What Went Wrong
1. **Superficial Consolidation**: Only consolidated a single pattern (initialization check) in a single function (`cmd_list`), ignoring numerous other duplicated patterns
2. **Incomplete Helper Function**: Created an `ensure_initialized()` function that only handled part of the standard initialization pattern (missing the validation step)
3. **Lack of Systematic Approach**: Failed to identify and catalog all duplicated code patterns before starting
4. **Editing Issues**: Had difficulty with precise edits, causing unintended file content deletions
5. **Missed Opportunities**: Didn't prioritize the most impactful or frequently occurring patterns
6. **Inconsistent Application**: Only applied the consolidation to one function, not throughout the codebase

## Comprehensive Pattern Inventory

After thorough analysis, I've identified the following duplicated patterns that need consolidation:

### 1. Initialization and Validation Pattern *(7 occurrences)*
```sh
# Check if any mode is initialized
if [ "${HAS_COMMIT_MODE}" = "false" ] && [ "${HAS_LOCAL_MODE}" = "false" ]; then
    error "No ai-rizz configuration found. Run 'ai-rizz init' first."
fi

# Validate manifest integrity (hard error for mismatched source repos)
validate_manifest_integrity
```

### 2. Smart Mode Selection Pattern *(2 occurrences)*
```sh
# Smart mode selection
if [ -z "${mode}" ]; then
    if [ "${HAS_LOCAL_MODE}" = "true" ] && [ "${HAS_COMMIT_MODE}" = "false" ]; then
        mode="local"
    elif [ "${HAS_COMMIT_MODE}" = "true" ] && [ "${HAS_LOCAL_MODE}" = "false" ]; then
        mode="commit"
    else
        error "Both modes available. Please specify --local or --commit flag."
    fi
fi
```

### 3. Lazy Initialization Pattern *(2 occurrences)*
```sh
# Check if lazy initialization is needed and track it
lazy_init_occurred=false
if needs_lazy_init "${mode}"; then
    lazy_init_mode "${mode}"
    lazy_init_occurred=true
fi
```

### 4. Mode-based Target Selection Pattern *(2 occurrences)*
```sh
# Select manifest and target based on mode
case "${mode}" in
    local)
        manifest_file="${LOCAL_MANIFEST_FILE}"
        target_dir="${LOCAL_TARGET_DIR}/${LOCAL_DIR}"
        # Update source repository
        git_sync "${LOCAL_SOURCE_REPO}"
        ;;
    commit)
        manifest_file="${COMMIT_MANIFEST_FILE}"
        target_dir="${COMMIT_TARGET_DIR}/${SHARED_DIR}"
        # Update source repository
        git_sync "${COMMIT_SOURCE_REPO}"
        ;;
    *)
        error "Invalid mode: ${mode}"
        ;;
esac
```

### 5. Add .mdc Extension Pattern *(2 occurrences)*
```sh
# Add .mdc extension if not present
case "${item}" in
    *".mdc") ;;  # Already has extension
    *) item="${item}.mdc" ;;  # Add extension
esac
```

### 6. Check Repository Existence Pattern *(2 occurrences)*
```sh
# Check if item exists in source repo
if [ ! -f "${REPO_DIR}/${item_path}" ]; then
    warn "Item not found: ${item_path}"
    continue
fi
```

### 7. Conflict Resolution Migration Pattern *(2 occurrences)*
Complex pattern repeated in `cmd_add_rule` and `cmd_add_ruleset` that handles migrating entries between modes

**In cmd_add_rule (using car_* variables):**
```sh
# Check if rule exists in opposite mode (conflict resolution)
# Skip migration check if we just lazy-initialized the target mode (it's empty)
if [ "${car_lazy_init_occurred}" = "false" ]; then
    case "${car_mode}" in
        local)
            if [ "${HAS_COMMIT_MODE}" = "true" ]; then
                if read_manifest_entries "${COMMIT_MANIFEST_FILE}" | grep -q "^${car_rule_path}$"; then
                    # Remove from commit mode, add to local mode
                    remove_manifest_entry_from_file "${COMMIT_MANIFEST_FILE}" "${car_rule_path}"
                fi
            fi
            ;;
        commit)
            if [ "${HAS_LOCAL_MODE}" = "true" ]; then
                if read_manifest_entries "${LOCAL_MANIFEST_FILE}" | grep -q "^${car_rule_path}$"; then
                    # Remove from local mode, add to commit mode
                    remove_manifest_entry_from_file "${LOCAL_MANIFEST_FILE}" "${car_rule_path}"
                fi
            fi
            ;;
    esac
else
    # Lazy initialization occurred - need to migrate from opposite mode
    case "${car_mode}" in
        local)
            # We just created local mode, migrate from commit mode if rule exists there
            if [ "${HAS_COMMIT_MODE}" = "true" ]; then
                if read_manifest_entries "${COMMIT_MANIFEST_FILE}" | grep -q "^${car_rule_path}$"; then
                    remove_manifest_entry_from_file "${COMMIT_MANIFEST_FILE}" "${car_rule_path}"
                fi
            fi
            ;;
        commit)
            # We just created commit mode, migrate from local mode if rule exists there
            if [ "${HAS_LOCAL_MODE}" = "true" ]; then
                if read_manifest_entries "${LOCAL_MANIFEST_FILE}" | grep -q "^${car_rule_path}$"; then
                    remove_manifest_entry_from_file "${LOCAL_MANIFEST_FILE}" "${car_rule_path}"
                fi
            fi
            ;;
    esac
fi
```

**In cmd_add_ruleset (using cars_* variables):**
```sh
# Check if ruleset exists in opposite mode (conflict resolution)
# Skip migration check if we just lazy-initialized the target mode (it's empty)
if [ "${cars_lazy_init_occurred}" = "false" ]; then
    case "${cars_mode}" in
        local)
            if [ "${HAS_COMMIT_MODE}" = "true" ]; then
                if read_manifest_entries "${COMMIT_MANIFEST_FILE}" | grep -q "^${cars_ruleset_path}$"; then
                    # Remove from commit mode, add to local mode
                    remove_manifest_entry_from_file "${COMMIT_MANIFEST_FILE}" "${cars_ruleset_path}"
                fi
            fi
            ;;
        commit)
            if [ "${HAS_LOCAL_MODE}" = "true" ]; then
                if read_manifest_entries "${LOCAL_MANIFEST_FILE}" | grep -q "^${cars_ruleset_path}$"; then
                    # Remove from local mode, add to commit mode
                    remove_manifest_entry_from_file "${LOCAL_MANIFEST_FILE}" "${cars_ruleset_path}"
                fi
            fi
            ;;
    esac
else
    # Lazy initialization occurred - need to migrate from opposite mode
    case "${cars_mode}" in
        local)
            # We just created local mode, migrate from commit mode if ruleset exists there
            if [ "${HAS_COMMIT_MODE}" = "true" ]; then
                if read_manifest_entries "${COMMIT_MANIFEST_FILE}" | grep -q "^${cars_ruleset_path}$"; then
                    remove_manifest_entry_from_file "${COMMIT_MANIFEST_FILE}" "${cars_ruleset_path}"
                fi
            fi
            ;;
        commit)
            # We just created commit mode, migrate from local mode if ruleset exists there
            if [ "${HAS_LOCAL_MODE}" = "true" ]; then
                if read_manifest_entries "${LOCAL_MANIFEST_FILE}" | grep -q "^${cars_ruleset_path}$"; then
                    remove_manifest_entry_from_file "${LOCAL_MANIFEST_FILE}" "${cars_ruleset_path}"
                fi
            fi
            ;;
    esac
fi
```

**Analysis:** These patterns are structurally identical - only the variable names and comments differ (`car_*` vs `cars_*`, "rule" vs "ruleset"). This is an excellent candidate for consolidation into a helper function that takes the item path, mode, and lazy init flag as parameters.

## Implementation Plan

### Phase 1: Preparation and Safety
1. **Create a Checkpoint**: Create a git branch or commit before starting
2. **Validate with Tests**: Run the test suite to confirm the starting state is good

### Phase 2: Helper Function Design
Create the following helper functions just before the Commands section:

1. **`ensure_initialized_and_valid()`**
   - Purpose: Consolidate initialization check and integrity validation
   - Should replace patterns #1 completely

2. **`select_mode()`**
   - Purpose: Handle smart mode selection with proper variable prefixing
   - Parameters: Current mode value and a prefix for the return variable
   - Should replace pattern #2

3. **`initialize_mode_if_needed()`**
   - Purpose: Handle lazy initialization with tracking
   - Parameters: Mode and variable prefix for tracking variable
   - Should replace pattern #3

4. **`get_manifest_and_target()`**
   - Purpose: Select correct manifest file and target directory based on mode
   - Parameters: Mode and prefix for return variables
   - Should replace pattern #4

5. **`ensure_mdc_extension()`**
   - Purpose: Add .mdc extension to an item if not present
   - Parameters: Item name to normalize
   - Returns: Item name with .mdc extension
   - Should replace pattern #5

6. **`check_repository_item()`**
   - Purpose: Check if an item exists in the repository
   - Parameters: Item path, item type (file/directory)
   - Returns: 0 if exists, 1 if not (also outputs warning)
   - Should replace pattern #6

7. **`migrate_from_opposite_mode()`**
   - Purpose: Handle conflict resolution migration logic
   - Parameters: Item path, target mode, lazy init flag
   - Should replace pattern #7

### Phase 3: Implementation Strategy
1. **Test-Driven Approach**:
   - Create one helper function
   - Replace its pattern in all occurrences
   - Run tests to verify no regressions
   - Repeat for each helper function

2. **Use Precise Editing**:
   - Use more targeted file edits with smaller changes
   - When modifying functions, identify exact line numbers
   - Prefer multiple small edits over single large edits

3. **Validation Points**:
   - After implementing each helper function
   - After applying each helper in each command function
   - After completing all consolidations

### Phase 4: Documentation
1. **Document Helper Functions**:
   - Clear purpose statement
   - Description of parameters and return values
   - Explanation of globals used/modified
   - Any side effects

2. **Update Command Functions**:
   - Adjust comments to reflect the use of helper functions
   - Remove now-redundant comments

## Execution Timeline

1. **Helper Functions Creation** (30-40 minutes)
   - Define all 7 helper functions with proper documentation
   - Run tests to ensure baseline functionality

2. **Pattern Replacement** (60-90 minutes)
   - For each of the 7 patterns:
     - Identify all occurrences
     - Replace with helper function calls
     - Run tests after each function is fully replaced

3. **Final Verification** (15 minutes)
   - Complete test suite run
   - Manual code review
   - Verify shell compliance with shellcheck

## Potential Pitfalls and Mitigations

1. **Function Parameter Naming**:
   - Use prefix-based variable naming for all helper functions
   - Be consistent with prefixes across all helper functions

2. **Subshell Issues**:
   - For functions that need to set caller variables, use return values instead of trying to modify globals
   - Where necessary, use temporary files instead of pipes to avoid subshell variable scope issues

3. **Handling Continue/Return in Helpers**:
   - Be careful with control flow in extracted helpers that contained `continue` or `return`
   - Return status codes that the caller can check instead

4. **Code Block Boundaries**:
   - Carefully identify start/end of duplicated blocks
   - Include necessary context in helper functions

By implementing this comprehensive plan, we will successfully consolidate all duplicated logic patterns in the ai-rizz script, significantly improving maintainability while preserving functionality. 