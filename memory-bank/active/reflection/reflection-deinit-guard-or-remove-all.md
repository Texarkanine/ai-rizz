---
task_id: deinit-guard-or-remove-all
date: 2026-07-21
complexity_level: 2
---

# Reflection: deinit-guard-or-remove-all

## Summary

Delivered issue #42: `deinit --both` removes local+commit only; `--all`/`-a` is rejected with an actionable hint. Docs, help, completion, and tests updated; full suite green.

## Requirements vs Outcome

All brief requirements met. No scope additions beyond the planned short `-b` and actionable `all` rejection copy from preflight.

## Plan Accuracy

Plan held: existing deinit suites were the right home; global-preservation needed the HOME-isolated `init_global_paths` pattern already used elsewhere. Integrity Option 3 was correctly identified as a project-mode reset, not a full wipe.

## Build & QA Observations

Red→green was straightforward once `--both` landed. QA found no substantive issues.

## Insights

### Technical
- Integrity-error “reset everything” copy had been recommending a machine-wide wipe for a local/commit metadata mismatch — flag renames are a good moment to audit suggested fix commands, not only the flag parser.

### Process
- Nothing notable

### Million-Dollar Question

If `--both` (project modes) vs `--global` had always been the aggregation model, there would never have been an “all modes” flag that crossed the project/user boundary. The fix is that model, not a softer guard around `--all`.
