# Project Brief: M3 — slobac-audit-fixes-2

## User Story

As an ai-rizz maintainer, I want **Milestone 3** of the SLOBAC remediation (**finding 16** in [`slobac-audit-2.md`](../../slobac-audit-2.md)) implemented, so that tests that exercise real filesystem, git, and symlink behavior no longer live under the `unit/` label, while fast pure-helper tests stay in `tests/unit/`, and project docs and runners match the new taxonomy.

## Source of Requirements

- [`slobac-audit-2.md`](../../slobac-audit-2.md) — **finding 16** (`wrong-level`).
- [`memory-bank/active/milestones.md`](milestones.md) — M3 scope and cross-milestone invariants.

## Scope (M3)

- Design a dedicated tier directory under integration for **direct-function** tests that perform real temp dirs, `git`, symlinks, and on-disk deployment assertions (per audit).
- Inventory `tests/unit/*.test.sh`: classify each file (or split where needed) into **stay in unit** vs **relocate**; relocate targets into the new directory.
- Update [`Makefile`](../../Makefile), [`tests/run_tests.sh`](../../tests/run_tests.sh), and [`tests/common.sh`](../../tests/common.sh) only where path assumptions or discovery require it; preserve `make test-unit` as the fast loop (unit-only) and `make test` / `make test-integration` as full coverage.
- Documentation: [`memory-bank/techContext.md`](../../memory-bank/techContext.md), [`memory-bank/systemPatterns.md`](../../memory-bank/systemPatterns.md), [`.cursor/rules/ai-rizz-development.mdc`](../../.cursor/rules/ai-rizz-development.mdc), [`README.md`](../../README.md) — reflect the new convention.

## Out of Scope

- Production changes to `ai-rizz` (L4 invariant).
- Findings 1–15 (handled in M1/M2).

## Definition of Done (M3)

- Finding **16** addressed per audit; intentional deviations documented in the M3 reflection.
- **`make test`** exits 0.
- Cross-milestone invariants in `milestones.md` respected (no new SLOBAC smells; no production code edits).
