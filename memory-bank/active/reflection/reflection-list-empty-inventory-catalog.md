---
task_id: list-empty-inventory-catalog
date: 2026-08-26
complexity_level: 2
---

# Reflection: list shows full catalog when inventory is empty

## Summary

Shipped auto-catalog on empty inventory: fresh `list` after init matches `--all`. QA PASS with advisories only. Delivered on PR #53 after retroactive Niko backfill.

## Requirements vs Outcome

All requirements met. Empty manifests → full catalog, no footer. Non-empty inventory → inventory + footer unchanged. Empty source repo still silent. Docs and systemPatterns aligned.

## Plan Accuracy

Retroactive plan matched shipped work. Manifest scan was the right empty signal (not footer heuristic). No surprise regressions in function suite.

## Build & QA Observations

Build was clean before backfill; CI green. QA confirmed completeness; advisories on repeated scan blocks and optional doc example tab are fair but non-blocking.

## Insights

### Technical

- Reusing `cl_show_all` for the empty-inventory case avoided a second listing path — the flag was already the catalog switch.

### Process

- Invoking a delivery skill (`github-open-a-pull-request-gh`) immediately after intent confirmation collapsed the Niko pipeline; PR became the finish line without Step 7 ephemeral files or QA. Retroactive backfill works but costs more than following the state machine.

### Million-Dollar Question

The list printer always had one catalog mode (`cl_show_all`); the product mistake was defaulting it off when inventory was empty — the elegant fix is exactly what we built: auto-enable catalog when manifests are empty, inventory view once anything is installed.
