# Active Context

## Current Task: deinit-guard-or-remove-all
**Phase:** BUILD - COMPLETE

## What Was Done
- Replaced `deinit --all`/`-a` with `deinit --both`/`-b` (local+commit only; global untouched)
- Actionable rejection for `--all`/`-a` and typed/env `all`
- Updated integrity Option 3, docs, help, completion
- Tests: function + CLI suites updated; global-preservation + rejection coverage; `make test` 35/35

## Files Modified
- `/home/mobaxterm/git/ai-rizz/ai-rizz`
- `/home/mobaxterm/git/ai-rizz/completion.bash`
- `/home/mobaxterm/git/ai-rizz/docs/user-guide/commands/init-deinit.md`
- `/home/mobaxterm/git/ai-rizz/docs/user-guide/commands/index.md`
- `/home/mobaxterm/git/ai-rizz/tests/integration/functions/test_deinit_modes.test.sh`
- `/home/mobaxterm/git/ai-rizz/tests/integration/test_cli_deinit.test.sh`

## Key Decisions
- `-b` short flag for `--both` (parity with other mode shorts)
- No single-flag wipe of local+commit+global; use `--both` then `--global`

## Deviations from Plan
- None material — built to plan

## Next Step
- QA review
