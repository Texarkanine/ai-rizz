---
task_id: mac-compat-bugs
complexity_level: 2
date: 2026-05-12
status: completed
---

# TASK ARCHIVE: macOS/BSD Cross-Platform Bug Fixes

## SUMMARY

Fixed three cross-platform bugs that broke ai-rizz on macOS/BSD: GNU-only `find -printf` in `completion.bash`, locale-sensitive `[A-Z]` character ranges that silently skipped lowercase `.md` commands, and `find -empty -delete` removing the commands target root directory. Changes are portable, defensive, and non-breaking for GNU/Linux. Full integration test suite passed (33 tests).

## REQUIREMENTS

- **Bug 1:** Replace `find -printf "%f\n"` in `completion.bash` (rules/rulesets completion) with portable basename extraction (e.g. `sed 's|.*/||'`).
- **Bug 2:** Ensure `[A-Z]` filtering and `grep -v '^[A-Z]'` behave as intended under UTF-8 locales — set `LC_ALL=C` at top of `ai-rizz` and inline `LC_ALL=C` on the completion `grep`.
- **Bug 3:** Prevent `find "${commands_dir}" -type d -empty -delete` from deleting the root commands directory — add `-mindepth 1`.
- **Constraints:** Non-breaking; POSIX-friendly where applicable (`ai-rizz` is `#!/bin/sh`).

## IMPLEMENTATION

- **`ai-rizz`:** Added `LC_ALL=C; export LC_ALL` early in the script so `case` patterns using `[A-Z]` use byte ordering. In `sync_manifest_to_directory`, changed empty-directory cleanup to `find ... -mindepth 1 -type d -empty -delete`.
- **`completion.bash`:** Replaced three GNU `find -printf` pipelines with `find ... | sed 's|.*/||'` (and equivalent `sed -e` chains). Wrapped the uppercase filter `grep` in `LC_ALL=C`.
- **Tests:** Added coverage in `tests/integration/functions/test_command_sync.test.sh`, `test_ruleset_commands.test.sh`, and `test_sync_operations.test.sh` for lowercase `.md` commands not being skipped, uppercase files still ignored under UTF-8 locale, and commands root dir surviving sync after files removed.
- **Documentation:** `memory-bank/systemPatterns.md` updated with a **C Locale Enforcement** pattern for scripts using character-class ranges.

## TESTING

- TDD: tests added/extended before or alongside fixes per plan.
- Full suite: `make test` — 33/33 passing (1 unit + 32 integration) at completion.
- `/niko-qa` semantic review passed; one indentation regression in `completion.bash` caught and fixed during QA.

## LESSONS LEARNED

- POSIX shell `[A-Z]` ranges are **locale-dependent**; under UTF-8 collation they can match lowercase letters and silently drop intended files. **`LC_ALL=C` at script top** is the right default for tool scripts that rely on byte-value character classes.
- **`find -empty -delete`** on a tree root can remove the root if it becomes empty; **`-mindepth 1`** is required when the starting path must be preserved.
- GNU **`find -printf`** is not portable; **`sed` basename stripping** is sufficient for completion basenames.

### Reflection excerpt (inlined)

*From reflection-mac-compat-bugs:* If `LC_ALL=C` had been set from project inception, the locale `[A-Z]` bugs and downstream empty-dir behavior would have been avoided or reduced; Bug 1 (`find -printf`) would still have needed the same portable replacement. The chosen fix matches that “foundational” assumption.

*Process note:* Test helpers that `cd` to `$REPO_DIR` for git operations must return to the expected app directory for subsequent commands — caught during test authoring.

## PROCESS IMPROVEMENTS

None material. Plan matched execution; only minor QA indentation fix.

## TECHNICAL IMPROVEMENTS

None required beyond documenting C-locale convention in `systemPatterns.md`. Optional future hardening: audit other scripts for GNU-only `find` flags or locale-sensitive ranges.

## NEXT STEPS

None.
