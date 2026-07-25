# Project Brief

## User Story

As an ai-rizz consumer of a shared rules repository, I want `ai-rizz sync` to correctly handle upstream **slug-preserving relocates** across entity forms (rule ↔ command ↔ skill) so that my manifests and installed `.cursor/` trees stay consistent without stale paths, missing-entry warnings, or half-applied migrations.

## Use-Case(s)

### Use-Case 1 — Rule/command → skill (observed)

A rules repo converts description rules/commands into Cursor skills (e.g. `rules/foo.mdc` or `rules/foo.md` → `rules/foo/SKILL.md`). After pull + `ai-rizz sync`, standalone manifest entries that still list the old path remapped and deploy as skills; warnings for those entries stop.

### Use-Case 2 — Reverse / other form changes

Same slug moves the other way (skill → rule, skill → command, rule ↔ command). Sync remaps and deploys the current form.

### Use-Case 3 — Truly gone

An entry whose slug no longer exists in any standalone form under `rules/` still warns “Entry not found” and is not silently dropped from the manifest.

## Requirements

1. Diagnose why sync fails or partially applies when upstream relocates entries by identical name-slug across entity types (as in Texarkanine/.cursor-rules#87).
2. Fix ai-rizz so sync resolves missing exact paths via slug-preserving alternate forms, deploys the current form, and rewrites the manifest entry to the new canonical path.
3. Cover with TDD tests for multiple relocate directions and the truly-missing case.
4. Ruleset-internal layout changes (e.g. member moved into `skills/`) remain ruleset-walk behavior — do not invent a parallel rename system for ruleset members.

## Constraints

1. Follow project TDD and shell/testing practices; never run `ai-rizz` against this project directory for ad-hoc testing.
2. Prefer clean-break alignment with existing `cmd_add_rule` bare-name resolution (skill → `.mdc` → `.md`).
3. Do not remap `rulesets/*` entries by slug; only standalone `rules/*` entries.

## Acceptance Criteria

1. Sync of a manifest entry whose exact path is gone but whose slug exists as another standalone form succeeds without “Entry not found,” deploys to the correct target dir, and updates the manifest path.
2. Reverse and cross-form relocates (skill↔rule, skill↔command, rule↔command) behave the same.
3. Truly missing slugs still warn; unrelated entries unaffected.
4. Full test suite passes (`make test`).
