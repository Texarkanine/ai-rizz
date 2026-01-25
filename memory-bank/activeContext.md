# Memory Bank: Active Context

## Current Focus

**Task**: Add `--global` mode and unified command support to ai-rizz
**Phase**: ✅ ALL PHASES COMPLETE - Ready for Review
**Branch**: `command-support-2`
**PR**: https://github.com/Texarkanine/ai-rizz/pull/14

## Implementation Summary

### Completed Features

1. **Global Mode (`--global|-g`)**
   - Manifest: `~/ai-rizz.skbd`
   - Rules: `~/.cursor/rules/ai-rizz/`
   - Commands: `~/.cursor/commands/ai-rizz/`
   - Glyph: `★` for global items in list display
   - Full support in `init`, `add`, `remove`, `deinit`, and `list` commands

2. **Unified Command Support**
   - Commands (`*.md` files) now work in ALL modes
   - Mode-specific subdirectories:
     - Local: `.cursor/commands/local/`
     - Commit: `.cursor/commands/shared/`
     - Global: `~/.cursor/commands/ai-rizz/`
   - **Removed** restriction that forced rulesets with commands to commit mode

3. **New Functions Added**
   - `init_global_paths()` - Dynamic path initialization for test isolation
   - `is_command()` - Detects `*.md` files as commands
   - `get_entity_type()` - Returns "rule" or "command"
   - `get_commands_target_dir()` - Returns mode-specific commands directory

4. **Functions Updated**
   - `is_mode_active()` - Now handles `global` mode
   - `select_mode()` - Three-mode selection logic
   - `cmd_init()` - `--global` flag support
   - `cmd_deinit()` - `--global` flag support
   - `cmd_list()` - Global mode validation and display
   - `cmd_add_rule()` - `--global` flag support
   - `cmd_add_ruleset()` - `--global` flag support
   - `cmd_remove_ruleset()` - Global mode cleanup
   - `copy_entry_to_target()` - Mode-aware command routing
   - `sync_manifest_to_directory()` - Mode parameter support
   - `sync_all_modes()` - Global mode sync

5. **Functions Deleted**
   - `show_ruleset_commands_error()` - No longer needed

## Key Files Modified

- `ai-rizz` - Main script (~564 lines changed)
- `tests/unit/test_ruleset_bug_fixes.test.sh` - Updated paths
- `tests/unit/test_ruleset_commands.test.sh` - Updated tests for new behavior
- `tests/unit/test_ruleset_removal_and_structure.test.sh` - Updated paths
- `tests/unit/test_symlink_security.test.sh` - Updated paths

## New Test Files

- `tests/unit/test_global_mode_init.test.sh`
- `tests/unit/test_global_mode_detection.test.sh`
- `tests/unit/test_command_entity_detection.test.sh`
- `tests/unit/test_command_sync.test.sh`
- `tests/unit/test_command_modes.test.sh`

## Test Results

**All 30 tests pass** (23 unit + 7 integration)

## Completed in This Session

1. **Phase 4: Mode Transition Warnings** - Implemented
   - `get_entity_installed_mode()` - detects current mode of entity
   - `warn_mode_transition()` - emits appropriate warnings
   - Integrated into `cmd_add_rule()` and `cmd_add_ruleset()`
   - 12 new tests in `test_mode_transition_warnings.test.sh`

2. **Phase 6: Global-Only Context** - Implemented
   - Global mode works outside git repositories
   - Smart mode selection auto-selects global when only mode active
   - Commit mode correctly fails outside git repos
   - 10 new tests in `test_global_only_context.test.sh`

3. **Help Documentation** - Updated
   - Added `--global/-g` to mode options
   - Added modes section explaining commit/local/global
   - Added glyph legend (●/◐/★/○)

## Critical Bug Discovered

Two related bugs found in global mode implementation:

### Bug 1: Global Cache Naming Collision
- `get_repo_dir()` uses `basename $(pwd)` when outside git repos
- Running `ai-rizz init --global` in different directories creates different caches
- Should always use SAME cache (`_ai-rizz.global`) regardless of PWD

### Bug 2: Mixed Source Repo Operations Broken
- `REPO_DIR` is set ONCE at startup
- If global mode uses repo X and local uses repo Y:
  - `ai-rizz add rule --global` looks in repo Y's cache (WRONG!)
  - May find wrong rule or fail silently

## Phase 7 Complete: Cache Isolation Bug Fix

See `memory-bank/creative/creative-repo-cache-isolation.md` for full design.

**Implementation**:
1. Global mode uses fixed cache: `_ai-rizz.global`
2. Local/commit modes share project cache (UNCHANGED - core feature)
3. `GLOBAL_REPO_DIR` tracked separately from `REPO_DIR`
4. `get_repo_dir_for_mode()` returns correct repo for each mode
5. `repos_match()` compares global vs local/commit source repos

**New functions**:
- `get_global_repo_dir()` - Fixed global cache path
- `sync_global_repo()` - Global repo synchronization
- `get_global_source_repo()` - Extract repo from global manifest
- `get_local_commit_source_repo()` - Extract repo from local/commit manifest
- `repos_match()` - Compare source repos
- `get_repo_dir_for_mode()` - Mode-aware repo selection

**Test coverage**: 12 new tests in `test_cache_isolation.test.sh`

## Status

- All 31 tests pass (24 unit + 7 integration)
- All phases complete (1-7)
- PR ready for review

## Open Questions

None - all implementation complete.

## Blockers

None - ready for review and merge.
