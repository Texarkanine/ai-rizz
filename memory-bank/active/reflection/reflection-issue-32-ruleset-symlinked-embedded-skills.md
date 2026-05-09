---
task_id: issue-32-ruleset-symlinked-embedded-skills
date: 2026-05-09
complexity_level: 2
---

# Reflection: issue-32-ruleset-symlinked-embedded-skills

## Summary

Implemented support for symlinked embedded skills under ruleset `skills/` for both list and deploy paths, while preserving out-of-repo symlink rejection. The change met all requested requirements and passed targeted, full, and docs verification.

## Requirements vs Outcome

All requested requirements were delivered: in-repo symlinked embedded skills now list and install/sync correctly; out-of-repo symlinked entries are skipped; regression coverage was added; and docs were updated to match behavior. No requirements were dropped or added beyond scope.

## Plan Accuracy

The plan sequence was accurate and did not require reordering. The identified risk (discovery filters using `-type d`) was the exact root cause encountered in both list and copy paths.

## Build & QA Observations

TDD flow was clean: newly added tests failed first, then passed after focused runtime changes. QA found no semantic issues requiring rework; existing helper reuse kept the implementation compact and consistent.

## Insights

### Technical
- Discovery-expansion changes should always be paired with explicit boundary validation on each newly included entry type.

### Process
- Writing paired list + sync tests before runtime edits produced a fast, reliable red/green loop with minimal iteration.

### Million-Dollar Question

If this behavior had been foundational, embedded skill discovery for both list and deploy would have been implemented through a single shared helper that enumerates valid `skills/` children (real dirs + safe symlink dirs) once, then feeds both consumers to prevent drift.
