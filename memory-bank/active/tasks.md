# Task: M2 — Regroup skill tests by capability (finding 15)

* Task ID: slobac-audit-fixes-2-m2
* Complexity: Level 2
* Type: Test-suite structure / documentation refactor (no logic changes)

Remap section banners and file-level comments in three skill-related unit suites from plan-style **“BEHAVIOR N”** labels to **capability-oriented** groupings (detection, deployment/sync, list rendering, deinit, symlink security, etc.). Strip obsolete plan behavior numbers from headers. **Do not** rename `test_*` functions, alter assertions, or change control flow — SLOBAC finding 15 / `milestones.md` M2.

## Test Plan (TDD)

M2 adds **no new behavior**. Verification is **regression-first**: establish a green baseline on the affected suite **before** editing that file’s comments, then re-run the same suite after edits. Final gate: full `make test`.

### Behaviors to Verify

- **Regression (detection):** `./tests/unit/test_skill_detection.test.sh` → exit 0 before and after comment-only edits to that file.
- **Regression (sync):** `./tests/unit/test_skill_sync.test.sh` → exit 0 before and after comment-only edits to that file.
- **Regression (list display):** `./tests/unit/test_skill_list_display.test.sh` → exit 0 before and after comment-only edits to that file.
- **Regression (full suite):** `make test` → exit 0 after all three files are updated.
- **Edge / safety:** No accidental edits inside `test_*()` bodies (only file header + `BEHAVIOR`/section banner comment blocks).

### Test Infrastructure

- Framework: shunit2 (bundled), helpers in `tests/common.sh`
- Test location: `tests/unit/`
- Conventions: `test_<description>()` functions; files `test_<feature>.test.sh`; single suite: `./tests/unit/<file>.test.sh`
- New test files: **none**

## Implementation Plan

1. **Detection suite — baseline + regroup comments**
   - Files: `tests/unit/test_skill_detection.test.sh`
   - **Before edits:** Run `./tests/unit/test_skill_detection.test.sh`; require exit 0.
   - **Changes:** Replace the header “Test Coverage (behaviors 1-7…)” block with a short capability summary (standalone `rules/`, embedded `rulesets/.../skills/`, invalid paths). Replace each `# BEHAVIOR N: …` banner triplet with capability labels, for example:
     - **Standalone skill paths (`rules/`)** — valid vs missing `SKILL.md`, nested rejection
     - **Embedded skill paths (`rulesets/.../skills/`)** — valid vs missing `SKILL.md`, nested rejection
     - **Non-skill / malformed paths** — catch-all negatives
   - **After edits:** Re-run `./tests/unit/test_skill_detection.test.sh`; require exit 0.

2. **Sync suite — baseline + regroup comments**
   - Files: `tests/unit/test_skill_sync.test.sh`
   - **Before edits:** Run `./tests/unit/test_skill_sync.test.sh`; require exit 0.
   - **Changes:** Remove plan-numbered “behaviors 8-15, 22-29…” header list. Replace `BEHAVIOR N` section banners with capability groups, for example:
     - **Standalone skill deployment** (paths under `.cursor/skills/<mode>/`, content preservation)
     - **Embedded skill deployment** (from ruleset `skills/`, mixed with rules/commands)
     - **Ruleset without skills / non-skill dirs** (no regression, not copied)
     - **Sync rebuild** (clear + redeploy standalone and embedded)
     - **Deinit cleanup** (local / shared / global skills dirs)
     - **Symlink security** (standalone + embedded variants, including `27b` / `28b` cases)
     - **Stale artifact cleanup** (files vs directories)
   - Preserve per-test inline comments; do not renumber or touch shell code.
   - **After edits:** Re-run `./tests/unit/test_skill_sync.test.sh`; require exit 0.

3. **List display suite — baseline + regroup comments**
   - Files: `tests/unit/test_skill_list_display.test.sh`
   - **Before edits:** Run `./tests/unit/test_skill_list_display.test.sh`; require exit 0.
   - **Changes:** Replace header numbered list (16, 17, …) with capability summary. Replace `BEHAVIOR N` banners with groups, for example:
     - **“Available skills:” section** (standalone entries, embedded-only exclusion)
     - **Install status glyphs**
     - **Deduplication** (rules + ruleset)
     - **Ruleset tree / `skills/` magic subdir** (expansion, SKILL.md filter)
     - **Section ordering** (skills before rulesets)
   - **After edits:** Re-run `./tests/unit/test_skill_list_display.test.sh`; require exit 0.

4. **Full suite gate**
   - Files: (none — command only)
   - **Changes:** Run `make test`; require exit 0.

## Technology Validation

No new technology — validation not required.

## Dependencies

- Git test identity / `git commit --no-gpg-sign` (already standard in `tests/common.sh` fixtures)
- **Do not** run `ai-rizz` from the project root as the test subject (existing project rule)

## Challenges & Mitigations

- **Accidentally editing test logic:** Only touch file header and `# ===…===` / `BEHAVIOR` banner lines; use `git diff` to confirm no changes inside `test_*()` functions.
- **shunit2 discovery:** Keep all `test_*` function names unchanged so the runner still collects the same cases.

## Preflight amendments

*(Populated after preflight — see `.preflight-status`.)*

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
