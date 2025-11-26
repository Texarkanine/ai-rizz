# Task List: Phase 4 - Listing and Sync

**Phase**: 4 of 7  
**Goal**: Commands visible and synchronized  
**Status**: In Progress  
**Started**: 2025-11-22

---

## Overview

This phase implements command listing and sync functionality, making commands visible through the `ai-rizz list` command and ensuring sync operations handle commands properly.

**Deliverables**:
- Commands appear in listings with proper formatting
- Filtering support (`list rules`, `list cmds`)
- Sync operations include commands
- All changes follow TDD process

---

## Tasks

### 1. Preparation & Planning
- [x] Create task list file
- [ ] Review tech brief requirements for Phase 4
- [ ] Identify existing list and sync test files
- [ ] Plan test structure and coverage

### 2. Test Infrastructure (TDD Step 1: Stub Tests)
- [ ] Create `test_command_listing.test.sh`
- [ ] Add test stubs for listing commands
- [ ] Add test stubs for filtering (rules only, cmds only)
- [ ] Add test stubs to `test_sync_operations.test.sh` for command sync
- [ ] Run stubbed tests to verify they fail appropriately

### 3. Code Infrastructure (TDD Step 2: Stub Functions)
- [ ] Stub `list_commands()` function with empty implementation
- [ ] Update `cmd_list()` to accept filter argument (stub)
- [ ] Verify `cmd_sync()` calls command sync (check implementation)
- [ ] Run tests to verify they still fail (empty implementations)

### 4. Test Implementation (TDD Step 3: Implement Tests)
- [ ] Implement listing tests:
  - [ ] Test list shows commands with proper glyphs
  - [ ] Test list shows installed vs available commands
  - [ ] Test list filters: `list rules` (rules only)
  - [ ] Test list filters: `list cmds` (commands only)
  - [ ] Test list filters: `list` or `list all` (both)
- [ ] Implement sync tests:
  - [ ] Test sync deploys commands
  - [ ] Test sync with both rules and commands
  - [ ] Test sync respects manifest
- [ ] Run tests - all should fail with clear error messages

### 5. Function Implementation (TDD Step 4: Implement Code)
- [ ] Implement `list_commands()`:
  - [ ] Find all .md files in COMMANDS_PATH
  - [ ] Check each against commit manifest
  - [ ] Print with appropriate glyphs
  - [ ] Handle empty commands directory gracefully
- [ ] Update `cmd_list()`:
  - [ ] Accept filter argument (rules|cmds|all)
  - [ ] Route to appropriate list functions
  - [ ] Maintain backwards compatibility (no arg = all)
- [ ] Verify `cmd_sync()` integration with `sync_all_modes()`
- [ ] Run tests iteratively until all pass

### 6. Verification & Quality
- [ ] Run full test suite: `make test`
- [ ] Fix any failures or regressions
- [ ] Verify listing output formatting
- [ ] Test edge cases:
  - [ ] No commands in source repo
  - [ ] Empty manifests
  - [ ] Mixed rules and commands
- [ ] Run individual test suites for detailed verification

### 7. Documentation & Cleanup
- [ ] Update inline documentation for new/modified functions
- [ ] Verify help text is consistent with new behavior
- [ ] Document any assumptions or design decisions
- [ ] Update this task list with final status

---

## Test Files

### New Files
- `tests/unit/test_command_listing.test.sh` - Command listing functionality

### Modified Files
- `tests/unit/test_sync_operations.test.sh` - Add command sync tests

---

## Function Changes

### New Functions
- `list_commands()` - List available commands with status glyphs

### Modified Functions
- `cmd_list()` - Accept filter argument for rules/cmds/all
- Verify `cmd_sync()` / `sync_all_modes()` integration

---

## Design Decisions

1. **Listing Format**: Match rules listing format with same glyphs (●=committed, ○=available)
2. **Filter Syntax**: Accept `rules`, `cmds`/`commands`, `all` (default)
3. **Graceful Degradation**: Handle missing commands/ directory without errors
4. **Consistent Sync**: Commands sync automatically with rules via `sync_all_modes()`

---

## Testing Strategy

### Test Coverage
- Basic listing functionality
- Filter argument handling
- Glyph display for different states
- Empty directory handling
- Sync integration with commands
- Mixed rules and commands scenarios

### Edge Cases
- Source repo without commands/ directory
- Empty commands/ directory
- No commands in manifest
- Commands exist but not in manifest

---

## Notes

- Phase 3 should have implemented `sync_commands()` and command add/remove
- This phase focuses on visibility (listing) and verification (sync works)
- No new deployment logic needed - just surface existing functionality
- Keep listing format consistent with rules for UX continuity

---

## Status Log

- **2025-11-22**: Phase 4 started - creating task list and planning
