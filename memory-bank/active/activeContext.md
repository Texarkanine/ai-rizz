# Active Context

## Current Task: list-empty-inventory-catalog
**Phase:** BUILD - COMPLETE (retroactive backfill)

## What Was Done

- `cmd_list` auto-enables catalog mode when every active manifest is empty (`cl_any_installed` scan → `cl_show_all=true`).
- Tests: `test_list_nothing_installed_shows_full_catalog`, `test_list_fresh_init_shows_catalog`; prior footer-only test replaced.
- Docs: `list.md`, `getting-started.md` — plain `list` after init.
- `memory-bank/systemPatterns.md` list-view contract updated.
- Feature commit on `no-empty-list`; PR #53 open.

## Next Step

- Run `/niko-qa` → reflect → archive
