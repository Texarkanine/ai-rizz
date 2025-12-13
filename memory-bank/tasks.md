# Memory Bank: Tasks

## Current Task
Add targeted and limited support for `commands` subdirectory in rulesets to enable delivery of cursor-memory-bank commands to a "rules" repo.

## Status
- [x] Task definition
- [x] Complexity determination
- [x] Implementation plan
- [x] Phase 1: Stubbing (TDD Step 2) - Complete
- [x] Phase 4: Implement Tests (TDD Step 3) - Complete (all tests fail as expected)
- [x] Phase 5: Implement Code (TDD Step 4) - Complete
- [x] Phase 6: Documentation - Complete

## Requirements

### Core Requirements
1. Rulesets can have a special `commands` subdirectory
   - Subdirs work fine in rulesets for RULES currently (can be symlinks or regular dirs)
2. Commands in a ruleset must be committed (per blog post requirement)
   - Rulesets with `commands` subdir must error if trying to add in "local" mode
   - OR accept `/local/` prefix on all commands (creative decision needed)
   - Local commands are out of scope, but need to prevent damaging operations
3. Build a "memory-bank" ruleset with:
   - `commands/` subdir containing command files
   - Subdirs of all non-symlinked rules
   - Only addable in commit mode (memory bank MUST be committed anyway)
4. Commands local to ruleset won't show up in `ai-rizz list` (same as ruleset-local rules)
   - No need for root `commands` folder
   - No need for `ai-rizz add command ...` implementations

### Workflow
```
ai-rizz init --local
ai-rizz add ruleset memory-bank
# ERROR! - helpful message about how sets with commands MUST be committed
ai-rizz init --commit
ai-rizz add ruleset memory-bank --commit
```
This should:
- Copy `rulesets/memory-bank/commands/*` to `.cursor/commands/`
- Populate (committable) rules into `.cursor/rules/shared` per normal

## Complexity Level
**Level 3: Intermediate Feature**

### Complexity Analysis
- **Scope**: Multiple components (ruleset handling, sync logic, error checking)
- **Design Decisions**: Required (how to detect commands, error handling approach)
- **Risk**: Moderate (affects core ruleset functionality)
- **Implementation Effort**: Moderate (days to 1-2 weeks)
- **Components Affected**:
  - `cmd_add_ruleset()` function
  - `sync_manifest_to_directory()` / `copy_entry_to_target()` functions
  - Error handling for local mode restrictions
  - Command file copying logic

## Implementation Plan

**TDD Workflow**: Following `.cursor/rules/local/always-tdd.mdc`, all implementation must follow:
1. Determine Scope ✓ (already done)
2. Preparation (Stubbing) - Stub tests AND stub function interfaces
3. Write Tests - Implement tests, run them (they should fail)
4. Write Code - Implement code to make tests pass

### Phase 1: Preparation (Stubbing) - Detection and Validation

#### 1.1 Stub Test Suite: `test_ruleset_commands.test.sh`
**Location**: `tests/unit/test_ruleset_commands.test.sh` (new file)
**Purpose**: Create test file with empty test cases
**Implementation**:
- Create file with proper header and shunit2 setup
- Add empty test functions:
  - `test_ruleset_with_commands_rejects_local_mode()`
  - `test_ruleset_with_commands_allows_commit_mode()`
  - `test_ruleset_without_commands_works_in_local_mode()`
  - `test_commands_copied_to_correct_location()`
  - `test_commands_directory_created_if_missing()`
- Add multi-line comments explaining what each test should verify
- **DO NOT implement test logic yet** - just stubs

#### 1.2 Stub Function Interface: `show_ruleset_commands_error()`
**Location**: Add with other error functions (after `show_git_context_error()`)
**Purpose**: Stub the error function interface
**Implementation**:
- Add function signature with full documentation
- Follow pattern of other `show_*_error()` functions
- Include all documentation sections (Globals, Arguments, Outputs, Returns)
- **DO NOT implement function body yet** - just empty function that returns
- Use function-specific variable prefix: `srce_` (show_ruleset_commands_error)

#### 1.3 Stub Validation Logic in `cmd_add_ruleset()`
**Location**: In `cmd_add_ruleset()`, after mode selection, before adding to manifest
**Purpose**: Add placeholder for validation check
**Implementation**:
- After `cars_mode=$(select_mode "${cars_mode}")`
- Add comment: `# TODO: Check if ruleset has commands/ subdirectory and reject local mode`
- **DO NOT implement check yet** - just placeholder comment

### Phase 2: Preparation (Stubbing) - Command File Copying

#### 2.1 Stub Test Cases for Command Copying
**Location**: Add to `tests/unit/test_ruleset_commands.test.sh`
**Purpose**: Add empty test cases for command copying behavior
**Implementation**:
- Add empty test functions:
  - `test_commands_copied_to_correct_location()`
  - `test_commands_symlinks_followed_correctly()`
  - `test_commands_not_copied_in_local_mode()`
- Add multi-line comments explaining what each test should verify
- **DO NOT implement test logic yet** - just stubs

#### 2.2 Stub Function Interface: `copy_ruleset_commands()`
**Location**: Add before `copy_entry_to_target()` function
**Purpose**: Stub the command copying function interface
**Implementation**:
- Add function signature with full documentation
- Parameters:
  - `ruleset_path`: Path to ruleset in source repo (e.g., `rulesets/memory-bank`)
  - `target_commands_dir`: Target directory (e.g., `.cursor/commands`)
- Include all documentation sections (Globals, Arguments, Outputs, Returns)
- **DO NOT implement function body yet** - just empty function that returns 0
- Use function-specific variable prefix: `crc_`

#### 2.3 Stub Integration Point in `copy_entry_to_target()`
**Location**: In `copy_entry_to_target()`, when handling ruleset directories
**Purpose**: Add placeholder for command copying integration
**Implementation**:
- In the `elif [ -d "${cett_source_path}" ]` branch (ruleset handling)
- After copying `.mdc` files, add comment: `# TODO: Copy commands/ subdirectory if exists and in commit mode`
- **DO NOT implement copying logic yet** - just placeholder comment

### Phase 3: Preparation (Stubbing) - List Display Updates

**IMPORTANT**: This phase EXTENDS the existing `cmd_list()` implementation (lines 2519-2528), it does NOT rewrite it. We are building upon and preserving the existing tree/fallback logic and formatting.

#### 3.1 Stub Test Suite: `test_list_display.test.sh`
**Location**: `tests/unit/test_list_display.test.sh` (new file)
**Purpose**: Create test file with empty test cases for list display
**Implementation**:
- Create file with proper header and shunit2 setup
- Add empty test functions:
  - `test_list_expands_commands_directory()`
  - `test_list_commands_alignment_correct()`
  - `test_list_works_without_tree_command()`
  - `test_list_handles_empty_commands_directory()`
- Add multi-line comments explaining what each test should verify
- **DO NOT implement test logic yet** - just stubs

#### 3.2 Stub List Display Modifications in `cmd_list()`
**Location**: In `cmd_list()`, ruleset contents display section (lines 2519-2528)
**Purpose**: Add placeholders for extending existing display logic
**Implementation**:
- **CRITICAL**: We are EXTENDING the existing code, not rewriting it
- Current code block (lines 2519-2528):
  - Tree path: `tree -P "*.mdc" -L 1 --noreport` (shows only .mdc files)
  - Fallback: `find ... -name "*.mdc" ...` (shows only .mdc files)
- Add comment before the existing code block:
  - `# TODO: Extend to show directories and expand commands/ subdirectory`
- **DO NOT modify existing code yet** - just placeholder comment
- **Preserve existing behavior**: Continue showing .mdc files as before
- **Add new behavior**: Also show directories and expand `commands/`

#### 3.3 Detailed Specification

**Current Behavior**:
- Ruleset contents show only `.mdc` files
- Directories are shown but collapsed (no contents visible)
- Example:
  ```
  ◐ test
    ├── commands
    ├── foobar.mdc
    ├── java-gradle-tdd.mdc
    └── subdir
  ```

**Desired Behavior**:
- `commands/` directory always expanded to first level
- Other directories shown normally (tree's default behavior - no special prefix needed)
- Proper tree alignment maintained
- Example:
  ```
  ◐ test
    ├── commands
    │   ├── bar.md
    │   ├── baz.md
    │   └── subcommands  (if subdirectory exists)
    ├── foobar.mdc
    ├── java-gradle-tdd.mdc
    └── subdir
  ```

**Implementation Strategy**:

**CRITICAL PRINCIPLE**: Extend, don't rewrite. The existing `cmd_list()` code (lines 2519-2528) works correctly for .mdc files. We are adding directory display and `commands/` expansion while preserving all existing behavior and formatting.

**Tree Command Path** (when `tree` is available) - EXTENDING EXISTING CODE:
- **Current implementation** (line 2524):
  - `(cd "${cl_ruleset}" && tree -P "*.mdc" -L 1 --noreport) | tail -n +2 | sed 's/^/    /' | sed 's/ -> .*$//'`
  - Shows only .mdc files, 4-space indentation, strips symlink targets
- **Extension approach**: Modify the tree command to show directories AND expand `commands/`
- **New command**: Replace `-P "*.mdc"` with `-I "pattern"` approach
  - Use `tree -L 2 --noreport -I "pattern"` to exclude files but keep directories
  - Pattern: `find . -name 'commands' -type d -prune -o -type f,l -printf '%f|' | head -c -1`
  - This excludes all files/links but keeps all directories visible
  - Safe assumption: if `tree` is available, `find` and `head` are also available
- **Preserve existing post-processing**:
  - Keep `tail -n +2` (skip first line)
  - Keep `sed 's/^/    /'` (4-space indentation)
  - Keep `sed 's/ -> .*$//'` (strip symlink targets)
- **Result**: Tree shows directories (including `commands/` expanded to level 2) with same formatting
- Example command: `tree . -L 2 --noreport -I "$(find . -name 'commands' -type d -prune -o -type f,l -printf '%f|' | head -c -1)"`
- Implementation note: Can reuse the `find` command techniques for the fallback path

**Fallback Path** (when `tree` is not available) - EXTENDING EXISTING CODE:
- **Current implementation** (line 2527):
  - `find "${cl_ruleset}" -maxdepth 1 \( -name "*.mdc" -type f \) -o \( -name "*.mdc" -type l \) -exec basename {} \; | sort | sed 's/^/    ├── /'`
  - Shows only .mdc files, sorted, with `├──` prefix and 4-space indentation
- **Extension approach**: Extend the find command to also show directories and expand `commands/`
- **New logic**: Build on existing find pattern:
  - Keep existing: `.mdc` files (current behavior)
  - Add: Directories at maxdepth 1
  - Add: `commands/` contents expansion
- **Preserve existing formatting**:
  - Keep `sort` (alphabetical sorting)
  - Keep `sed 's/^/    ├── /'` (4-space indentation + tree character)
  - Extend to handle multiple items with proper `├──`/`└──` based on position
- **Implementation**:
  - Combine existing .mdc find with directory find
  - Add special handling for `commands/` directory expansion
  - Maintain same output format (4 spaces + tree character)

**Detailed Formatting Rules**:
1. **Item Ordering**:
   - Files first (sorted alphabetically)
   - `commands/` directory (if exists)
   - Other directories (sorted alphabetically)

2. **Tree Characters**:
   - `├──` for non-last items
   - `└──` for last item in ruleset
   - `│` for vertical continuation in `commands/` expansion

3. **Indentation**:
   - Ruleset contents: 4 spaces base (`    `)
   - `commands/` contents: 4 spaces + `│   ` = 8 spaces total
   - Alignment: Directory names align with file names naturally

4. **Commands Expansion Logic**:
   - Always expand `commands/` to first level
   - Show all files in `commands/`
   - Show subdirectories in `commands/` normally (tree's default - no special prefix)
   - Use proper tree continuation (`│`) for all but last item

**Edge Cases**:
- Empty `commands/` directory: Show as `├── commands` (no expansion)
- `commands/` with only subdirs: Show subdirectory entries normally
- No `commands/` directory: Normal behavior (no special handling)
- Multiple subdirectories: All shown normally, properly sorted

### Phase 4: Implement Tests (TDD Step 3)

#### 4.1 Implement Detection and Validation Tests
**Location**: `tests/unit/test_ruleset_commands.test.sh`
**Purpose**: Fill out test implementations for validation logic
**Implementation**:
- Implement all test functions from Phase 1.1
- Each test should:
  - Set up test environment (create ruleset with/without commands)
  - Execute the command being tested
  - Assert expected behavior
- Run tests: `./tests/unit/test_ruleset_commands.test.sh`
- **Expected**: All tests should FAIL (functionality not implemented yet)

#### 4.2 Implement Command Copying Tests
**Location**: `tests/unit/test_ruleset_commands.test.sh`
**Purpose**: Fill out test implementations for command copying
**Implementation**:
- Implement all test functions from Phase 2.1
- Test symlink handling specifically
- Run tests: `./tests/unit/test_ruleset_commands.test.sh`
- **Expected**: All tests should FAIL (functionality not implemented yet)

#### 4.3 Implement List Display Tests
**Location**: `tests/unit/test_list_display.test.sh`
**Purpose**: Fill out test implementations for list display
**Implementation**:
- Implement all test functions from Phase 3.1
- Test both `tree` and fallback `find` paths
- Test alignment and formatting
- Run tests: `./tests/unit/test_list_display.test.sh`
- **Expected**: All tests should FAIL (functionality not implemented yet)

#### 4.4 Create Integration Tests
**Location**: `tests/integration/test_ruleset_commands.test.sh` (new file)
**Purpose**: Create integration tests for full workflows
**Implementation**:
- Create file with proper header and shunit2 setup
- Implement test cases:
  - `test_full_workflow_local_then_commit()`
  - `test_commands_persist_after_sync()`
- Run tests: `./tests/integration/test_ruleset_commands.test.sh`
- **Expected**: All tests should FAIL (functionality not implemented yet)

### Phase 5: Implement Code (TDD Step 4)

#### 5.1 Implement Detection and Validation
**Location**: `ai-rizz` script
**Purpose**: Implement code to make Phase 4.1 tests pass
**Implementation**:
- Implement `show_ruleset_commands_error()` function body
- Add validation check in `cmd_add_ruleset()`:
  - After `cars_mode=$(select_mode "${cars_mode}")`
  - Check: `if [ -d "${REPO_DIR}/${cars_ruleset_path}/commands" ] && [ "${cars_mode}" = "local" ]; then`
  - Call `show_ruleset_commands_error()` if condition true
- Run tests: `./tests/unit/test_ruleset_commands.test.sh`
- **Expected**: Detection/validation tests should PASS

#### 5.2 Implement Command Copying
**Location**: `ai-rizz` script
**Purpose**: Implement code to make Phase 4.2 tests pass
**Implementation**:
- Implement `copy_ruleset_commands()` function body:
  - Check if source exists: `${REPO_DIR}/${crc_ruleset_path}/commands`
  - Create target directory: `mkdir -p "${crc_target_commands_dir}"`
  - Copy files: `cp -L` to follow symlinks
  - Handle errors gracefully
- Integrate into `copy_entry_to_target()`:
  - Calculate commands directory: `$(dirname "${TARGET_DIR}")/commands`
  - Check if in commit mode: `case "${cett_target_directory}" in */"${SHARED_DIR}")`
  - Call `copy_ruleset_commands()` if conditions met
- Run tests: `./tests/unit/test_ruleset_commands.test.sh`
- **Expected**: Command copying tests should PASS

#### 5.3 Implement List Display Updates
**Location**: `ai-rizz` script, `cmd_list()` function (lines 2519-2528)
**Purpose**: Implement code to make Phase 4.3 tests pass
**Implementation**:
- **CRITICAL**: Extend existing code block, do NOT rewrite
- **Tree path extension** (line 2524):
  - Replace `tree -P "*.mdc" -L 1` with `tree -L 2 -I "pattern"`
  - Build ignore pattern using find (as specified)
  - **Keep all existing post-processing**: `tail -n +2 | sed 's/^/    /' | sed 's/ -> .*$//'`
  - Result: Shows directories + expands `commands/` with same formatting
- **Fallback path extension** (line 2527):
  - Extend existing find command to include directories
  - Add special handling for `commands/` directory expansion
  - **Keep existing formatting**: `sort | sed 's/^/    ├── /'`
  - Extend to handle multiple items with proper `├──`/`└──` based on position
- **Preserve backward compatibility**: Existing .mdc file display must continue to work
- Run tests: `./tests/unit/test_list_display.test.sh`
- **Expected**: List display tests should PASS, existing behavior preserved

#### 5.4 Run Full Test Suite
**Purpose**: Verify all tests pass and no regressions
**Implementation**:
- Run: `make test`
- Verify all new tests pass
- Verify existing tests still pass (no regressions)
- Fix any failures before proceeding

#### 5.1 Error Message Content
**Message should include**:
- Clear explanation: "Rulesets containing a 'commands' subdirectory must be added in commit mode"
- Reason: "Commands must be committed to the repository (per requirement)"
- Fix options:
  - If not initialized: "Run 'ai-rizz init <repo-url> --commit' first"
  - If already initialized in local: "Run 'ai-rizz init <repo-url> --commit' to add commit mode"
- Reference: Mention this is by design to ensure commands are version-controlled

#### 5.2 Update Documentation
**Files to update**:
- `README.md`: Add section explaining commands subdirectory feature
- Document the restriction (commands must be committed)
- Add example workflow showing error and fix

### Phase 6: Documentation

#### 6.1 Update README.md
**Purpose**: Document the new commands subdirectory feature
**Implementation**:
- Add section explaining commands subdirectory feature
- Document the restriction (commands must be committed)
- Add example workflow showing error and fix

### Implementation Checklist (TDD Order)

#### Phase 1: Stubbing (TDD Step 2)
- [x] Stub test suite: `test_ruleset_commands.test.sh` with empty test functions
- [x] Stub function: `show_ruleset_commands_error()` with empty body
- [x] Stub validation logic in `cmd_add_ruleset()` (placeholder comment)
- [x] Stub test cases for command copying
- [x] Stub function: `copy_ruleset_commands()` with empty body
- [x] Stub integration point in `copy_entry_to_target()` (placeholder comment)
- [x] Stub test suite: `test_list_display.test.sh` with empty test functions
- [x] Stub list display modifications in `cmd_list()` (placeholder comments)

#### Phase 4: Implement Tests (TDD Step 3)
- [x] Implement detection/validation tests (should fail)
- [x] Implement command copying tests (should fail)
- [x] Implement list display tests (should fail)
- [x] Create and implement integration tests (should fail)
- [x] Run all tests to verify they fail as expected

#### Phase 5: Implement Code (TDD Step 4)
- [x] Implement `show_ruleset_commands_error()` function body
- [x] Implement validation check in `cmd_add_ruleset()`
- [x] Run tests - detection/validation tests should pass
- [x] Implement `copy_ruleset_commands()` function body
- [x] Integrate command copying into `copy_entry_to_target()`
- [x] Run tests - command copying tests should pass
- [x] Implement list display updates in `cmd_list()`
- [x] Run tests - list display tests should pass
- [x] Run full test suite: `make test`
- [x] Verify all tests pass, no regressions

#### Phase 6: Documentation
- [x] Update README.md with commands feature documentation
- [x] Add example workflow
- [x] Document error message and resolution

### Dependencies and Challenges

#### Dependencies
- Existing ruleset handling infrastructure (already in place)
- Sync mechanism (already handles rules, needs extension)
- Error handling patterns (follow existing patterns)

#### Challenges
1. **Path Calculation**: Need to derive `.cursor/commands/` from `.cursor/rules` (TARGET_DIR)
   - Solution: Use `dirname` to get base path, append `/commands`
2. **Mode Detection**: Need to know if we're in commit mode when copying
   - Solution: Check if target directory contains `SHARED_DIR` constant
3. **Error Message Clarity**: Need helpful, actionable error messages
   - Solution: Follow existing error function patterns with copy-pasteable fixes
4. **Testing**: Need to test both error and success paths
   - Solution: Create comprehensive test suite covering all scenarios

### Creative Phase Required

**Component**: Error handling approach for local mode restrictions

**Decision Needed**: 
- Should we error immediately when detecting commands in local mode?
- OR should we allow it but warn and skip command copying?

**Recommendation**: Error immediately (fail-fast approach)
- Clearer user experience
- Prevents partial state (rules added but commands missing)
- Aligns with requirement that commands MUST be committed
- Matches existing error patterns in codebase

**Alternative Considered**: Warn and continue
- Pros: More permissive, allows rules without commands
- Cons: Creates inconsistent state, violates requirement

**Decision**: **Error immediately** - This ensures commands are always committed and prevents confusing partial states.

## Next Steps

1. **Stubbing (TDD Step 2)**: Create empty test files and stub function interfaces
2. **Implement Tests (TDD Step 3)**: Fill out test implementations, verify they fail
3. **Implement Code (TDD Step 4)**: Write code to make tests pass, one test at a time
4. **Documentation**: Update README after all tests pass

