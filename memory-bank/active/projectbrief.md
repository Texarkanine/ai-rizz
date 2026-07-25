# Project Brief

## User Story

As an ai-rizz consumer of a shared rules repository, I want `ai-rizz sync` to correctly handle upstream rule→skill moves so that my local `.cursor/` install stays consistent with the source repo without stale paths, missing-entry warnings, or half-applied migrations.

## Use-Case(s)

### Use-Case 1

A rules repo converts description rules (and some commands) into Cursor skills (e.g. `rules/foo.mdc` → `rules/foo/SKILL.md`, ruleset members under `rulesets/*/skills/`). After pull + `ai-rizz sync`, the consumer project’s manifests and installed files match the new skill layout.

### Use-Case 2

Entries that truly disappeared from the source repo (not relocated) still produce clear warnings; sync does not invent mappings for unrelated removals.

## Requirements

1. Diagnose why sync fails or partially applies when upstream moves rules into skills (as in Texarkanine/.cursor-rules#87).
2. Fix ai-rizz so sync updates consumers correctly for those relocates.
3. Cover the fix with tests (TDD) so the regression cannot return unnoticed.

## Constraints

1. Follow project TDD and shell/testing practices; never run `ai-rizz` against this project directory for ad-hoc testing.
2. Prefer a clean-break fix aligned with existing skill-support design; do not paper over sync with one-off consumer workarounds.

## Acceptance Criteria

1. Reproducing the .cursor-rules skillify scenario (or an equivalent fixture) via tests shows sync succeeds without spurious “Entry not found” for relocated entries.
2. After sync, installed paths and manifests reflect skills (old rule files removed / new skill dirs present as appropriate).
3. Unrelated missing entries still warn as before.
4. Full test suite passes (`make test`).
