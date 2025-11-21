# Task List: Phase 2 - Command Deployment

**Goal**: Deploy commands with symlink creation

**Status**: In Progress  
**Started**: 2025-11-21  

---

## Overview

Implement command deployment functionality with symlink creation, following TDD methodology.

---

## Tasks

### 1. Scope Determination ✅
- [x] Review Phase 2 requirements from TECH_BRIEF.md
- [x] Identify test scenarios needed
- [x] Identify functions to implement

### 2. Preparation (Stubbing)
- [ ] Create test file: `test_command_deployment.test.sh`
- [ ] Stub test cases with empty implementations
- [ ] Add `deploy_command()` stub to `ai-rizz`
- [ ] Add `remove_command()` stub to `ai-rizz`
- [ ] Verify test file runs (all tests should skip/pass empty)

### 3. Write Tests
- [ ] Implement test: deploy command creates file in shared-commands/
- [ ] Implement test: deploy command creates symlink in commands/
- [ ] Implement test: symlink points to correct target
- [ ] Implement test: collision detection (non-symlink file exists)
- [ ] Implement test: collision detection (wrong symlink target)
- [ ] Implement test: remove command deletes both files
- [ ] Implement test: remove command ignores non-symlink files
- [ ] Run tests - verify they fail (expected)

### 4. Write Code
- [ ] Implement `deploy_command()` function
- [ ] Implement `remove_command()` function
- [ ] Run tests - iterate until all pass
- [ ] Run full test suite to verify no regressions

### 5. Verification
- [ ] All new tests pass
- [ ] All existing tests still pass
- [ ] Code follows project conventions
- [ ] Functions properly documented

---

## Test Scenarios

1. **Deploy Command Creates File**: Verify actual file created in `.cursor/shared-commands/`
2. **Deploy Command Creates Symlink**: Verify symlink created in `.cursor/commands/`
3. **Symlink Target Correct**: Verify symlink points to `../shared-commands/filename`
4. **Collision Non-Symlink**: Error when non-symlink file exists at symlink location
5. **Collision Wrong Symlink**: Error when symlink exists but points elsewhere
6. **Remove Deletes Both**: Verify both symlink and actual file removed
7. **Remove Ignores Non-Symlinks**: Verify non-symlink files in commands/ not touched

---

## Functions to Implement

### `deploy_command()`
- **Purpose**: Deploy command file and create symlink
- **Parameters**: Command name (e.g., "review-code.md")
- **Behavior**:
  - Copy file from repo to `.cursor/shared-commands/`
  - Create symlink in `.cursor/commands/`
  - Validate source exists
  - Detect collisions
  - Create directories as needed

### `remove_command()`
- **Purpose**: Remove command file and symlink
- **Parameters**: Command name
- **Behavior**:
  - Remove symlink if it's ours (points to shared-commands/)
  - Remove actual file from shared-commands/
  - Ignore non-symlink files

---

## Notes

- Follow existing function naming conventions (snake_case, prefixed local vars)
- Use constants: `SHARED_COMMANDS_DIR="shared-commands"`
- Deploy commands always go to shared-commands/ (no mode-specific subdirectories)
- Symlinks use relative paths for portability
- Error messages should be actionable

---

## Blockers

None currently identified.

---

## Decisions Made

1. Commands are commit-only (Phase 2 doesn't need mode handling)
2. Symlinks use relative paths (`../shared-commands/filename`)
3. Only manage symlinks pointing to `../shared-commands/`
