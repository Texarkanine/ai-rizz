# Active Context

## Current Task: list-installed-default
**Phase:** BUILD - COMPLETE

## What Was Done

- Default `cmd_list` is inventory; `-a`/`--all` is catalog; footer `N available, not shown`; empty-of-installed section headers omitted.
- Cheap completion test: stub `_init_completion` via `COMP_TEST_PREV`/`COMP_TEST_CUR` env (the stub's `$1`/`$2` are empty because `_ai_rizz_completion` calls it with no args).
- Help, docs, getting-started discovery uses `list --all`. `make test` 37/37. `make docs-build` passed.
- Did not apply the advisory footer hint `(ai-rizz list --all)` — brief pins the exact string.

## Next Step

- QA review (subagent).
