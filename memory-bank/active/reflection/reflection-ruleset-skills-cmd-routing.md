---
task_id: ruleset-skills-cmd-routing
date: 2026-04-23
complexity_level: 2
---

# Reflection: Ruleset skill markdown must not become slash-commands

## Summary

Fixed ai-rizz ruleset sync so `*.md` under `rulesets/<r>/skills/` is no longer copied flat to `.cursor/commands/`; those files only ship with the embedded skill tree. Added a regression test and documented routing in `systemPatterns.md`. Full suite passed.

## Requirements vs Outcome

Delivered the requested behavior: reference/workflow markdown bundled with skills (e.g. Niko `references/`) stays under `.cursor/skills/...` and does not pollute `.cursor/commands/`. Root and other non-`skills/` `.md` in rulesets still behave as commands. No requirements dropped.

## Plan Accuracy

Work was discovered incrementally: the bug was “obvious” once `copy_entry_to_target` was read—flat `find` on all `*.md` ran before the skill `cp -rL`. No large plan document existed in memory bank during the fix (session ran lean). Surprises were minimal; the main gap was **process** (memory bank not updated during the fix pass).

## Build & QA Observations

Implementation was a small, localized guard plus one unit test. QA was the existing shunit2 suite; it stayed green. No rework loop.

## Insights

### Technical

- **Ordering and ownership:** When one deployment path uses a broad glob (`find … *.md`) and another path owns a subtree (`skills/`), the broad pass must explicitly exclude the subtree or you get duplicate semantics (same file, two roles). Documenting “magic dirs” in `systemPatterns` helps the next reader see why the skip exists.

### Process

- **Memory bank during build:** If `/niko` or explicit task tracking is expected, update `memory-bank/active/*` as work proceeds—not only at reflect. Archiving/clearing `active/` without an immediate follow-up left no audit trail for the fix until this reflection. Next time: keep `projectbrief`/`progress` current or accept that reflect will require deliberate backfill.

### Million-Dollar Question

If ruleset routing had been designed with **explicit command sources** from the start (e.g. only ruleset root + `commands/**` as slash-commands, never “all `*.md` minus exceptions”), the bug would not have appeared. The current fix is the minimal correction: exclude the `skills/` subtree from the legacy “all markdown flattens” rule. A larger redesign could narrow command discovery, but it would be a behavior contract change for edge layouts; the exclusion is the right tradeoff for compatibility.
