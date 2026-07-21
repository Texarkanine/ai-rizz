# Active Context

## Current Task: fix-issues-40-41-repo-global-select
**Phase:** BUILD - COMPLETE

## What Was Done
- Repo-aware `select_mode()`: inside `.git`, auto-select only local/commit; zero repo modes → `show_repo_mode_required_error`
- Tests extended in `tests/integration/functions/test_global_mode_detection.test.sh`
- Docs: `docs/user-guide/rule-modes.md` “Choosing a mode”
- `make test` 34/34 PASS

## Files modified
- `/home/mobaxterm/git/ai-rizz/ai-rizz`
- `/home/mobaxterm/git/ai-rizz/tests/integration/functions/test_global_mode_detection.test.sh`
- `/home/mobaxterm/git/ai-rizz/docs/user-guide/rule-modes.md`

## Key decisions
- New actionable error helper instead of reusing “Multiple modes available” for the zero-repo-mode case
- No change to `add_manifest_entry_to_file` — select_mode gate prevents the bad add path

## Next Step
- QA phase
