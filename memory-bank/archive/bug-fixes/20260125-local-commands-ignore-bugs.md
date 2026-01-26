# TASK ARCHIVE: Local Commands Ignore Bugs

## METADATA

- **Task ID**: local-commands-ignore-bugs
- **Date Completed**: 2026-01-25
- **Complexity**: Level 2
- **Branch**: `ignore-local-commands`
- **Category**: Bug Fix
- **PR**: [#18](https://github.com/Texarkanine/ai-rizz/pull/18)

## SUMMARY

Fixed two bugs related to `.cursor/commands/local` handling:
1. Re-init not fixing missing excludes on repos initialized before commands support
2. Deinit confirmation message not mentioning commands directory would be deleted

## REQUIREMENTS

**Bug 1**: When `ai-rizz init --local` is run on a repo initialized before `.cursor/commands/local` support was added, it said "already initialized; no changes needed" without fixing the missing exclude pattern.

**Bug 2**: `ai-rizz deinit --local` said "This will delete: ai-rizz.local.skbd .cursor/rules/local" but didn't mention `.cursor/commands/local/` which it also deleted.

## IMPLEMENTATION

### Bug 1 Fix
Added `setup_local_mode_excludes()` call before the "already initialized" early return in `cmd_init()`. This ensures all three excludes are present even on re-init of older repos.

### Bug 2 Fix
Added `.cursor/commands/${LOCAL_DIR}` to the `cd_items_to_remove` variable in `cmd_deinit()` for local mode. Also fixed commit mode for consistency.

### Code Changes
- `ai-rizz` line ~2641: Added `setup_local_mode_excludes "${ci_target_dir}"` before return
- `ai-rizz` line ~2928: Added `.cursor/commands/${LOCAL_DIR}` to confirmation message
- `ai-rizz` line ~2931: Added `.cursor/commands/${SHARED_DIR}` for commit mode consistency

## TESTING

- Added `test_reinit_local_fixes_missing_commands_exclude` in `test_initialization.test.sh`
- Added `test_deinit_local_message_includes_commands_dir` in `test_deinit_modes.test.sh`
- All 30/30 tests pass
- Manual verification on test repo confirmed both fixes work

## LESSONS LEARNED

1. **Idempotent Operations Should Be Complete**: The "already initialized" path assumed nothing needed fixing, but should have ensured all expected state is present.

2. **Confirmation Messages Should Match Actions**: If code deletes something, the confirmation message should mention it.

3. **Historical Compatibility**: When adding new features that require state changes, consider that existing installations won't have that state. Re-init should be a mechanism to "upgrade" existing installations.

## REFERENCES

- Reflection: `memory-bank/reflection/reflection-local-commands-ignore-bugs.md`
- PR: https://github.com/Texarkanine/ai-rizz/pull/18
