---
task_id: mac-compat-bugs
date: 2025-05-12
complexity_level: 2
---

# Reflection: macOS/BSD Cross-Platform Bug Fixes

## Summary

Fixed three cross-platform bugs that broke ai-rizz on macOS/BSD: GNU-only `find -printf` in tab completion, locale-sensitive `[A-Z]` character ranges silently skipping `.md` commands, and `find -empty -delete` removing target root directories. All fixes are non-breaking and all 33 tests pass.

## Requirements vs Outcome

All three bugs from the report are fixed exactly as specified. No requirements were dropped or reinterpreted. No scope was added beyond what the bug report described.

## Plan Accuracy

The plan was accurate. The 7-step sequence executed without reordering or splitting. The identified challenges (LC_ALL=C impact on output, completion.bash needing inline locale fix, CI locale not reproducing the bug) were correct — none materialized as blockers. One minor surprise: test helpers `cd` to `$REPO_DIR` for git commits and tests that don't return to `$TEST_DIR/app` cause subsequent commands to fail with "not in a git repository." This was caught and fixed during test writing.

## Build & QA Observations

Build was clean and fast. The only iteration was fixing the `cd` target in two test functions (returning to `$TEST_DIR/app` instead of `$TEST_DIR`). QA caught one trivial indentation regression in `completion.bash` where a tab level was lost during the `find -printf` replacement — fixed inline.

## Insights

### Technical
- POSIX shell `[A-Z]` character ranges are locale-dependent and silently produce wrong results under UTF-8. `LC_ALL=C` at script top is the correct defensive measure for any POSIX script that uses character class ranges. This should be a standing convention for the project.

### Process
- Nothing notable.

### Million-Dollar Question

If `LC_ALL=C` had been set from the project's inception, Bugs 2 and 3 would never have existed — the `[A-Z]` filter would have always worked correctly on all platforms, and the commands directory would have been populated, making the `find -empty -delete` harmless. Bug 1 (`find -printf`) is independent of locale and would have required the same fix regardless. The current solution (adding `LC_ALL=C` at the top) is the same fix that would have been the foundational assumption — so the implementation is already the most elegant form.
