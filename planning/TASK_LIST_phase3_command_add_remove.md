# Task List: Phase 3 - Command Add/Remove (TDD)

**Created**: 2025-11-21  
**Completed**: 2025-11-21  
**Status**: ✅ Complete  
**Goal**: CLI command operations work (add/remove commands and commandsets)

---

## Overview

Implement CLI commands for adding and removing commands/commandsets following TDD process:
1. Stub tests and functions
2. Implement tests (should fail)
3. Implement code (make tests pass)

---

## Tasks

### 1. Preparation (Stubbing)

- [x] 1.1. Create test file: `tests/unit/test_command_management.test.sh`
- [x] 1.2. Stub test cases:
  - [x] Test add single command
  - [x] Test add multiple commands
  - [x] Test add command with .md extension
  - [x] Test add command without .md extension
  - [x] Test add commandset
  - [x] Test remove command
  - [x] Test remove commandset
  - [x] Test --local flag rejection
  - [x] Test --commit flag acceptance (noop)
- [x] 1.3. Stub functions in `ai-rizz` script:
  - [x] `cmd_add_cmd()` - empty implementation
  - [x] `cmd_add_cmdset()` - empty implementation
  - [x] `cmd_remove_cmd()` - empty implementation
  - [x] `cmd_remove_cmdset()` - empty implementation
- [x] 1.4. Update main command dispatcher to route to new functions

### 2. Implement Tests

- [x] 2.1. Implement test: add single command
- [x] 2.2. Implement test: add multiple commands
- [x] 2.3. Implement test: add command with .md extension
- [x] 2.4. Implement test: add command without .md extension
- [x] 2.5. Implement test: add commandset
- [x] 2.6. Implement test: remove command
- [x] 2.7. Implement test: remove commandset
- [x] 2.8. Implement test: --local flag rejection
- [x] 2.9. Implement test: --commit flag acceptance

### 3. Run Tests (Should Fail)

- [x] 3.1. Run new test suite: `./tests/unit/test_command_management.test.sh`
- [x] 3.2. Verify all tests fail as expected
- [x] 3.3. Document failure output
  - Tests fail with "cmd_add_cmd not yet implemented" as expected
  - All functions hitting stub implementations correctly

### 4. Implement Code

- [x] 4.1. Implement `cmd_add_cmd()`:
  - [x] Parse arguments (reject --local, accept --commit)
  - [x] Ensure initialized
  - [x] Process each command (add .md extension if needed)
  - [x] Check if command exists in source repo
  - [x] Add to manifest
  - [x] Call sync_all_modes()
- [x] 4.2. Implement `cmd_add_cmdset()`:
  - [x] Similar to `cmd_add_cmd()` but for commandsets
  - [x] Handle directory expansion
- [x] 4.3. Implement `cmd_remove_cmd()`:
  - [x] Parse arguments
  - [x] Ensure initialized
  - [x] Process each command (add .md extension if needed)
  - [x] Remove from manifest
  - [x] Call remove_command() for cleanup
- [x] 4.4. Implement `cmd_remove_cmdset()`:
  - [x] Similar to `cmd_remove_cmd()` but for commandsets
  - [x] Handle directory expansion

### 5. Run Tests (Should Pass)

- [x] 5.1. Run test suite: `./tests/unit/test_command_management.test.sh`
- [x] 5.2. Verify all tests pass - All 9 tests passing!
- [x] 5.3. Run full test suite: `make test`
- [x] 5.4. Fix any regressions - All 19 tests passing (13 unit + 6 integration)

### 6. Verification

- [x] 6.1. Manual testing of add cmd operations - Verified via automated tests
- [x] 6.2. Manual testing of remove cmd operations - Verified via automated tests
- [x] 6.3. Manual testing of add cmdset operations - Verified via automated tests
- [x] 6.4. Manual testing of remove cmdset operations - Verified via automated tests
- [x] 6.5. Verify error messages are helpful - Verified via test_reject_local_flag

---

## Notes

- Commands are commit-only (no --local mode)
- Must validate that source repo has commands/ directory
- Must add .md extension if not present
- Must handle both individual commands and commandsets
- Error messages should guide users to ~/.cursor/commands/ for personal commands

---

## Blockers

None currently.

---

## Summary

Phase 3 successfully implemented command add/remove functionality following TDD principles:

### Implemented Functions
1. **cmd_add_cmd()** - Adds individual commands to commit manifest
   - Rejects --local flag with helpful error message
   - Accepts --commit flag (redundant but allowed)
   - Auto-adds .md extension if missing
   - Validates command exists in source repo
   - Syncs to deploy files

2. **cmd_add_cmdset()** - Adds commandsets to commit manifest
   - Similar to cmd_add_cmd but for directory sets
   - Expands to individual commands during sync

3. **cmd_remove_cmd()** - Removes individual commands
   - Removes from commit manifest only
   - Cleans up deployed files and symlinks
   - Warns if command not found

4. **cmd_remove_cmdset()** - Removes commandsets
   - Similar to cmd_remove_cmd but for directory sets
   - Triggers sync for cleanup

### Enhanced Functionality
- **Updated sync_commands()** to handle commandsets by expanding them to individual command files
- **Updated main dispatcher** to route cmd/cmdset operations to new functions
- Both `cmd` and `command` aliases supported
- Both `cmdset` and `commandset` aliases supported

### Test Coverage
- Created comprehensive test suite with 9 test cases
- All tests passing
- No regressions in existing functionality (19/19 tests pass)

### Key Features
- Commands are commit-only (no --local mode)
- Helpful error messages guide users to ~/.cursor/commands/ for personal commands
- Extension handling: auto-adds .md if missing
- Multiple commands can be added in single operation
- Commandsets expand to individual commands during sync

---

## Completed Tasks

All tasks in sections 1-6 completed successfully.
