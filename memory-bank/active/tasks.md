# Task: fix-sync-rule-to-skill-moves

* Task ID: fix-sync-standalone-entry-relocates
* Complexity: Level 2
* Type: bug fix

When a standalone manifest entry’s exact path is missing after upstream pull, resolve the same name-slug to another valid standalone form under `rules/` (rule `.mdc` / command `.md` / skill dir), deploy that form, and rewrite the manifest so subsequent sync/remove/list use the new path. Ruleset entries are unchanged (already walk current layout).

## Test Plan (TDD)

### Behaviors to Verify

- [B1 rule→skill]: Manifest has `rules/foo.mdc`; repo only has `rules/foo/SKILL.md` → sync deploys skill under `.cursor/skills/<mode>/foo/`, rewrites manifest to `rules/foo`, no “Entry not found” for foo.
- [B2 command→skill]: Manifest has `rules/foo.md`; repo only has `rules/foo/SKILL.md` → same as B1 (deploy skill + rewrite to `rules/foo`).
- [B3 skill→rule]: Manifest has `rules/foo`; repo only has `rules/foo.mdc` → sync deploys rule to rules target, rewrites manifest to `rules/foo.mdc`.
- [B4 skill→command]: Manifest has `rules/foo`; repo only has `rules/foo.md` → sync deploys command to commands target, rewrites to `rules/foo.md`.
- [B5 rule↔command]: Manifest has `rules/foo.mdc`; repo only has `rules/foo.md` → sync deploys command, rewrites to `rules/foo.md` (and reverse if cheap in same suite).
- [B6 truly missing]: Manifest has `rules/gone.mdc`; no `gone` form exists → still warns “Entry not found”, entry remains in manifest, no inventing a deploy.
- [B7 exact path wins]: Manifest has `rules/foo.mdc` and that file still exists (even if skill also exists) → deploy the rule; no remap.
- [B8 priority on ambiguity]: Manifest has `rules/foo.mdc` missing; both `rules/foo/SKILL.md` and `rules/foo.md` exist → remap to skill (`rules/foo`), matching `cmd_add_rule` bare-name order.
- [B9 ruleset unchanged]: Ruleset-only install still deploys embedded skills from `rulesets/<r>/skills/` after members move there (regression; existing skill sync coverage may already cover — add only if gap).
- [E1 global/local/commit]: Remap works for at least one non-default mode path used in tests (prefer commit or global fixture pattern already in suite); no need to duplicate every direction per mode if helper is mode-agnostic.

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh` / `source_ai_rizz`
- Test location: `tests/unit/` for pure resolve helper; `tests/integration/functions/` for sync end-to-end
- Conventions: `test_<feature>.test.sh`, `test_<description>()`; temp repos via common helpers; `git commit --no-gpg-sign`
- New test files:
  - `tests/unit/test_resolve_standalone_entry.test.sh` (helper behaviors B7/B8 + slug extraction / miss)
  - `tests/integration/functions/test_sync_entry_relocates.test.sh` (B1–B6 end-to-end sync + manifest rewrite)

## Implementation Plan

1. **Stub tests + empty helper interface (TDD prep)**
   - Files: new unit + integration suites; `ai-rizz`
   - Changes: empty test stubs; add documented stub `resolve_standalone_entry()` (and any tiny slug helper if split) returning empty / no-op until step 3.

2. **Implement unit tests for `resolve_standalone_entry` — expect fail**
   - Files: `tests/unit/test_resolve_standalone_entry.test.sh`
   - Changes: given repo dir + manifest entry path, assert resolved path for each form (skill / mdc / md), exact-hit, miss, and priority skill > mdc > md.

3. **Implement `resolve_standalone_entry` to pass unit tests**
   - Files: `ai-rizz` (near `is_skill` / entity helpers)
   - Changes: extract slug from `rules/<slug>(.mdc|.md|)` only; if exact path exists return it; else probe skill dir → `.mdc` → `.md` under `RULES_PATH`; ignore `rulesets/*`; stdout canonical relative entry path or empty.

4. **Implement integration tests for sync remaps — expect fail**
   - Files: `tests/integration/functions/test_sync_entry_relocates.test.sh`
   - Changes: seed manifest with old path, mutate source repo to new form, `cmd_sync`, assert deploy target + rewritten manifest + warning absence/presence.

5. **Wire remap into `sync_manifest_to_directory` (+ optional copy path)**
   - Files: `ai-rizz` (`sync_manifest_to_directory`, possibly thin use inside loop before `copy_entry_to_target`)
   - Changes: for each standalone entry, if missing, call resolve; if remapped, replace manifest line (remove old / add new or rewrite file), then `copy_entry_to_target` with new path; emit a clear stderr notice of the relocate; keep “Entry not found” only when resolve fails.

6. **Docs touch if user-facing behavior is documented**
   - Files: `docs/developer-guide/manifest.md` and/or sync docs if they claim exact-path-only
   - Changes: note that sync rewrites standalone entries when the slug relocates across rule/command/skill forms.

7. **Full verification**
   - Run new suites then `make test`.

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing: `is_skill`, `copy_entry_to_target`, `read_manifest_entries`, `add_manifest_entry_to_file` / `remove_manifest_entry_from_file` (or equivalent rewrite helpers)
- Source-repo fixtures in integration tests (mutate after add, before sync)

## Challenges & Mitigations

- **Manifest rewrite during sync**: Must keep metadata line intact and only replace the relocated entry. Mitigation: reuse existing add/remove manifest helpers or a single rewrite pass after collecting remaps.
- **Ambiguous multiple forms**: Mitigation: same priority as `cmd_add_rule` (skill → mdc → md); unit-test B8.
- **`copy_entry_to_target` alone vs sync loop**: Remap + rewrite belongs in sync (manifest ownership), not buried only in copy (copy shouldn’t mutate manifests). Mitigation: resolve+rewrite in `sync_manifest_to_directory` before copy.
- **Stale global installs (operator machine)**: Fix is in ai-rizz; after fix, one `ai-rizz sync` should heal `~/ai-rizz.skbd`. No special migration script.

## Pre-Mortem

- **Plan assumed “rename” includes arbitrary path/slug renames (`foo`→`bar`)**: Out of scope; operator clarified identical name-slug only. Plan already limits to slug-preserving form changes — keep that boundary in tests/docs so we don’t overbuild.
- **Only rule→skill covered, reverse still broken**: Already covered by B3–B5; if build time-pressures cut tests, cut modes (E1) not directions.
- **Remap without manifest rewrite → sync “works” once but remove/list stay wrong**: Challenge already flags rewrite-in-sync; acceptance criteria require rewritten manifest.
- **Ruleset member moves treated as standalone remaps**: Wrong layer — ruleset walk already handles visual-planning; do not slug-remap `rulesets/*`.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
