---
task_id: fix-issues-40-41-repo-global-select
date: 2026-07-21
complexity_level: 2
---

# Reflection: fix-issues-40-41-repo-global-select

## Summary

Fixed #40 and #41 by making `select_mode()` ignore global inside git repos (require `--global`), with an actionable error when no local/commit mode exists. Tests and rule-modes docs updated; full suite green.

## Requirements vs Outcome

Delivered as specified. Did not chase a separate invalid-manifest writer once the auto-select-global path was closed; that path was the issue trigger.

## Plan Accuracy

Plan held: primary lever was `select_mode`, tests lived in `test_global_mode_detection.test.sh`, and the existing local+global test needed flipping. Only surprise was assertion shape around `exit` vs `|| echo ERROR_OCCURRED`.

## Build & QA Observations

TDD red→green was clean after assertion fixes. QA found nothing substantive.

## Insights

### Technical
- Helpers that `exit` never reach a sibling `|| echo` inside `$(...)`; assert on stderr text the way neighboring tests already do.

### Process
- Nothing notable

### Million-Dollar Question

Treat “global is never part of repo auto-select” as the original contract for `select_mode` — which is what we implemented. No broader redesign needed.
