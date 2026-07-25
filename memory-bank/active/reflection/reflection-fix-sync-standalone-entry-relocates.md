---
task_id: fix-sync-standalone-entry-relocates
date: 2026-07-25
complexity_level: 2
---

# Reflection: fix-sync-standalone-entry-relocates

## Summary

Sync now remaps slug-preserving standalone relocates across rule/command/skill forms (manifest rewrite + deploy). Full suite green; QA clean.

## Requirements vs Outcome

Delivered as scoped: diagnose exact-path sync failure, fix via shared resolver + sync-time rewrite, cover forward/reverse form changes and truly-missing. Ruleset-internal moves left to existing ruleset walk. No descopes; no extra features.

## Plan Accuracy

Plan sequence held (unit helper → add reuse → integration → sync wire → docs). Real surprise was operator-environment detail (global `~/ai-rizz.skbd` entries), not design. Preflight’s shared-resolver amendment paid off immediately.

## Build & QA Observations

TDD red→green was straightforward. One test flake from `grep && fail` under `set -e` when the absence case is success. QA found nothing substantive.

## Insights

### Technical
- Manifests store exact paths; entity-form moves are invisible unless sync rewrites. Ruleset entries already tolerate layout churn because they walk the live tree — standalone entries need an explicit remap step.
- `grep && fail` under `set -e` fails the test function when grep misses; prefer `if grep; then fail; fi`.

### Process
- Nothing notable

### Million-Dollar Question

If relocates had been a foundational assumption, manifests would store *slugs* (or typed ids) and resolve to the current form on every sync/add/list — paths would be a deploy detail, not identity. What we built (path identity + sync-time remap) is the smallest correct patch on the existing contract; the elegant long-term shape is slug-primary identity.
