# Project Brief: M2 — slobac-audit-fixes-2

## User Story

As an ai-rizz maintainer, I want **Milestone 2** of the SLOBAC remediation (**finding 15** in [`slobac-audit-2.md`](../../slobac-audit-2.md)) applied to the skill test suites, so that tests are grouped by durable product capability instead of plan-style “behavior N” numbering, without changing test logic.

## Source of Requirements

- [`slobac-audit-2.md`](../../slobac-audit-2.md) — **finding 15** (skill test deliverable-fossils / grouping).
- [`memory-bank/active/milestones.md`](milestones.md) — M2 scope and cross-milestone invariants.

## Scope (M2)

In these files only:

- `tests/unit/test_skill_detection.test.sh`
- `tests/unit/test_skill_sync.test.sh`
- `tests/unit/test_skill_list_display.test.sh`

Replace “behavior N” plan-numbered grouping with **capability-oriented** section groupings (for example: detection, deployment, list rendering, cleanup, symlink security — exact names to follow file content). Strip plan-behavior numbers from comments. **No changes to test logic or assertions** — structure and comments only.

## Out of Scope

- Findings **1–14** (done in M1) and **16** (M3: test tier reorganization).
- Any change to production script `ai-rizz` (cross-milestone invariant).

## Definition of Done (M2)

- Finding **15** addressed per audit intent; any intentional deviation documented in the M2 reflection.
- **`make test`** exits 0.
- Cross-milestone invariants in `milestones.md` respected (no new SLOBAC smells; test-only edits).
