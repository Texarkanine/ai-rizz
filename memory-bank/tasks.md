# Memory Bank: Tasks

## Current Task

**Task ID**: global-mode-command-support
**Title**: Add `--global` mode and unified command support to ai-rizz
**Complexity**: Level 4 (Architectural change with multiple components)
**Status**: ✅ IMPLEMENTATION COMPLETE - DRAFT PR CREATED
**Branch**: `command-support-2`
**PR**: https://github.com/Texarkanine/ai-rizz/pull/14

## Task Summary

Add a third mode (`--global`) to ai-rizz that manages `~/.cursor/` with manifest `~/ai-rizz.skbd`. Simultaneously, add support for commands (`*.md` files) as first-class entities alongside rules (`*.mdc`), using a subdirectory approach that enables fully uniform mode semantics for all entity types.

## Creative Phase Decisions

See `memory-bank/creative/creative-global-mode.md` and `memory-bank/creative/creative-ruleset-command-modes.md`.

**Key Decisions**:
1. Global mode as true third mode (repo-independent)
2. Commands detected by `*.md` extension in `rules/` directory
3. Subdirectory approach for commands (uniform with rules)
4. Mode transition warnings for scope changes (DEFERRED)
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

## Implementation Status

### Phase 1: Global Mode Infrastructure ✅ COMPLETE

#### 1.1 Constants and Configuration
- [x] Add `GLOBAL_MANIFEST_FILE="$HOME/ai-rizz.skbd"`
- [x] Add `GLOBAL_RULES_DIR="$HOME/.cursor/rules/ai-rizz"`
- [x] Add `GLOBAL_COMMANDS_DIR="$HOME/.cursor/commands/ai-rizz"`
- [x] Add `GLOBAL_GLYPH="★"`
- [x] Add `init_global_paths()` for dynamic path initialization (test isolation)

#### 1.2 Mode Detection
- [x] Extend `is_mode_active()` to handle `global` mode
- [x] Update `get_any_manifest_metadata()` to include global manifest
- [x] Update `cache_manifest_metadata()` to include global manifest

#### 1.3 Global Initialization
- [x] Extend `cmd_init` to support `--global` flag
- [x] Create global directory structure on init
- [x] Handle `ai-rizz init --global` (uses source repo from current repo if available)
- [x] Handle `ai-rizz init <repo> --global` (explicit source repo)
- [x] Idempotency for global mode (re-init is no-op)

#### 1.4 Global Mode Selection
- [x] Update `select_mode()` helper to handle three modes
- [x] Smart mode detection: if only one mode active, use it without flag
- [x] Error when multiple modes active and no flag specified
- [x] Update error messages to include `--global` option

**Tests**: `test_global_mode_init.test.sh`, `test_global_mode_detection.test.sh`

---

### Phase 2: Command Support Infrastructure ✅ COMPLETE

#### 2.1 Entity Type Detection
- [x] Create `is_command()` - checks if entity is `*.md` (not `*.mdc`)
- [x] Create `get_entity_type()` - returns "rule" or "command" based on extension

#### 2.2 Command Target Directory Calculation
- [x] Create `get_commands_target_dir()` - returns appropriate commands subdir
  - local: `.cursor/commands/local/`
  - commit: `.cursor/commands/shared/`
  - global: `~/.cursor/commands/ai-rizz/`

#### 2.3 Update Sync Logic
- [x] Modify `copy_entry_to_target()` to route by entity type
- [x] Modify `sync_manifest_to_directory()` to handle both rules and commands dirs
- [x] Add mode parameter to sync functions
- [x] Create commands subdirs during sync if needed

#### 2.4 Remove Command Restrictions
- [x] **DELETED** `show_ruleset_commands_error()` function
- [x] **REMOVED** check in `cmd_add_ruleset` that blocked local mode for rulesets with commands
- [x] **REMOVED** auto-switch to commit mode for rulesets with commands
- [x] Update `copy_ruleset_commands()` to use mode-aware target path

**Tests**: `test_command_entity_detection.test.sh`, `test_command_sync.test.sh`, `test_command_modes.test.sh`

---

### Phase 3: List Display Updates ✅ COMPLETE

#### 3.1 Glyph and Display
- [x] Add global glyph to `is_installed()` return values
- [x] Update `cmd_list()` to check global manifest
- [x] Priority display: `●` > `◐` > `★` (strongest mode wins)
- [x] Add global manifest validation in `cmd_list()`

**Tests**: Covered by existing list display tests

---

### Phase 4: Mode Transition Warnings ⏸️ DEFERRED

Deferred to follow-up PR. Not critical for initial release.

---

### Phase 5: Deinit and Cleanup ✅ COMPLETE

#### 5.1 Global Deinit
- [x] Extend `cmd_deinit` to support `--global` flag
- [x] Clean up `~/.cursor/rules/ai-rizz/` and `~/.cursor/commands/ai-rizz/`
- [x] Remove `~/ai-rizz.skbd`
- [x] Update mode prompt to include global option

#### 5.2 Command Cleanup
- [x] Update `cmd_remove_ruleset()` to clean commands in all modes
- [x] Update `cmd_deinit()` to clean command directories

**Tests**: Covered by existing deinit tests

---

### Phase 6: Integration and Edge Cases ⏸️ DEFERRED

#### Completed
- [x] Rulesets with commands in global mode
- [x] Mixed mode scenarios (all three active)

#### Deferred
- [ ] Running ai-rizz outside a git repo (global-only context)
- [ ] Help documentation updates

---

## Test Infrastructure

### New Test Files Created
```
tests/unit/
├── test_global_mode_init.test.sh        ✅
├── test_global_mode_detection.test.sh   ✅
├── test_command_entity_detection.test.sh ✅
├── test_command_sync.test.sh            ✅
├── test_command_modes.test.sh           ✅
```

### Updated Test Files
```
tests/unit/
├── test_ruleset_bug_fixes.test.sh       ✅ (updated command paths)
├── test_ruleset_commands.test.sh        ✅ (updated for new behavior)
├── test_ruleset_removal_and_structure.test.sh ✅ (updated command paths)
├── test_symlink_security.test.sh        ✅ (updated command paths)
```

### Test Results
- **All 28 tests pass** (21 unit + 7 integration)

## Definition of Done

- [x] All new tests pass
- [x] All existing tests pass
- [x] `ai-rizz init <repo> --global` works
- [x] `ai-rizz add rule foo.mdc --global` works
- [x] `ai-rizz add rule foo.md --local` works (commands in any mode)
- [x] `ai-rizz add ruleset niko --local` works (no more restriction)
- [x] `ai-rizz list` shows global entities with ★
- [ ] `ai-rizz list` shows commands with / prefix (DEFERRED)
- [ ] Mode transition warnings appear appropriately (DEFERRED)
- [ ] Help documentation updated (DEFERRED)
- [x] `make test` passes

## Follow-up Items

1. Mode transition warnings (Phase 4)
2. Running ai-rizz outside git repos (Phase 6)
3. Help documentation updates
4. Command listing with `/` prefix in display

---

## Progress Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-25 | Creative | COMPLETE | Design decisions finalized |
| 2026-01-25 | Planning | COMPLETE | Implementation plan created |
| 2026-01-25 | Phase 1 | COMPLETE | Global mode infrastructure |
| 2026-01-25 | Phase 2 | COMPLETE | Command support infrastructure |
| 2026-01-25 | Phase 3 | COMPLETE | List display updates |
| 2026-01-25 | Phase 5 | COMPLETE | Deinit and cleanup |
| 2026-01-25 | PR | CREATED | Draft PR #14 |
