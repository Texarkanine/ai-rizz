# Implementation Phase 5.1: POSIX Style Compliance

## Overview

This document outlines the step-by-step implementation plan for bringing ai-rizz into full compliance with the POSIX style guide (@posix-style.mdc). Based on analysis of the current codebase, the script is already largely POSIX-compliant but needs specific formatting and style improvements.

## Current State Analysis

**✅ Already POSIX-Compliant:**
- ✅ Shebang: Uses `#!/bin/sh` 
- ✅ No bash-specific features: No `local`, `[[]]`, `function` keyword, `==` operator
- ✅ Function syntax: All functions use POSIX `name() { }` syntax
- ✅ Variable expansion: Uses `${variable}` format consistently
- ✅ Test constructs: Uses `[ ]` instead of `[[ ]]`
- ✅ Command substitution: Uses `$()` instead of backticks
- ✅ Parameter expansion: Uses POSIX-compliant `${0##*/}` pattern
- ✅ Variable naming: Constants are UPPERCASE, variables are lowercase_with_underscores

**🔄 Needs POSIX Compliance Work:**
- **Indentation**: Many lines use 4-space indentation instead of tabs
- **Line length**: Some lines exceed 80 characters
- **Error handling**: Inconsistent patterns (47 `if !` vs 23 `||` patterns)
- **Comment quality**: Some comments explain WHAT instead of WHY
- **Function variable scope**: No function-specific prefixes (POSIX has no `local`)

## Implementation Plan

### Step 1: Indentation Standardization
**Priority**: HIGH - Foundation for all other formatting

**Current Issue**: 
- Script uses 4-space indentation throughout
- POSIX style requires tabs for initial indentation, spaces for alignment

**Implementation**:
1. **Convert 4-space indentation to tabs**:
   - Replace `^    ` (4 spaces at start of line) with `\t` (tab)
   - Preserve alignment spaces within lines
   - Handle nested indentation (8 spaces → 2 tabs, 12 spaces → 3 tabs, etc.)

2. **Preserve alignment spaces**:
   - Keep spaces used for alignment within multi-line commands
   - Keep spaces in comments for readability

**Validation**:
- Visual inspection of indentation consistency
- Test script functionality after changes

### Step 2: Line Length Compliance
**Priority**: MEDIUM - Improves readability

**Current Issue**: 
- Some lines exceed 80 characters
- Long strings and commands need line continuation

**Implementation**:
1. **Identify long lines**: Find lines > 80 characters
2. **Apply line continuation**: Use `\` for command continuation
3. **Use here documents**: For long strings/messages
4. **Break long pipelines**: Put each pipe on separate line

**Examples**:
```sh
# Before (long line)
error "Manifest integrity error: Local and commit modes use different source repositories (${LOCAL_SOURCE_REPO} vs ${COMMIT_SOURCE_REPO}). This is not supported. Use 'ai-rizz deinit' to reset."

# After (line continuation)
error "Manifest integrity error: Local and commit modes use different source repositories" \
      "(${LOCAL_SOURCE_REPO} vs ${COMMIT_SOURCE_REPO}). This is not supported." \
      "Use 'ai-rizz deinit' to reset."
```

### Step 3: Function Variable Scope
**Priority**: HIGH - POSIX compliance requirement

**Current Issue**:
- Functions use global variables without prefixes
- POSIX shell has no `local` keyword
- Risk of variable name conflicts

**Implementation**:
1. **Add function prefixes**: Use function name abbreviations for variables
2. **Document prefix scheme**: Add comments explaining prefixes
3. **Update existing functions**: Apply prefixes systematically

**Prefix Scheme**:
```sh
# Function: read_manifest_metadata → prefix: rmm_
read_manifest_metadata() {
	rmm_manifest_file="$1"
	rmm_first_line
	
	if [ ! -f "${rmm_manifest_file}" ]; then
		return 1
	fi
	
	read -r rmm_first_line < "${rmm_manifest_file}"
	echo "${rmm_first_line}"
}

# Function: cmd_add_rule → prefix: car_
cmd_add_rule() {
	car_rules="$1"
	car_mode="$2"
	car_rule
	
	for car_rule in ${car_rules}; do
		# Process rule
	done
}
```

### Step 4: Error Handling Standardization
**Priority**: HIGH - Affects reliability

**Current Patterns**:
- 47 instances of `if ! command; then` pattern
- 23 instances of `command || action` pattern

**Standardization Rules**:
1. **Simple fail-fast**: Use `command || error "message"`
2. **Complex error handling**: Use `if ! command; then`
3. **Never use**: `command || { action1; action2; }` (unreadable)

**Implementation**:
1. **Audit all error handling**: Categorize each instance
2. **Apply standards**: Convert to appropriate pattern
3. **Test error paths**: Ensure error handling still works

### Step 5: Comment Quality Improvement
**Priority**: MEDIUM - Code clarity

**Current Issues**:
- Some comments explain WHAT code does (redundant)
- Missing WHY explanations for complex logic

**Implementation**:
1. **Remove redundant comments**: Delete comments that repeat code
2. **Add WHY comments**: Explain reasoning for non-obvious logic
3. **Keep essential comments**: Preserve comments that add value

**Examples**:
```sh
# REMOVE - explains what code does
# Check if file exists
if [ -f "${file}" ]; then

# KEEP - explains why we do this
# Use git root for consistent project naming across different working directories
if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then

# ADD - explain non-obvious logic
# Skip first line (metadata), return rest (handle empty manifests gracefully)
tail -n +2 "$manifest_file" | grep -v '^$' || true
```

### Step 6: Control Flow Formatting
**Priority**: MEDIUM - Consistency

**Current State**: Generally good, minor improvements needed

**Implementation**:
1. **Standardize spacing**: Ensure consistent spacing in if/for/while/case
2. **Align case statements**: Proper indentation and alignment
3. **Pipeline formatting**: Break long pipelines appropriately

**Standards**:
```sh
# if statements
if [ "${condition}" ]; then
	# code
elif [ "${other_condition}" ]; then
	# code
else
	# code
fi

# case statements
case "${variable}" in
	pattern1)
		action1
		;;
	pattern2)
		action2
		;;
	*)
		default_action
		;;
esac

# Long pipelines
command1 \
	| command2 \
	| command3 \
	| command4
```

### Step 7: File Header Enhancement
**Priority**: LOW - Documentation

**Current State**: Basic header exists

**Enhancement**:
```sh
#!/bin/sh
#
# ai-rizz - A CLI tool to manage Cursor rules and rulesets
# Supports progressive initialization with local and commit modes
#
# Usage: ai-rizz <command> [options]
# 
# Copyright 2024 ai-rizz project
# POSIX-compliant shell script for maximum portability
```

## Implementation Steps

### Phase 5.1.1: Indentation Conversion ✅ COMPLETED
1. ✅ **Backup current script**: `cp ai-rizz ai-rizz.backup`
2. ✅ **Convert indentation**: Used sed to convert 4-space to tabs, 8-space to 2 tabs
3. ✅ **Manual review**: Verified complex indentation cases handled correctly
4. ✅ **Test functionality**: All tests pass (8/8), script functions correctly
5. ✅ **Commit changes**: `git commit -m "fix: convert indentation to POSIX tabs"`

### Phase 5.1.2: Line Length and Formatting ✅ COMPLETED
1. ✅ **Identify long lines**: Found lines >100 chars that needed logical breaking
2. ✅ **Apply line continuation**: Broke long error messages and find commands at logical points
3. ✅ **Follow updated guidance**: Applied flexible line length approach (readability over strict 80-char)
4. ✅ **Test functionality**: No syntax errors, all tests pass (8/8)
5. ✅ **Commit changes**: `git commit -m "style: improve line length compliance with logical breaks"`

### Phase 5.1.3: Function Variable Scope
1. **Design prefix scheme**: Document function name → prefix mapping
2. **Update functions systematically**: Start with core functions
3. **Test after each function**: Ensure no variable conflicts
4. **Update documentation**: Reflect new variable naming
5. **Commit changes**: `git commit -m "refactor: add function variable prefixes for POSIX compliance"`

### Phase 5.1.4: Error Handling and Comments
1. **Audit error handling**: Categorize all 70+ instances
2. **Apply standardization**: Convert to appropriate patterns
3. **Review comments**: Remove redundant, add WHY explanations
4. **Test error paths**: Verify error handling works
5. **Commit changes**: `git commit -m "style: standardize error handling and improve comments"`

### Phase 5.1.5: Final Polish
1. **File header update**: Add comprehensive header
2. **Final review**: Check against POSIX style guide
3. **Run ShellCheck**: `shellcheck --shell=sh ai-rizz`
4. **Full test suite**: Ensure all functionality works
5. **Commit changes**: `git commit -m "docs: enhance file header for POSIX compliance"`

## Validation Criteria

### Automated Validation
- [ ] **ShellCheck**: `shellcheck --shell=sh ai-rizz` passes with no POSIX warnings
- [ ] **Test Suite**: All 8 test files pass (100% success rate)
- [ ] **Syntax Check**: `sh -n ai-rizz` passes (no syntax errors)

### Manual Validation
- [ ] **Indentation**: All initial indentation uses tabs, alignment uses spaces
- [ ] **Line Length**: No lines exceed 80 characters (except where unavoidable)
- [ ] **Variable Naming**: All variables follow POSIX conventions
- [ ] **Function Variables**: All function variables use appropriate prefixes
- [ ] **Error Handling**: Consistent patterns throughout
- [ ] **Comments**: Only WHY comments, no redundant WHAT comments

### Functional Validation
- [ ] **Core Commands**: All commands work identically to before
- [ ] **Error Paths**: Error handling behaves correctly
- [ ] **Edge Cases**: Complex scenarios still work
- [ ] **Performance**: No significant performance degradation

## Risk Mitigation

### Code Changes
- **Risk**: Breaking functionality during style changes
- **Mitigation**: 
  - Make incremental changes with frequent testing
  - Run test suite after each major change
  - Keep backup of working version

### Variable Scope Changes
- **Risk**: Variable name conflicts with function prefixes
- **Mitigation**:
  - Use systematic prefix scheme
  - Test each function individually
  - Document prefix mappings clearly

### Error Handling Changes
- **Risk**: Changing error behavior
- **Mitigation**:
  - Test all error paths after changes
  - Preserve existing error messages
  - Validate error codes remain consistent

## Success Criteria

1. **POSIX Compliance**: Script passes `shellcheck --shell=sh` with no warnings
2. **Functionality Preserved**: All existing functionality works identically
3. **Test Suite**: 100% test pass rate maintained
4. **Code Quality**: Improved readability and maintainability
5. **Documentation**: Clear, helpful comments explaining WHY not WHAT

## Deliverables

1. **Updated ai-rizz Script**: Fully POSIX-compliant version
2. **Validation Report**: Confirmation of all success criteria
3. **Documentation**: Updated comments and function documentation
4. **Test Results**: Proof that all tests still pass

---

**Phase 5.1 Status**: Ready for implementation
**Estimated Effort**: 1-2 weeks
**Priority**: HIGH - Foundation for remaining Phase 5 work
**Dependencies**: None (can start immediately) 