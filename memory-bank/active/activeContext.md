# Active Context

## Current Task: fix-sync-standalone-entry-relocates
**Phase:** PLAN - COMPLETE

## What Was Done
- Diagnosed root cause: global/local/commit manifests store exact paths (`rules/foo.mdc`, `rules/foo.md`); after upstream slug-preserving form change, `copy_entry_to_target` looks up only that path → “Entry not found”. Ruleset walks already pick up embedded skill moves (visual-planning).
- Operator clarification: all identical name-slug relocates across rule/command/skill (including reverse), not only rule→skill.
- Level 2 plan written: resolve helper + sync-time remap/manifest rewrite; TDD suites mapped.

## Next Step
- Preflight validation, then build.
