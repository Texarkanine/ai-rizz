# Implementation Phase 5: Polish & Testing

## Overview

Phase 5 focuses on code quality, documentation, and user experience improvements. This phase will bring ai-rizz to production-ready quality with comprehensive documentation, standardized error handling, and polished user interactions.

## Objectives

### 1. POSIX Style Compliance
- **Goal**: Make ai-rizz fully compliant with `@posix-style.mdc`
- **Scope**: All functions, variables, error handling, and code structure
- **Priority**: HIGH - Foundation for maintainability

### 2. Function Documentation
- **Goal**: Every function documented with leading comment blocks per updated `@posix-style.mdc`
- **New Requirements**: 
  - Any function that is not both obvious and short must have documentation
  - Any function in a library must have documentation regardless of length or complexity
  - All required sections must be present, even if not applicable
- **Required Sections**: 
  - **Description**: What the function does
  - **Globals**: List of global variables used and modified  
  - **Arguments**: Arguments taken
  - **Outputs**: Output to STDOUT or STDERR
  - **Returns**: Returned values other than the default exit status
- **Priority**: HIGH - Critical for maintainability and compliance

### 3. Code Comment Cleanup
- **Remove**: Useless comments that repeat what code does
- **Keep**: Comments explaining WHY something is done
- **Add**: WHY explanations where logic isn't obvious
- **Priority**: MEDIUM - Improves code clarity

### 4. Error Handling Standardization
- **Current Issue**: Inconsistent use of `if ! command; then` vs `command || error`
- **Goal**: Establish clear patterns and apply consistently
- **Standard**:
  - Use `if ! command; then` for complex error handling with multiple actions
  - Use `command || error "message"` for simple fail-fast scenarios
  - **NEVER** Use `command || { action1; action2; }` ; this is unreadable to a human.
- **Priority**: HIGH - Affects reliability

### 5. Fix Output Issues
- **Issue 1**: "Added rule" printed even when downgrade is rejected
  - **Root Cause**: `continue 2` inside pipe subshell can't break outer loop
  - **Solution**: Restructure downgrade check logic
- **Issue 2**: Tests are too verbose
  - **Solution**: Reduce test output, only show failures and summary... by default. Have some mechanism for tests to be their original verbosity, for troubleshooting!
- **Priority**: HIGH - User experience

### 6. README Updates
- **Add**: Advanced user guide section on upgrade/downgrade rules
- **Content**: 
  - Explain ruleset vs individual rule constraints
  - Document when downgrades are prevented
  - Provide examples of valid/invalid operations
  - Remove troubleshooting section (error messages should be self-contained)
- **Priority**: MEDIUM - User education

### 7. Improve Manifest Integrity Error Messages
- **Current Issue**: Unhelpful error message suggests `deinit` as first choice
- **Goal**: Guide users to sync manifests by switching one mode to match the other
- **Solution**: Show current state and provide copy-pasteable commands
- **Priority**: HIGH - User experience and workflow efficiency

### 8. Fix List Command File Filtering
- **Current Issue**: `ai-rizz list` shows non-.mdc files (like README.md) in rulesets
- **Goal**: Only show .mdc files and symlinks in listings
- **Solution**: Filter ruleset contents to only display .mdc files and symlinks to .mdc files
- **Priority**: MEDIUM - Clean user interface

## Detailed Implementation Plan

### 5.1: POSIX Style Compliance Audit

**Files to Update**: `ai-rizz` (main script)

**Tasks**:
1. **Variable Naming**: Ensure all variables use lowercase_with_underscores
2. **Function Naming**: Ensure all functions use lowercase_with_underscores  
3. **Quoting**: Ensure all variable expansions use `"${variable}"` format
4. **Indentation**: Use tabs for initial indentation, spaces for alignment
5. **Line Length**: Keep under 80 characters where possible
6. **Control Flow**: Ensure proper spacing in if/for/while/case statements

**Validation**: 
- Manual review against posix-style.mdc checklist
- Test all functionality after changes

### 5.2: Function Documentation Implementation

**Scope**: All 45+ functions in ai-rizz need documentation

**Priority Order**:
1. **Public Commands** (8 functions): `cmd_init`, `cmd_add_rule`, `cmd_add_ruleset`, `cmd_remove_rule`, `cmd_remove_ruleset`, `cmd_list`, `cmd_sync`, `cmd_deinit`
2. **Core Utilities** (12 functions): `detect_initialized_modes`, `cache_manifest_metadata`, `lazy_init_mode`, `migrate_legacy_repository_if_needed`, etc.
3. **Helper Functions** (25+ functions): All remaining utility functions

**Updated Documentation Template** (per new posix-style.mdc requirements):
```sh
# Brief description of what the function does
#
# Globals:
#   GLOBAL_VAR1 - Description of how it's used/modified
#   GLOBAL_VAR2 - Description of how it's used/modified
#   (or "None" if no globals used)
#
# Arguments:
#   $1 - Parameter description (required/optional, type, constraints)
#   $2 - Parameter description (required/optional, type, constraints)
#   (or "None" if no arguments)
#
# Outputs:
#   Stdout: Description of normal output
#   Stderr: Description of error output
#   (or "None" if no output)
#
# Returns:
#   0 on success
#   1 on specific error condition
#   2 on different error condition
#   (or "Always returns 0 (default exit status)" if no special returns)
#
# Examples:
#   function_name "example_arg1" "example_arg2"
#   function_name --flag value
```

**Documentation Criteria**:
- **Must Document**: All functions that are not both obvious AND short
- **Must Document**: ALL functions in ai-rizz (it's a library/tool)
- **All Sections Required**: Even if "None" or "N/A"

### 5.3: Error Handling Standardization

**Current Patterns Analysis**:
- Found 47 instances of `if ! command; then` pattern
- Found 23 instances of `command || action` pattern
- Inconsistent usage creates maintenance burden

**Standardization Rules**:

1. **Simple Fail-Fast**: Use `command || error "message"`
   ```sh
   git clone "${repo}" "${dir}" || error "Failed to clone repository"
   ```

2. **Complex Error Handling**: Use `if ! command; then`
   ```sh
   if ! git clone "${repo}" "${dir}"; then
       warn "Clone failed, trying alternative method"
       # alternative logic
       return 1
   fi
   ```

3. **Multi-Action Error**: **NEVER** use `command || { action1; action2; }` - this is unreadable to humans
   ```sh
   # WRONG - unreadable
   process_file "${file}" || { warn "Processing failed"; cleanup_temp_files; return 1; }
   
   # RIGHT - readable
   if ! process_file "${file}"; then
       warn "Processing failed for ${file}"
       cleanup_temp_files
       return 1
   fi
   ```

**Implementation**:
- Audit all 70+ error handling instances
- Apply standardization rules consistently
- Test error paths after changes

### 5.4: Fix Downgrade Output Issue

**Problem**: 
```bash
ai-rizz add rule bash-style --local
Warning: Cannot add individual rule 'bash-style.mdc' to local mode: it's part of committed ruleset 'rulesets/shell'. Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
Added rule: rules/bash-style.mdc  # ← This shouldn't print!
```

**Root Cause**: 
- `continue 2` inside pipe subshell (`echo "$commit_entries" | while`) cannot break outer loop
- Code continues executing after warning

**Solution**:
1. **Restructure Logic**: Move downgrade check outside of pipe
2. **Use Function Return**: Create helper function that returns status
3. **Skip Processing**: Use flag to skip rule processing after conflict detection

**Implementation**:
```sh
# New approach - check conflicts before processing
check_downgrade_conflict() {
    rule="$1"
    mode="$2"
    
    if [ "$mode" = "local" ] && [ "$HAS_COMMIT_MODE" = "true" ]; then
        # Check logic here
        # Return 1 if conflict found, 0 if OK
    fi
    return 0
}

# In main loop
for rule in $rules; do
    if ! check_downgrade_conflict "$rule" "$mode"; then
        continue  # Skip this rule
    fi
    # Process rule normally
    echo "Added rule: $rule_path"
done
```

### 5.5: Test Output Reduction

**Current State**: 137 echo/printf statements in tests, very verbose output

**Goals**:
- Passing tests should be quiet (only show test name and PASS/FAIL)
- Failing tests should show detailed output for debugging
- Overall test run should show summary

**Implementation Strategy**:

1. **Test Framework Enhancement**:
   ```sh
   # Add to tests/common.sh
   VERBOSE_TESTS="${VERBOSE_TESTS:-false}"
   
   test_echo() {
       if [ "$VERBOSE_TESTS" = "true" ]; then
           echo "$@"
       fi
   }
   
   test_debug() {
       if [ "$VERBOSE_TESTS" = "true" ]; then
           echo "DEBUG: $@" >&2
       fi
   }
   ```

2. **Replace Echo Statements**:
   - Change `echo "Setting up..."` to `test_echo "Setting up..."`
   - Keep `echo` for actual test assertions and failures
   - Use `test_debug` for diagnostic information

3. **Test Runner Enhancement**:
   ```sh
   # In test runner
   run_test() {
       test_name="$1"
       if $test_name >/dev/null 2>&1; then
           echo "✓ $test_name"
       else
           echo "✗ $test_name"
           echo "  Running with verbose output for troubleshooting:"
           VERBOSE_TESTS=true $test_name
       fi
   }
   ```

4. **Troubleshooting Mode**:
   ```sh
   # Allow users to run tests with full verbosity for debugging
   # Usage: VERBOSE_TESTS=true ./run-tests.sh
   # Usage: make test-verbose
   ```

### 5.6: Improve Manifest Integrity Error Messages

**Current Problem**:
```bash
ai-rizz list
Error: Manifest integrity error: Local and commit modes use different source repositories (https://github.com/texarkanine/.cursor-rules2.git vs https://github.com/texarkanine/.cursor-rules.git). This is not supported. Use 'ai-rizz deinit' to reset.
```

**Issues with Current Approach**:
- Suggests `deinit` as first choice (destructive)
- Doesn't show which mode has which repository
- No guidance on how to sync the manifests
- No copy-pasteable commands

**Improved Error Message**:
```bash
ai-rizz list
Error: Manifest integrity error - different source repositories detected:

  Local mode:  https://github.com/texarkanine/.cursor-rules2.git
  Commit mode: https://github.com/texarkanine/.cursor-rules.git

To fix this, choose which repository you want to use for both modes:

Option 1: Switch local mode to match commit mode
  ai-rizz deinit --local -y && ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local

Option 2: Switch commit mode to match local mode  
  ai-rizz deinit --commit -y && ai-rizz init https://github.com/texarkanine/.cursor-rules2.git --commit

Option 3: Reset everything and start fresh
  ai-rizz deinit --all -y && ai-rizz init
```

**Implementation**:
1. **Enhance `validate_manifest_integrity()`**: Collect detailed information about the mismatch
2. **Create `show_integrity_fix_options()`**: Generate helpful error message with commands
3. **Update error calls**: Replace generic error with detailed guidance

**Code Structure**:
```sh
# Enhanced integrity validation with detailed reporting
validate_manifest_integrity() {
    if [ "$HAS_COMMIT_MODE" = "true" ] && [ "$HAS_LOCAL_MODE" = "true" ]; then
        if [ "$COMMIT_SOURCE_REPO" != "$LOCAL_SOURCE_REPO" ]; then
            show_integrity_fix_options
            exit 1
        fi
    fi
}

# Show detailed fix options for manifest integrity issues
show_integrity_fix_options() {
    echo "Error: Manifest integrity error - different source repositories detected:" >&2
    echo "" >&2
    echo "  Local mode:  ${LOCAL_SOURCE_REPO}" >&2
    echo "  Commit mode: ${COMMIT_SOURCE_REPO}" >&2
    echo "" >&2
    echo "To fix this, choose which repository you want to use for both modes:" >&2
    echo "" >&2
    echo "Option 1: Switch local mode to match commit mode" >&2
    echo "  ai-rizz deinit --local -y && ai-rizz init ${COMMIT_SOURCE_REPO} --local" >&2
    echo "" >&2
    echo "Option 2: Switch commit mode to match local mode" >&2  
    echo "  ai-rizz deinit --commit -y && ai-rizz init ${LOCAL_SOURCE_REPO} --commit" >&2
    echo "" >&2
    echo "Option 3: Reset everything and start fresh" >&2
    echo "  ai-rizz deinit --all -y && ai-rizz init" >&2
}
```

### 5.7: Fix List Command File Filtering

**Current Problem**:
```bash
ai-rizz list
Available rulesets:
  ● shell
    ├── README.md          # ← This shouldn't be shown
    ├── bash-style.mdc     # ← Only these should be shown
    ├── posix-style.mdc
    └── shell-tdd.mdc
```

**Goal**: Only show .mdc files and symlinks to .mdc files in ruleset listings

**Implementation**:
1. **Locate List Logic**: Find where ruleset contents are enumerated in `cmd_list()`
2. **Add File Filtering**: Filter to only include:
   - Files ending in `.mdc`
   - Symlinks pointing to files ending in `.mdc`
3. **Update Tree Display**: Ensure tree structure remains clean

**Code Changes**:
```sh
# Current approach (shows all files)
find "$ruleset_path" -type f -o -type l

# New approach (filter to .mdc only)
find "$ruleset_path" \( -type f -name "*.mdc" \) -o \( -type l -name "*.mdc" \)
```

### 5.8: README Advanced User Guide

**New Section**: "Advanced Usage" 

**Content to Add**:

```markdown
## Advanced Usage

### Rule and Ruleset Constraints

ai-rizz enforces certain constraints to maintain consistency:

#### Upgrade/Downgrade Rules

**Committed Rulesets**: When a ruleset is committed (git-tracked), all its individual rules are "locked" to that ruleset.

```bash
# This works - adding entire ruleset
ai-rizz add ruleset shell --commit
ai-rizz list
# Shows: ● shell (with bash-style.mdc, posix-style.mdc, etc.)

# This is BLOCKED - can't downgrade individual rules
ai-rizz add rule bash-style --local
# Warning: Cannot add individual rule 'bash-style.mdc' to local mode: 
# it's part of committed ruleset 'rulesets/shell'. 
# Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
```

**Why This Matters**:
- Prevents inconsistent states where some rules from a ruleset are local, others committed
- Ensures team members get complete, tested rule combinations
- Maintains ruleset integrity and dependencies

#### Valid Operations

**✅ Allowed**:
```bash
# Move entire ruleset between modes
ai-rizz add ruleset shell --local    # Move whole ruleset to local
ai-rizz add ruleset shell --commit   # Move whole ruleset to commit

# Add individual rules that aren't part of committed rulesets
ai-rizz add rule standalone-rule.mdc --local
ai-rizz add rule standalone-rule.mdc --commit  # Upgrade individual rule

# Mix individual rules and rulesets
ai-rizz add rule personal-rule.mdc --local     # Personal rule
ai-rizz add ruleset team-standards --commit    # Team ruleset
```

**❌ Blocked**:
```bash
# Cannot downgrade individual rules from committed rulesets
ai-rizz add rule bash-style.mdc --local  # If bash-style is in committed ruleset

# Cannot partially move rulesets
# (Must move entire ruleset at once)
```

#### Workarounds

If you need a modified version of a rule from a committed ruleset:

**Fork the Ruleset**:
```bash
# Move entire ruleset to local, modify, then re-commit
ai-rizz add ruleset shell --local
# Edit rules in .cursor/rules/local/rulesets/shell/
ai-rizz add ruleset shell --commit
```

**Note**: You cannot extract individual rules from rulesets. Rules are locked to their rulesets to maintain integrity and dependencies.



## Success Criteria

### Code Quality
- [ ] All functions have proper documentation headers with required sections (Description, Globals, Arguments, Outputs, Returns)
- [ ] All code follows POSIX style guide
- [ ] Error handling is consistent throughout (no unreadable `||` chains)
- [ ] No useless comments, clear WHY comments added

### User Experience  
- [ ] No "Added rule" message when downgrade is rejected
- [ ] Test output is clean and informative
- [ ] README explains upgrade/downgrade constraints clearly (no troubleshooting section)
- [ ] Manifest integrity errors provide helpful guidance with copy-pasteable commands
- [ ] Error messages are self-contained and don't require external documentation
- [ ] List command only shows .mdc files and symlinks (no README.md or other files)

### Reliability
- [ ] All existing tests continue to pass
- [ ] Error handling is robust and consistent
- [ ] Edge cases are properly documented

## Validation Plan

### Automated Testing
1. **Run Full Test Suite**: Ensure no regressions
2. **Style Validation**: Manual review against posix-style.mdc
3. **Error Path Testing**: Verify all error conditions work correctly

### Manual Testing
1. **User Scenarios**: Test common workflows end-to-end
2. **Error Conditions**: Verify error messages are helpful
3. **Documentation**: Ensure examples in README work

### Code Review
1. **Function Documentation**: Every function properly documented
2. **Comment Quality**: Comments explain WHY, not WHAT
3. **Consistency**: Error handling follows established patterns

## Dependencies

### Prerequisites
- Phase 4 must be complete (all tests passing)
- No outstanding bugs or regressions
- Clean git state for testing

### External Dependencies
- POSIX style guide (`.cursor/rules/shared/posix-style.mdc`)
- Existing test infrastructure
- Current documentation structure

## Risk Mitigation

### Code Changes
- **Risk**: Breaking existing functionality during style updates
- **Mitigation**: Run tests after each major change, make incremental updates

### Documentation
- **Risk**: Documentation becomes outdated quickly  
- **Mitigation**: Include documentation validation in test suite

### User Experience
- **Risk**: Changes affect user workflows
- **Mitigation**: Maintain backward compatibility, test common scenarios

## Deliverables

1. **Updated ai-rizz Script**: Fully documented, POSIX-compliant, standardized error handling
2. **Enhanced Test Suite**: Quiet by default, verbose on failure
3. **Comprehensive README**: Advanced user guide with upgrade/downgrade rules
4. **Documentation**: All functions properly documented
5. **Validation Report**: Confirmation all success criteria met

---

**Phase 5 Status**: Ready for implementation
**Next Phase**: Phase 6 (Integration Testing) - moved from Phase 5 scope
**Estimated Effort**: 3 weeks
**Priority**: HIGH - Required for production readiness 