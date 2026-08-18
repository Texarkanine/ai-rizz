---
task_id: list-installed-default
date: 2026-08-18
complexity_level: 2
---

# Reflection: list-installed-default

## Summary

`ai-rizz list` now defaults to installed inventory, with `-a`/`--all` restoring the catalog and a single `N available, not shown` footer when anything is hidden. Delivered; two extra plan/preflight cycles on completion TDD, one QA FAIL on docs/assertions, then PASS.

## Requirements vs Outcome

All seven brief requirements shipped. Nothing descoped. The preflight footer-hint advisory (`… (ai-rizz list --all)`) was not applied — Requirement 4 pins the exact string. Completion stayed a cheap `_init_completion` stub, not a `COMP_WORDS` harness.

## Plan Accuracy

The seven-step sequence and retarget enumeration were right; `--all` as a strict superset let catalog tests stay green while the new inventory tests were the red bar. What the first plans got wrong was Step 5: treating flag completion as inspect-by-looking. Preflight refused twice; the operator then accepted the cheap stub. The surprise at QA was not the filter — it was retargeting a mixed installed/uninstalled skill test entirely to `--all`, which dropped the default-inventory half the plan still required.

## Build & QA Observations

Build of `cmd_list` was straightforward (`cl_note_item` + `cl_hidden_count`). The completion stub needed env vars, not stub `$1`/`$2`, because `_ai_rizz_completion` calls `_init_completion` with no args. QA (gpt) correctly failed on a 6-vs-5 docs example, missing empty-catalog and nonzero-unknown-arg asserts, and the dropped skill-inventory half. Rework was small; second QA (gemini) passed.

## Insights

### Technical
- A mixed installed/uninstalled list test cannot be wholesale-retargeted to `--all`; keep a default `cmd_list` call for the installed half.
- `_init_completion` takes no arguments. Stub `cur`/`prev` through the environment, and do not `local` those names in the stub (bash dynamic scope).
- `VERBOSE_TESTS` prefixes `DEBUG: Running: …` onto CLI output, so full-string equality of `list -a` vs `list --all` is not a valid CLI assertion.

### Process
- Inspection is not a TDD carve-out for executable completion. The cheap stub was enough; inventing a tty/`COMP_WORDS` harness was not. We have been burned on missed completion bodies before — name-listing tests stay, and flag offers deserve the same class of test.
- Preflight's tests-or-remove fork was correct to hold. Plan-upstream friction is real; auto-amending the plan under the operator would have been worse.

### Million-Dollar Question

Inventory as the default and catalog behind `--all` is the shape `cmd_list` should have had from the start: one printer, a show-uninstalled flag, headers on first printed row. The retarget tax is the cost of having treated catalog as the only view. No second command, no header rename — that remains the elegant form.
