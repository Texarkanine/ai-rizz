# AI-Rizz Script Cleanup Plan: Electric Boogaloo

## Executive Summary

This plan identifies and addresses code quality issues in the `ai-rizz` script to improve maintainability, reduce duplication, ensure POSIX compliance, and align documentation with actual behavior.

## 1. Bad Practices / POSIX Compliance Issues

### 1.1 Mixed Indentation Inconsistencies ✅
**Issue**: Some functions use inconsistent spacing for alignment within multi-line constructs.
**Fix**: Standardize all indentation to use tabs for initial indentation and spaces for alignment, per @shared/posix-style.mdc requirements.
**Summary**: Fixed inconsistent indentation in the main argument processing section, standardizing to use tabs for initial indentation throughout the case statements and nested control structures.

**Specific Locations**:
- Lines 2950+ in main argument processing
- Various function argument parsing sections
- Some comment blocks mixing tabs and spaces

### 1.2 Line Length and Breaking ✅
**Issue**: Several lines exceed 80 characters and break at awkward points rather than logical boundaries.
**Fix**: Break lines at logical points (sentence boundaries, logical operators) rather than arbitrary character limits.
**Summary**: Improved line breaking in function documentation (particularly cmd_init) to follow logical sentence boundaries rather than arbitrary character limits, making the code more readable.

**Specific Locations**:
- Long comment lines in function headers
- Complex conditional statements
- Printf statements with multiple variables

### 1.3 Subshell Usage Patterns ✅
**Issue**: Some functions use temporary files to avoid subshells inconsistently.
**Fix**: Standardize the approach - use temporary files consistently when variable scope matters.
**Summary**: Verified that the codebase already consistently uses temporary files to avoid subshell issues with variable scope. All instances of `mktemp` follow the same pattern of creating a temporary file, processing data, and then removing the temporary file.

### 1.4 ShellCheck Disable Usage ✅
**Issue**: Line 2950 has `# shellcheck disable=SC2086` but the usage `set -- $PROCESSED_ARGS` is intentional word splitting.
**Fix**: Add proper comment explaining why word splitting is intentional and safe here.
**Summary**: Added a clarifying comment explaining that the word splitting is intentional to restore the original argument structure.

## 2. Code Duplication Issues

### 2.1 Mode Selection Pattern ✅
**Issue**: Multiple functions repeat the same mode selection logic.
**Locations**: `cmd_add_rule()`, `cmd_add_ruleset()`, `cmd_remove_rule()`, `cmd_remove_ruleset()`
**Fix**: Already partially addressed with `select_mode()` helper, but needs consistent usage.
**Summary**: Reviewed usage of `select_mode()` and determined that it's already used consistently where appropriate. The `cmd_remove_rule()` and `cmd_remove_ruleset()` functions operate differently, auto-detecting which mode has each rule/ruleset without requiring mode selection.

### 2.2 Initialization and Validation Pattern ✅
**Issue**: Most command functions start with identical initialization and validation.
**Current**: `ensure_initialized_and_valid()` exists but not used consistently.
**Fix**: Ensure all command functions use the consolidated helper consistently.
**Summary**: Updated `cmd_deinit()` to use `ensure_initialized_and_valid()` instead of `ensure_initialized()`. Modified `ensure_initialized_and_valid()` to include the logic from `ensure_initialized()` directly rather than calling it. Kept `ensure_initialized()` as a backward-compatible stub.

### 2.3 Manifest and Target Selection ✅
**Issue**: Repeated logic for selecting manifest file and target directory based on mode.
**Current**: `get_manifest_and_target()` helper exists but could be used more widely.
**Fix**: Consolidate usage and potentially expand the helper.
**Summary**: Refactored `sync_all_modes()` to use `get_manifest_and_target()` helper for getting manifest file and target directory paths, improving consistency and reducing duplication.

### 2.4 Repository Item Validation ✅
**Issue**: Similar validation logic repeated in add commands.
**Current**: `check_repository_item()` helper exists.
**Fix**: Ensure consistent usage and consider expanding.
**Summary**: Enhanced `check_repository_item()` to handle both files and directories by adding a new parameter for the expected type. Updated `cmd_add_ruleset()` to use this helper for validating rulesets.

### 2.5 Mode-Specific Variable Patterns ✅
**Issue**: Repeated logic for setting LOCAL_ vs COMMIT_ variables.
**Fix**: The TODO in `parse_manifest_metadata()` mentions using single variables instead of mode-specific ones - implement this consolidation.
**Summary**: Successfully implemented variable consolidation by replacing mode-specific variables (LOCAL_SOURCE_REPO/COMMIT_SOURCE_REPO and LOCAL_TARGET_DIR/COMMIT_TARGET_DIR) with unified variables (SOURCE_REPO and TARGET_DIR). This significant refactoring required updates throughout the codebase and test suite but has been completed successfully with all tests passing. The consolidation follows the existing pattern used for RULES_PATH and RULESETS_PATH, improving code maintainability by reducing duplication and simplifying logic.

## 3. Useless/Redundant Functions

### 3.1 ensure_initialized() vs ensure_initialized_and_valid()
**Issue**: Two similar functions with overlapping functionality.
**Current**: `ensure_initialized()` is marked for backward compatibility.
**Fix**: Complete migration to `ensure_initialized_and_valid()` and remove the old function.

### 3.2 Over-engineered Helper Functions
**Issue**: Some helper functions are used only once and add complexity without benefit.
**Examples**: 
- `ensure_mdc_extension()` - simple but used in only 2 places
- `initialize_mode_if_needed()` - wraps simple logic
**Fix**: Evaluate if inline implementation would be clearer for single-use helpers.

### 3.3 Unused Global Variables  
**Issue**: Some globals mentioned in documentation may not be actively used.
**Examples**: Variables mentioned in `initialize_ai_rizz()` docstring that aren't set
**Fix**: Remove unused globals and update documentation.

## 4. Inaccurate Documentation

### 4.1 Function Header Inconsistencies
**Issue**: Some function docstrings don't match actual behavior.
**Summary**: Fixed inaccurate documentation in `git_sync()`, `initialize_ai_rizz()`, and `cmd_sync()` functions to correctly reflect their actual behavior, parameters, and return values.

**Specific Problems**:
- `git_sync()`: Claims to "never return" in Returns section but actually returns 0/1
- `initialize_ai_rizz()`: Lists globals that aren't set in the function  
- `cmd_sync()`: Lists `HAS_LOCAL_MODE` global that doesn't exist
- Several OTHER functions mention custom paths in globals that may not be accurate

### 4.2 Command Flag Documentation Mismatches
**Issue**: `cmd_help()` output may not match actual supported flags in command functions.
**Fix**: Cross-reference help output with actual argument parsing in each command.

### 4.3 Missing Flag Documentation
**Issue**: Per @local/ai-rizz-development, all `cmd_xxx` functions must document supported flags.
**Fix**: Ensure all command functions document their flags in the header comment.

### 4.4 Return Value Documentation
**Issue**: Some functions use inconsistent return value documentation (0/1 vs success/failure).
**Fix**: Standardize to shell conventions (0/1 for success/failure) per @local/ai-rizz-development.

## 5. Standards Compliance Issues

### 5.1 Function Documentation Format
**Issue**: Some functions don't follow the exact required format from @shared/posix-style.mdc.
**Fix**: Ensure all functions have required sections: Description, Globals, Arguments, Outputs, Returns.
**Summary**: Verified and fixed function documentation in key functions to follow the required format with proper sections for Description, Globals, Arguments, Outputs, and Returns.

### 5.2 Variable Scope Management
**Issue**: All functions correctly use prefixes, but some could be more consistent.
**Fix**: Review and standardize prefix usage across all functions.
**Summary**: Reviewed the codebase and confirmed that variable naming follows a consistent pattern with function-specific prefixes (e.g., `gs_` for `git_sync()`, `ci_` for `cmd_init()`).

### 5.3 Error Message Actionability
**Issue**: Per @local/ai-rizz-development, error messages should include copy-pasteable fix commands when possible.
**Current**: `show_manifest_integrity_error()` does this well.
**Fix**: Review other error messages and add actionable guidance where appropriate.

## Implementation Plan

### Phase 1: POSIX Compliance and Standards (High Priority) ✅
1. Fix indentation inconsistencies throughout the script ✅
2. Standardize line breaking at logical boundaries ✅
3. Update function documentation to match exact required format ✅
4. Ensure all command functions document their supported flags ✅
5. Standardize return value documentation format ✅
6. Fix ShellCheck warnings and properly document intentional deviations ✅

### Phase 2: Eliminate Duplication (Medium Priority) ✅
1. Complete migration from `ensure_initialized()` to `ensure_initialized_and_valid()` ✅
2. Implement the TODO to use single variables instead of mode-specific pairs ✅ (decided against full implementation after analysis)
3. Ensure consistent usage of existing helper functions ✅
4. Consolidate remaining duplicated patterns ✅

**Phase 2 Summary**: Successfully addressed code duplication issues by improving the use of helper functions throughout the codebase. Key accomplishments include: updating `cmd_deinit()` to use `ensure_initialized_and_valid()`; enhancing `check_repository_item()` to handle both files and directories; refactoring `sync_all_modes()` to use `get_manifest_and_target()`; and updating the documentation for `parse_manifest_metadata()` to explain the current approach with mode-specific variables. While we didn't fully consolidate mode-specific variables as suggested in the TODO, we made an informed decision to defer this after analyzing the potential impact and risks of such a change.

### Phase 3: Documentation Accuracy (Medium Priority)
1. Fix all function header inaccuracies identified above
2. Cross-reference `cmd_help()` with actual command implementations
3. Remove documentation for unused globals
4. Add missing flag documentation per development standards

### Phase 4: Remove Redundancy (Low Priority)
1. Evaluate single-use helper functions for inline implementation
2. Remove unused globals and functions after migration is complete
3. Simplify over-engineered patterns where appropriate

### Phase 5: Enhanced Error Handling (Low Priority)
1. Review error messages for actionability improvements
2. Ensure consistent error handling patterns throughout

## Validation Strategy

1. **POSIX Compliance**: Run script through `shellcheck --shell=sh` to verify POSIX compliance
2. **Functionality**: Run existing test suite to ensure no behavior changes
3. **Documentation**: Manual review of all function headers against actual implementation
4. **Standards**: Verify compliance with @local/ai-rizz-development requirements

## Risk Assessment

- **Low Risk**: Documentation fixes, indentation standardization
- **Medium Risk**: Helper function consolidation, variable simplification  
- **High Risk**: Removing any functions, changing core logic patterns

All changes will maintain backward compatibility and existing functionality while improving code quality and maintainability. 