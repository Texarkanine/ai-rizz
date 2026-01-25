# Memory Bank: Tasks

## Current Task

**Task ID**: global-mode-command-support
**Title**: Add `--global` mode and unified command support to ai-rizz
**Complexity**: Level 4 (Architectural change with multiple components)
**Status**: PLANNING COMPLETE
**Branch**: `command-support-2`

## Task Summary

Add a third mode (`--global`) to ai-rizz that manages `~/.cursor/` with manifest `~/ai-rizz.skbd`. Simultaneously, add support for commands (`*.md` files) as first-class entities alongside rules (`*.mdc`), using a subdirectory approach that enables fully uniform mode semantics for all entity types.

## Creative Phase Decisions

See `memory-bank/creative/creative-global-mode.md` and `memory-bank/creative/creative-ruleset-command-modes.md`.

**Key Decisions**:
1. Global mode as true third mode (repo-independent)
2. Commands detected by `*.md` extension in `rules/` directory
3. Subdirectory approach for commands (uniform with rules)
4. Mode transition warnings for scope changes
5. Manifest-level conflict detection only
6. `★` glyph for global mode

**Target Directory Structure**:
```
Mode      | Rules Target                | Commands Target                | Invocation
----------|----------------------------|-------------------------------|------------------
local     | .cursor/rules/local/       | .cursor/commands/local/       | /local/...
commit    | .cursor/rules/shared/      | .cursor/commands/shared/      | /shared/...
global    | ~/.cursor/rules/ai-rizz/   | ~/.cursor/commands/ai-rizz/   | /ai-rizz/...
```

## Implementation Plan

### Phase 1: Global Mode Infrastructure

#### 1.1 Constants and Configuration
- [ ] Add `GLOBAL_MANIFEST_FILE="$HOME/ai-rizz.skbd"`
- [ ] Add `GLOBAL_RULES_DIR="$HOME/.cursor/rules/ai-rizz"`
- [ ] Add `GLOBAL_COMMANDS_DIR="$HOME/.cursor/commands/ai-rizz"`
- [ ] Add `GLOBAL_GLYPH="★"`

#### 1.2 Mode Detection
- [ ] Extend `is_mode_active()` to handle `global` mode
- [ ] Create `is_global_mode_active()` - checks `~/ai-rizz.skbd` existence
- [ ] Update `get_any_manifest_metadata()` to include global manifest

#### 1.3 Global Initialization
- [ ] Extend `cmd_init` to support `--global` flag
- [ ] Create global directory structure on init
- [ ] Handle `ai-rizz init --global` (uses source repo from current repo if available)
- [ ] Handle `ai-rizz init <repo> --global` (explicit source repo)

#### 1.4 Global Mode Selection
- [ ] Update `select_mode()` helper to handle three modes
- [ ] Smart mode detection: if only global active, use it without flag
- [ ] Error when multiple modes active and no flag specified

**Tests for Phase 1**:
- [ ] `test_global_mode_init.test.sh` - initialization scenarios
- [ ] `test_global_mode_detection.test.sh` - mode detection with three modes

---

### Phase 2: Command Support Infrastructure

#### 2.1 Entity Type Detection
- [ ] Create `get_entity_type()` - returns "rule" or "command" based on extension
- [ ] Create `is_command()` - checks if entity is `*.md` (not `*.mdc`)

#### 2.2 Command Target Directory Calculation
- [ ] Create `get_commands_target_dir()` - returns appropriate commands subdir
  - local: `.cursor/commands/local/`
  - commit: `.cursor/commands/shared/`
  - global: `~/.cursor/commands/ai-rizz/`

#### 2.3 Update Sync Logic
- [ ] Modify `copy_entry_to_target()` to route by entity type
- [ ] Modify `sync_manifest_to_directory()` to handle both rules and commands dirs
- [ ] Create commands subdirs during sync if needed

#### 2.4 Remove Command Restrictions
- [ ] **DELETE** `show_ruleset_commands_error()` function
- [ ] **REMOVE** check in `cmd_add_ruleset` that blocks local mode for rulesets with commands
- [ ] Update `copy_ruleset_commands()` to use mode-aware target path

**Tests for Phase 2**:
- [ ] `test_command_entity_detection.test.sh` - extension-based detection
- [ ] `test_command_sync.test.sh` - commands synced to correct subdirs
- [ ] `test_command_modes.test.sh` - commands work in all modes

---

### Phase 3: List Display Updates

#### 3.1 Glyph and Display
- [ ] Add global glyph to `is_installed()` return values
- [ ] Update `cmd_list()` to check global manifest
- [ ] Show commands with leading `/` prefix
- [ ] Priority display: `●` > `◐` > `★` (strongest mode wins)

#### 3.2 Command Listing
- [ ] List commands from `rules/*.md` in source repo
- [ ] Show invocation path based on mode: `/local/foo`, `/shared/foo`, `/ai-rizz/foo`

**Tests for Phase 3**:
- [ ] `test_list_global_entities.test.sh` - global entities shown with ★
- [ ] `test_list_commands.test.sh` - commands shown with / prefix

---

### Phase 4: Mode Transition Warnings

#### 4.1 Warning Functions
- [ ] Create `get_entity_current_mode()` - returns which mode(s) entity is in
- [ ] Create `check_mode_transition()` - detects and warns on transitions
- [ ] Create `warn_global_to_repo()` - warning for global → commit/local
- [ ] Create `warn_repo_to_global()` - warning for commit → global

#### 4.2 Integration
- [ ] Call `check_mode_transition()` in `cmd_add_rule()` before adding
- [ ] Call `check_mode_transition()` in `cmd_add_ruleset()` before adding

**Tests for Phase 4**:
- [ ] `test_mode_transition_warnings.test.sh` - all warning scenarios

---

### Phase 5: Deinit and Cleanup

#### 5.1 Global Deinit
- [ ] Extend `cmd_deinit` to support `--global` flag
- [ ] Clean up `~/.cursor/rules/ai-rizz/` and `~/.cursor/commands/ai-rizz/`
- [ ] Remove `~/ai-rizz.skbd`

#### 5.2 Sync Updates
- [ ] Update `cmd_sync` to sync global mode if active
- [ ] Handle sync when both repo and global modes active

**Tests for Phase 5**:
- [ ] `test_global_deinit.test.sh` - cleanup scenarios

---

### Phase 6: Integration and Edge Cases

#### 6.1 Edge Cases
- [ ] Running ai-rizz outside a git repo (global-only context)
- [ ] Mixed mode scenarios (all three active)
- [ ] Ruleset with commands in global mode

#### 6.2 Help and Documentation
- [ ] Update `cmd_help` with global mode documentation
- [ ] Update error messages to mention `--global` option

**Tests for Phase 6**:
- [ ] `test_global_integration.test.sh` - full integration scenarios
- [ ] `test_outside_repo.test.sh` - non-git-repo operation

---

## Test Infrastructure

### New Test Files
```
tests/unit/
├── test_global_mode_init.test.sh
├── test_global_mode_detection.test.sh
├── test_command_entity_detection.test.sh
├── test_command_sync.test.sh
├── test_command_modes.test.sh
├── test_list_global_entities.test.sh
├── test_list_commands.test.sh
├── test_mode_transition_warnings.test.sh
├── test_global_deinit.test.sh

tests/integration/
├── test_global_integration.test.sh
├── test_outside_repo.test.sh
```

### Test Setup Considerations
- Tests need to create/cleanup `$HOME/ai-rizz.skbd` and `~/.cursor/` subdirs
- Use `TEST_HOME` environment variable to isolate test home directory
- Ensure cleanup on test failure

## Dependencies

- None external
- Internal: existing test infrastructure, common.sh helpers

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing local/commit workflows | Comprehensive test coverage of existing functionality |
| Home directory pollution in tests | Use `TEST_HOME` isolation |
| Complex three-way mode interactions | Clear priority rules: commit > local > global |

## Definition of Done

- [ ] All new tests pass
- [ ] All existing tests pass
- [ ] `ai-rizz init <repo> --global` works
- [ ] `ai-rizz add rule foo.mdc --global` works
- [ ] `ai-rizz add rule foo.md --local` works (commands in any mode)
- [ ] `ai-rizz add ruleset niko --local` works (no more restriction)
- [ ] `ai-rizz list` shows global entities with ★
- [ ] `ai-rizz list` shows commands with / prefix
- [ ] Mode transition warnings appear appropriately
- [ ] Help documentation updated
- [ ] `make test` passes

## Next Steps

1. **Create test stubs** for Phase 1
2. **Implement Phase 1** (Global Mode Infrastructure)
3. Iterate through remaining phases following TDD

---

## Progress Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-25 | Creative | COMPLETE | Design decisions finalized |
| 2026-01-25 | Planning | COMPLETE | Implementation plan created |
