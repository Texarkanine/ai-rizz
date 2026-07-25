# Active Context

## Current Task: fix-sync-standalone-entry-relocates
**Phase:** BUILD - COMPLETE

## What Was Done
- Added `resolve_standalone_entry()` (exact hit, then skill → `.mdc` → `.md` slug remap)
- Refactored `cmd_add_rule` to use the shared resolver
- Wired remap + manifest rewrite into `sync_manifest_to_directory`
- Tests: `tests/unit/test_resolve_standalone_entry.test.sh` (12), `tests/integration/functions/test_sync_entry_relocates.test.sh` (7)
- Docs: `docs/user-guide/commands/sync.md`, `docs/developer-guide/manifest.md`
- `make test`: 37/37 PASS

## Files modified
- `/home/mobaxterm/git/ai-rizz/ai-rizz`
- `/home/mobaxterm/git/ai-rizz/tests/unit/test_resolve_standalone_entry.test.sh`
- `/home/mobaxterm/git/ai-rizz/tests/integration/functions/test_sync_entry_relocates.test.sh`
- `/home/mobaxterm/git/ai-rizz/docs/user-guide/commands/sync.md`
- `/home/mobaxterm/git/ai-rizz/docs/developer-guide/manifest.md`

## Next Step
- QA phase
