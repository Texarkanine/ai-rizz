# Memory Bank: Tasks

## Current Task

**Task ID**: global-mode-command-support
**Title**: Add `--global` mode and unified command support to ai-rizz
**Complexity**: Level 4 (Architectural change with multiple components)
**Status**: ✅ ALL PHASES COMPLETE - Ready for Review
**Branch**: `command-support-2`
**PR**: https://github.com/Texarkanine/ai-rizz/pull/15

## Task Summary

Add a third mode (`--global`) to ai-rizz that manages `~/.cursor/` with manifest `~/ai-rizz.skbd`. Simultaneously, add support for commands (`*.md` files) as first-class entities alongside rules (`*.mdc`), using a subdirectory approach that enables fully uniform mode semantics for all entity types.

## Creative Phase Decisions

See:
- `memory-bank/creative/creative-global-mode.md`
- `memory-bank/creative/creative-ruleset-command-modes.md`
- `memory-bank/creative/creative-repo-cache-isolation.md` (Phase 7 bug fix)

**Key Decisions**:
1. Global mode as true third mode (repo-independent)
2. Commands detected by `*.md` extension in `rules/` directory
3. Subdirectory approach for commands (uniform with rules)
4. Mode transition warnings for scope changes
5. Manifest-level conflict detection only
6. `★` glyph for global mode
7. **Global cache uses fixed name `_ai-rizz.global`** (Phase 7)
8. **Gated cross-mode operations when source repos differ** (Phase 7)

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

### Phase 4: Mode Transition Warnings ✅ COMPLETE

#### 4.1 Entity Mode Detection
- [x] Create `get_entity_installed_mode()` - Returns which mode an entity is currently in
- [x] Checks commit > local > global (priority order)
- [x] Returns "none" for new entities

#### 4.2 Mode Transition Warnings
- [x] Create `warn_mode_transition()` - Emits appropriate warnings
- [x] Warns for global → commit/local transitions
- [x] Warns for commit → global transition (team impact)
- [x] Warns for local → global transition
- [x] No warning for new entities or same-mode re-adds

#### 4.3 Integration
- [x] Integrate warnings in `cmd_add_rule()`
- [x] Integrate warnings in `cmd_add_ruleset()`

**Tests**: `test_mode_transition_warnings.test.sh` (12 tests)

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

### Phase 6: Integration and Edge Cases ✅ COMPLETE

#### 6.1 Global-Only Context
- [x] Global mode works outside git repositories
- [x] `ai-rizz init --global` works outside git repos
- [x] `ai-rizz add rule/ruleset --global` works outside git repos
- [x] `ai-rizz list` works with global-only context
- [x] `ai-rizz deinit --global` works outside git repos
- [x] Smart mode selection auto-selects global when only mode initialized

#### 6.2 Help Documentation
- [x] Added `--global/-g` to mode options
- [x] Added modes section explaining commit/local/global
- [x] Added glyph legend (●/◐/★/○)

#### 6.3 Edge Cases
- [x] Rulesets with commands in global mode
- [x] Mixed mode scenarios (all three active)
- [x] Commit mode correctly fails outside git repos (requires git)

**Tests**: `test_global_only_context.test.sh` (10 tests)

---

## Test Infrastructure

### New Test Files Created
```
tests/unit/
├── test_global_mode_init.test.sh         ✅
├── test_global_mode_detection.test.sh    ✅
├── test_command_entity_detection.test.sh ✅
├── test_command_sync.test.sh             ✅
├── test_command_modes.test.sh            ✅
├── test_mode_transition_warnings.test.sh ✅ (Phase 4)
├── test_global_only_context.test.sh      ✅ (Phase 6)
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
- **All 30 tests pass** (23 unit + 7 integration)

## Definition of Done

- [x] All new tests pass
- [x] All existing tests pass
- [x] `ai-rizz init <repo> --global` works
- [x] `ai-rizz add rule foo.mdc --global` works
- [x] `ai-rizz add rule foo.md --local` works (commands in any mode)
- [x] `ai-rizz add ruleset niko --local` works (no more restriction)
- [x] `ai-rizz list` shows global entities with ★
- [x] `ai-rizz list` shows commands with / prefix
- [x] Mode transition warnings appear appropriately
- [x] Help documentation updated with --global option
- [x] Running ai-rizz outside git repos works (global-only context)
- [x] `make test` passes (30/30 tests)

## Follow-up Items

None - all features complete.

---

## CRITICAL BUG: Cache Isolation Required

**Bug ID**: global-cache-isolation
**Severity**: Critical
**Status**: ✅ COMPLETE

### Problem Description

Two related bugs discovered in global mode implementation:

**Bug 1: Global mode cache naming collision**
- `get_repo_dir()` uses `basename $(pwd)` when outside git repos
- Running `ai-rizz init --global` in `/home/alice` → cache `alice`
- Running `ai-rizz init --global` in `~/documents/git` → cache `git`
- These are the SAME global mode but get DIFFERENT caches
- Global mode should always use the SAME cache regardless of where you run from

**Bug 2: Mixed source repo operations silently broken**
- `REPO_DIR` is set ONCE at startup from current context
- If global uses repo X and local uses repo Y:
  - `ai-rizz add rule foo --global` looks in repo Y's cache (WRONG!)
  - May find wrong rule or fail silently

### Root Cause

Single `REPO_DIR` variable cannot represent both:
- Global mode's source repo (user-wide, context-independent)
- Local/commit mode's source repo (project-specific)

### Solution: Gated Cross-Mode Operations

See `memory-bank/creative/creative-repo-cache-isolation.md` for full design.

**Key decisions**:
1. Global mode uses fixed cache name: `_ai-rizz.global`
2. Local/commit modes share project cache (UNCHANGED - core feature)
3. Track `GLOBAL_REPO_DIR` separately from `REPO_DIR`
4. Gate cross-mode operations when source repos differ
5. Full flexibility when source repos match

---

### Phase 7: Cache Isolation and Cross-Mode Gating

**Complexity**: Level 2 (Bug fix with architectural implications)
**Estimated Scope**: ~100-150 lines changed

#### 7.1 Global Cache Path (Fixed Name) ✅

- [x] Create `get_global_repo_dir()` function
  - Returns `${CONFIG_DIR}/repos/_ai-rizz.global/repo`
  - Deterministic, never changes based on PWD
  - Name `_ai-rizz.global` cannot conflict with git repo names

- [x] Add `GLOBAL_REPO_DIR` variable
  - Separate from `REPO_DIR` which is for local/commit
  - Set during `cache_manifest_metadata()` when global mode active

#### 7.2 Global Repository Sync ✅

- [x] Modify `cache_manifest_metadata()` to set `GLOBAL_REPO_DIR`
  - When global manifest exists, read its source repo
  - Set `GLOBAL_REPO_DIR = get_global_repo_dir()`

- [x] Create `sync_global_repo()` function
  - Syncs global manifest's source repo to `GLOBAL_REPO_DIR`
  - Called when operating on global mode

#### 7.3 Source Repo Comparison ✅

- [x] Create `get_global_source_repo()` function
  - Reads source repo from global manifest
  - Returns empty if global mode not active

- [x] Create `get_local_commit_source_repo()` function
  - Reads source repo from local/commit manifest
  - Returns empty if neither mode active

- [x] Create `repos_match()` function
  - Compares global source repo with local/commit source repo
  - Returns true if same or if only one mode active
  - Returns false if different repos

#### 7.4 Cross-Mode Operation Gating ✅

- [x] Create `get_repo_dir_for_mode()` function
  - Returns `GLOBAL_REPO_DIR` for global mode
  - Returns `REPO_DIR` for local/commit modes

- [x] Update `check_repository_item()` with repo_dir parameter
  - Accepts optional repo_dir to check in
  - Defaults to REPO_DIR for backward compatibility

- [x] Update `cmd_add_rule()` with gating logic
  - Uses `get_repo_dir_for_mode()` to get correct repo
  - Passes repo dir to `check_repository_item()`

- [x] Update `cmd_add_ruleset()` with same gating logic

#### 7.7 Test Coverage ✅

New test file: `test_cache_isolation.test.sh` (12 tests)

- [x] Test `GLOBAL_REPO_DIR` set correctly
- [x] Test `repos_match()` returns true when repos same
- [x] Test `repos_match()` returns false when repos differ
- [x] Test `repos_match()` returns true with single mode
- [x] Test `get_global_source_repo()` extracts URL
- [x] Test `get_global_source_repo()` returns empty when no manifest
- [x] Test `get_repo_dir_for_mode()` returns correct dir for each mode
- [x] Test add rule in commit mode uses REPO_DIR
- [x] Test add rule in global mode uses GLOBAL_REPO_DIR

---

### Implementation Order

1. **7.1** - Global cache path (foundation)
2. **7.2** - Global repo sync (makes global independent)
3. **7.3** - Repo comparison (enables gating)
4. **7.4** - Cross-mode gating (core fix)
5. **7.5** - Ambiguous mode selection (UX improvement)
6. **7.6** - List display (polish)
7. **7.7** - Tests (throughout, TDD)

### Files to Modify

| File | Changes |
|------|---------|
| `ai-rizz` | Add `get_global_repo_dir()`, `GLOBAL_REPO_DIR`, gating logic |
| `tests/unit/test_cache_isolation.test.sh` | New test file |
| `tests/unit/test_global_mode_init.test.sh` | Update for new cache path |

### What Stays UNCHANGED

- `REPO_DIR` for local/commit modes
- Local ↔ commit conflict resolution
- `copy_entry_to_target()` and sync internals
- Most existing test files (except paths)

### Definition of Done ✅

- [x] Global mode always uses `_ai-rizz.global` cache
- [x] `ai-rizz add rule --global` works with global's repo
- [x] `ai-rizz add rule --local` works with local's repo
- [x] Cross-mode ops use correct repo for each mode
- [x] All existing tests pass (24 unit + 7 integration)
- [x] New tests for cache isolation pass (12 tests)

---

## Progress Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-25 | Creative | COMPLETE | Design decisions finalized |
| 2026-01-25 | Planning | COMPLETE | Implementation plan created |
| 2026-01-25 | Phase 1 | COMPLETE | Global mode infrastructure |
| 2026-01-25 | Phase 2 | COMPLETE | Command support infrastructure |
| 2026-01-25 | Phase 3 | COMPLETE | List display updates |
| 2026-01-25 | Phase 4 | COMPLETE | Mode transition warnings |
| 2026-01-25 | Phase 5 | COMPLETE | Deinit and cleanup |
| 2026-01-25 | Phase 6 | COMPLETE | Global-only context + help docs |
| 2026-01-25 | PR | UPDATED | All phases complete, 30/30 tests pass |
| 2026-01-25 | Command Display | COMPLETE | Added / prefix for commands in list |
| 2026-01-25 | **BUG** | DISCOVERED | Cache isolation + mixed repo ops broken |
| 2026-01-25 | Phase 7 Creative | COMPLETE | Gated cross-mode operations solution |
| 2026-01-25 | Phase 7 Planning | COMPLETE | Implementation plan ready |
| 2026-01-25 | Phase 7 Impl | COMPLETE | Cache isolation implemented, 31/31 tests pass |
