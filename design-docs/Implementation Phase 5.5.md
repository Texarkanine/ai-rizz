# Implementation Phase 5.5: Step-by-Step Plan for Remainder of Phase 5

## Overview

This document provides a detailed step-by-step implementation plan for completing the remainder of Phase 5, starting with test verbosity reduction as requested. The plan ensures that test verbosity management is implemented first, as it will impact the validation procedures for all subsequent steps.

## Current Status

**✅ COMPLETED:**
- Function Documentation (Section 5.2) - All 45+ functions documented
- POSIX Function Variable Scope (Section 5.1.3) - All functions use proper prefixes
- POSIX Error Handling Standardization (Section 5.1.4) - All problematic patterns converted
- POSIX Final Polish (Section 5.1.5) - Full POSIX compliance achieved

**🔄 REMAINING TASKS:**
1. Test Output Reduction (Section 5.5) - **START HERE**
2. Fix Downgrade Output Issue (Section 5.4)
3. Improve Manifest Integrity Error Messages (Section 5.6)
4. Fix List Command File Filtering (Section 5.7)
5. README Advanced User Guide (Section 5.8)

---

## Step 1: Test Verbosity Management Implementation

### 1.1: Design Test Verbosity Framework

**Objective**: Create a comprehensive test verbosity control system that allows quiet operation by default with detailed output on failures or when explicitly requested.

**Framework Requirements**:
- **Default Behavior**: Quiet operation showing only test names and PASS/FAIL status
- **Failure Behavior**: Automatic verbose re-run of failed tests for debugging
- **Manual Verbose Mode**: Environment variable to force verbose output for all tests
- **Backward Compatibility**: Existing test logic remains unchanged, only output is controlled

**Implementation Strategy**:

#### 1.1.1: Core Verbosity Functions
Add to `tests/common.sh`:

```bash
# Test verbosity control
VERBOSE_TESTS="${VERBOSE_TESTS:-false}"
TEST_QUIET_MODE="${TEST_QUIET_MODE:-true}"

# Controlled output functions
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

test_info() {
    if [ "$VERBOSE_TESTS" = "true" ]; then
        echo "INFO: $@" >&2
    fi
}

# Always show critical messages (errors, failures)
test_error() {
    echo "ERROR: $@" >&2
}

test_fail() {
    echo "FAIL: $@" >&2
}
```

#### 1.1.2: Enhanced Test Runner
Update `tests/run_tests.sh`:

```bash
# Enhanced test execution with verbosity control
run_test() {
    test_file="$1"
    test_name="${test_file#$PROJECT_ROOT/tests/}"
    
    # Run from project root for consistency
    cd "$PROJECT_ROOT" || exit 1
    
    # Set environment for test execution
    AI_RIZZ_PATH="$PROJECT_ROOT/ai-rizz"
    export AI_RIZZ_PATH
    
    if [ "$VERBOSE_TESTS" = "true" ]; then
        # Verbose mode: show all output
        echo "==== Running test: $test_name ===="
        if timeout 5s sh "$test_file"; then
            echo "==== PASS: $test_name ===="
            return 0
        else
            exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "==== TIMEOUT: $test_name (hung waiting for input) ===="
            else
                echo "==== FAIL: $test_name ===="
            fi
            return 1
        fi
    else
        # Quiet mode: capture output, show only on failure
        printf "%-50s " "$test_name"
        
        if output=$(timeout 5s sh "$test_file" 2>&1); then
            echo "✓ PASS"
            return 0
        else
            exit_code=$?
            if [ $exit_code -eq 124 ]; then
                echo "✗ TIMEOUT"
                echo "  Test hung waiting for input. Re-running with verbose output:"
            else
                echo "✗ FAIL"
                echo "  Re-running with verbose output for troubleshooting:"
            fi
            echo "  ----------------------------------------"
            VERBOSE_TESTS=true timeout 5s sh "$test_file" || true
            echo "  ----------------------------------------"
            return 1
        fi
    fi
}

# Add usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Run tests with verbose output"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  VERBOSE_TESTS=true    Force verbose output for all tests"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run tests quietly (default)"
    echo "  $0 --verbose          # Run tests with full output"
    echo "  VERBOSE_TESTS=true $0 # Run tests with full output"
}

# Parse command line arguments
parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                VERBOSE_TESTS=true
                export VERBOSE_TESTS
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage >&2
                exit 1
                ;;
        esac
    done
}
```

### 1.2: Update Test Files for Verbosity Control

**Objective**: Replace verbose echo statements in test files with controlled output functions.

**Scope Analysis**: Based on examination of test files, the following patterns need updating:
- Setup/teardown diagnostic messages
- Test progress indicators
- Debug information
- Non-critical informational output

**Implementation Process**:

#### 1.2.1: Audit Current Echo Usage
Run analysis to identify all echo statements in test files:

```bash
# Find all echo statements in test files
grep -n "echo\|printf" tests/unit/*.test.sh tests/common.sh
```

#### 1.2.2: Categorize Echo Statements
- **Keep as-is**: Test assertions, error messages, critical failures
- **Convert to test_echo**: Setup messages, progress indicators, debug info
- **Convert to test_debug**: Detailed diagnostic information
- **Convert to test_info**: General informational messages

#### 1.2.3: Update Test Files Systematically
For each test file:
1. Replace setup/diagnostic echo with `test_echo`
2. Replace debug information with `test_debug`
3. Keep assertion failures and critical errors as regular echo
4. Ensure test logic remains unchanged

**Example Transformation**:
```bash
# Before
echo "Setting up test environment..."
echo "Creating test repository..."

# After  
test_echo "Setting up test environment..."
test_debug "Creating test repository..."
```

### 1.3: Update Documentation

**Objective**: Update all documentation to reflect the new test verbosity system.

#### 1.3.1: README Testing Section Update
Update the Testing section in README.md:

```markdown
### Testing

The project uses [shunit2](https://github.com/kward/shunit2) for unit and integration testing.

#### Running Tests

```bash
# Run all tests (quiet mode - default)
make test

# Run tests with verbose output
VERBOSE_TESTS=true make test

# Run specific test file (quiet)
sh tests/unit/test_progressive_init.sh

# Run specific test file (verbose)
VERBOSE_TESTS=true sh tests/unit/test_progressive_init.sh
```

#### Test Output Modes

**Quiet Mode (Default)**:
- Shows only test names and PASS/FAIL status
- Failed tests automatically re-run with verbose output for debugging
- Provides clean, summary-focused output for CI/CD and regular development

**Verbose Mode**:
- Shows all test setup, execution, and diagnostic information
- Useful for test development and troubleshooting
- Activated with `VERBOSE_TESTS=true`

#### Test Structure
[existing structure documentation remains unchanged]
```

#### 1.3.2: Add Testing Best Practices
Add new section to README:

```markdown
#### Testing Best Practices

**For Test Development**:
- Use `test_echo` for setup and progress messages
- Use `test_debug` for detailed diagnostic information  
- Use `test_info` for general informational messages
- Keep `echo` for test assertions and critical errors
- Test in both quiet and verbose modes during development

**For Troubleshooting**:
- Failed tests automatically show verbose output
- Use `VERBOSE_TESTS=true` to see all test details
- Individual test files can be run directly with verbose output

**For CI/CD**:
- Default quiet mode provides clean, parseable output
- Failed tests include full diagnostic information
- Exit codes properly indicate success/failure
```

### 1.4: Validation and Testing

**Objective**: Ensure the verbosity system works correctly and doesn't break existing functionality.

#### 1.4.1: Test the Test Framework
1. **Baseline Test**: Run existing tests to ensure they still pass
2. **Quiet Mode Test**: Verify default quiet output is clean and informative
3. **Verbose Mode Test**: Verify verbose mode shows all expected information
4. **Failure Mode Test**: Intentionally break a test to verify failure output
5. **Environment Variable Test**: Test `VERBOSE_TESTS=true` override

#### 1.4.2: Validation Criteria
- ✅ All existing tests continue to pass
- ✅ Quiet mode shows clean, summary output
- ✅ Verbose mode shows detailed information
- ✅ Failed tests automatically show verbose output
- ✅ Environment variable override works correctly

- ✅ Documentation is accurate and complete

---

## Step 2: Fix Downgrade Output Issue

### 2.1: Problem Analysis

**Current Issue**: 
```bash
ai-rizz add rule bash-style --local
Warning: Cannot add individual rule 'bash-style.mdc' to local mode: it's part of committed ruleset 'rulesets/shell'. Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
Added rule: rules/bash-style.mdc  # ← This shouldn't print!
```

**Root Cause**: `continue 2` inside pipe subshell cannot break outer loop, causing execution to continue after warning.

### 2.2: Implementation Strategy

#### 2.2.1: Restructure Downgrade Check Logic
Move conflict detection outside of pipe subshell:

```bash
# New helper function for conflict detection
check_rule_downgrade_conflict() {
    cdc_rule="$1"
    cdc_mode="$2"
    
    # Only check for downgrade conflicts (local mode with commit mode active)
    if [ "$cdc_mode" = "local" ] && [ "$HAS_COMMIT_MODE" = "true" ]; then
        # Check if rule is part of committed ruleset
        commit_entries=$(read_manifest_entries "$COMMIT_MANIFEST_FILE" 2>/dev/null || true)
        echo "$commit_entries" | while IFS= read -r entry; do
            case "$entry" in
                rulesets/*)
                    ruleset_name="${entry#rulesets/}"
                    if [ -f "${COMMIT_TARGET_DIR}/${SHARED_DIR}/${entry}/${cdc_rule}.mdc" ]; then
                        warn "Cannot add individual rule '${cdc_rule}.mdc' to local mode: it's part of committed ruleset '${entry}'. Use 'ai-rizz add-ruleset ${ruleset_name} --local' to move the entire ruleset."
                        return 1
                    fi
                    ;;
            esac
        done
    fi
    return 0
}
```

#### 2.2.2: Update cmd_add_rule Logic
Restructure main loop to check conflicts before processing:

```bash
# In cmd_add_rule function
for rule in $rules; do
    # Check for downgrade conflicts first
    if ! check_rule_downgrade_conflict "$rule" "$mode"; then
        continue  # Skip this rule, conflict detected
    fi
    
    # Process rule normally (existing logic)
    # ... existing rule processing code ...
    
    echo "Added rule: rules/${rule}.mdc"
done
```

### 2.3: Validation Strategy
- **Test Downgrade Scenarios**: Verify warning appears and no "Added" message
- **Test Valid Scenarios**: Verify normal operation continues to work
- **Test Edge Cases**: Multiple rules, mixed valid/invalid rules

---

## Step 3: Improve Manifest Integrity Error Messages

### 3.1: Enhanced Error Message Design

**Current Problem**: Unhelpful error suggests `deinit` as first choice without showing current state or providing actionable guidance.

**New Error Message Format**:
```bash
Error: Manifest integrity error - different source repositories detected:

  Local mode:  https://github.com/user/.cursor-rules2.git
  Commit mode: https://github.com/user/.cursor-rules.git

To fix this, choose which repository you want to use for both modes:

Option 1: Switch local mode to match commit mode
  ai-rizz deinit --local -y && ai-rizz init https://github.com/user/.cursor-rules.git --local

Option 2: Switch commit mode to match local mode  
  ai-rizz deinit --commit -y && ai-rizz init https://github.com/user/.cursor-rules2.git --commit

Option 3: Reset everything and start fresh
  ai-rizz deinit --all -y && ai-rizz init
```

### 3.2: Implementation Strategy

#### 3.2.1: Create Enhanced Error Function
```bash
show_manifest_integrity_error() {
    cat >&2 << EOF
Error: Manifest integrity error - different source repositories detected:

  Local mode:  ${LOCAL_SOURCE_REPO}
  Commit mode: ${COMMIT_SOURCE_REPO}

To fix this, choose which repository you want to use for both modes:

Option 1: Switch local mode to match commit mode
  ai-rizz deinit --local -y && ai-rizz init ${COMMIT_SOURCE_REPO} --local

Option 2: Switch commit mode to match local mode  
  ai-rizz deinit --commit -y && ai-rizz init ${LOCAL_SOURCE_REPO} --commit

Option 3: Reset everything and start fresh
  ai-rizz deinit --all -y && ai-rizz init
EOF
}
```

#### 3.2.2: Update Integrity Validation
Replace existing error call with enhanced function:

```bash
validate_manifest_integrity() {
    if [ "$HAS_COMMIT_MODE" = "true" ] && [ "$HAS_LOCAL_MODE" = "true" ]; then
        if [ "$COMMIT_SOURCE_REPO" != "$LOCAL_SOURCE_REPO" ]; then
            show_manifest_integrity_error
            exit 1
        fi
    fi
}
```

### 3.3: Validation Strategy
- **Test Repository Mismatch**: Create scenario with different repos, verify new error message
- **Test Copy-Paste Commands**: Verify suggested commands actually work
- **Test Edge Cases**: Empty repos, invalid URLs, etc.

---

## Step 4: Fix List Command File Filtering

### 4.1: Problem Analysis

**Current Issue**: `ai-rizz list` shows non-.mdc files (like README.md) in ruleset listings.

**Goal**: Only show .mdc files and symlinks to .mdc files.

### 4.2: Implementation Strategy

#### 4.2.1: Locate List Logic
Find the ruleset enumeration code in `cmd_list()` function.

#### 4.2.2: Update File Filtering
Replace current file listing with filtered approach:

```bash
# Current approach (shows all files)
find "$ruleset_path" -type f -o -type l

# New approach (filter to .mdc only)
find "$ruleset_path" \( -type f -name "*.mdc" \) -o \( -type l -name "*.mdc" \)
```

#### 4.2.3: Maintain Tree Structure
Ensure the tree display logic continues to work correctly with filtered file list.

### 4.3: Validation Strategy
- **Test Ruleset with Mixed Files**: Create ruleset with .mdc and non-.mdc files
- **Test Symlinks**: Verify .mdc symlinks are shown, non-.mdc symlinks are hidden
- **Test Tree Display**: Verify tree structure remains clean and readable

---

## Step 5: README Advanced User Guide

### 5.1: Content Design

**New Section**: "Advanced Usage" explaining upgrade/downgrade constraints.

**Key Topics**:
- Rule and ruleset constraints
- Upgrade/downgrade rules
- Valid vs blocked operations
- Workarounds for complex scenarios

### 5.2: Implementation Strategy

#### 5.2.1: Add Advanced Usage Section
Insert comprehensive section explaining:
- Why constraints exist
- What operations are allowed/blocked
- How to work around limitations
- Examples of valid workflows

#### 5.2.2: Remove Troubleshooting Section
Error messages should be self-contained, eliminating need for external troubleshooting documentation.

#### 5.2.3: Update Table of Contents
Ensure new section is properly referenced in README structure.

### 5.3: Content Structure
```markdown
## Advanced Usage

### Rule and Ruleset Constraints
[Explanation of constraint system]

### Upgrade/Downgrade Rules  
[Detailed rules with examples]

### Valid Operations
[Examples of allowed operations]

### Blocked Operations
[Examples of blocked operations with explanations]

### Workarounds
[Strategies for complex scenarios]
```

---

## Implementation Order and Dependencies

### Phase 1: Test Verbosity (Steps 1.1-1.4)
- **Priority**: HIGHEST - Affects all subsequent validation
- **Dependencies**: None
- **Validation**: New test framework must work before proceeding

### Phase 2: Core Fixes (Steps 2-4)
- **Priority**: HIGH - User experience improvements
- **Dependencies**: Test verbosity framework (for validation)
- **Order**: Can be done in parallel or any sequence

### Phase 3: Documentation (Step 5)
- **Priority**: MEDIUM - User education
- **Dependencies**: All core fixes completed
- **Timing**: Final step to ensure documentation matches implementation

## Success Criteria

### Test Verbosity System
- ✅ Quiet mode shows clean, summary output
- ✅ Verbose mode shows detailed information  
- ✅ Failed tests automatically show verbose output
- ✅ Environment variable override works

- ✅ Documentation is accurate and complete

### Core Fixes
- ✅ No "Added rule" message when downgrade is rejected
- ✅ Manifest integrity errors provide helpful guidance with copy-pasteable commands
- ✅ List command only shows .mdc files and symlinks

### Documentation
- ✅ README explains upgrade/downgrade constraints clearly
- ✅ Advanced usage section provides comprehensive guidance
- ✅ All examples work as documented

## Risk Mitigation

### Test Framework Changes
- **Risk**: Breaking existing test functionality
- **Mitigation**: Implement incrementally, validate each step
- **Rollback**: Keep original test files until validation complete

### Core Logic Changes  
- **Risk**: Introducing new bugs while fixing output issues
- **Mitigation**: Use new test verbosity system for thorough validation
- **Testing**: Test both positive and negative scenarios extensively

### Documentation Updates
- **Risk**: Documentation becoming outdated
- **Mitigation**: Update documentation as final step after implementation
- **Validation**: Test all documented examples

---

**Implementation Status**: Ready to begin with Step 1 (Test Verbosity Management)
**Next Action**: Implement test verbosity framework in tests/common.sh and tests/run_tests.sh
**Validation**: Each step must pass validation before proceeding to next step 