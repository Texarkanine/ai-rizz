# Memory Bank: Tasks

## Current Task

**Task ID**: local-commands-ignore-bugs
**Title**: Fix local commands directory git ignore and deinit message bugs
**Complexity**: Level 2
**Status**: Complete (Reflected)
**Branch**: `ignore-local-commands`

## Description

Two bugs related to `.cursor/commands/local` handling:

1. **Re-init doesn't fix missing excludes**: When `ai-rizz init --local` is run on a repo that was initialized before `.cursor/commands/local` support was added, it says "already initialized; no changes needed" without fixing the missing exclude pattern.

2. **Deinit message incomplete**: `ai-rizz deinit --local` says "This will delete: ai-rizz.local.skbd .cursor/rules/local" but doesn't mention `.cursor/commands/local/` which it also deletes.

## Implementation Plan

### Test Planning (TDD)
1. Add test: re-init --local fixes missing `.cursor/commands/local` exclude
2. Add test: deinit message includes `.cursor/commands/local`

### Code Changes
1. **Bug 1** (line ~2641): In the "already initialized" path, call `setup_local_mode_excludes` to ensure excludes are complete before returning
2. **Bug 2** (line 2926): Add `.cursor/commands/${LOCAL_DIR}` to `cd_items_to_remove`

## Definition of Done

- [x] Test: re-init fixes missing command exclude
- [x] Test: deinit message includes command dir
- [x] All existing tests pass (30/30)
- [x] Manual verification
