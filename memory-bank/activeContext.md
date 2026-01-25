# Memory Bank: Active Context

## Current Focus

**Task**: Add `--global` mode and unified command support to ai-rizz
**Phase**: ✅ Implementation Complete - Draft PR Created
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

**All 28 tests pass** (21 unit + 7 integration)

## Deferred Items

1. **Mode Transition Warnings** - Warn when entity scope changes
2. **Running Outside Git Repos** - Global-only context support
3. **Help Documentation Updates** - `--global` in help text
4. **Command `/` Prefix Display** - Show commands with leading `/`

## Next Steps

1. **Wait for PR review** on https://github.com/Texarkanine/ai-rizz/pull/14
2. **Manual testing** of global mode in real-world scenario
3. **Follow-up PR** for deferred items if needed

## Open Questions

None - implementation complete.

## Blockers

None.
