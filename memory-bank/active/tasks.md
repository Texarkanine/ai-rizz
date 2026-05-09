# Task: issue-32-ruleset-symlinked-embedded-skills

* Task ID: issue-32-ruleset-symlinked-embedded-skills
* Complexity: Level 2
* Type: bug fix + documentation enhancement

Fix ruleset embedded-skill discovery so symlinked skill directories under `rulesets/<ruleset>/skills/` are treated as valid embedded skills for list and install/sync when they resolve inside the repository, while preserving existing out-of-repo symlink rejection behavior and updating docs accordingly.

## Test Plan (TDD)

### Behaviors to Verify

- **List supports in-repo symlinked embedded skills:** `cmd_list` with `rulesets/<r>/skills/<name> -> in-repo-dir` -> ruleset tree shows `<name>`.
- **List rejects out-of-repo symlinked embedded skills:** `cmd_list` with `rulesets/<r>/skills/<name> -> outside-repo-dir` -> ruleset tree omits `<name>`.
- **Sync/install supports in-repo symlinked embedded skills:** add ruleset with `skills/<name>` symlink to in-repo skill dir -> `.cursor/skills/<mode>/<name>/SKILL.md` exists.
- **Sync/install rejects out-of-repo symlinked embedded skills:** add ruleset with `skills/<name>` symlink outside repo -> `.cursor/skills/<mode>/<name>` does not exist.
- **Regression:** regular embedded real directories remain listed/deployed; non-skill dirs without `SKILL.md` remain excluded.

### Test Infrastructure

- Framework: shunit2 shell tests with `tests/common.sh` helpers.
- Test location: `tests/integration/functions/`.
- Conventions: file names `test_<feature>.test.sh`; case names `test_<behavior>()`; use `cmd_init`, `cmd_add_ruleset`, `cmd_list`, and filesystem assertions.
- New test files: none.

## Implementation Plan

1. Add failing test stubs, then implement tests for embedded-skill symlink behavior in sync/deploy path.
   - Files: `tests/integration/functions/test_skill_sync.test.sh`
   - Changes: add test cases for in-repo and out-of-repo symlinked directories directly under a ruleset `skills/` subdir.
2. Add failing test stubs, then implement tests for list output behavior for symlinked embedded skills.
   - Files: `tests/integration/functions/test_skill_list_display.test.sh`
   - Changes: add list-tree assertions for in-repo symlink visibility and out-of-repo symlink exclusion.
3. Update embedded skill discovery logic in runtime.
   - Files: `ai-rizz`
   - Changes: change `skills/` child discovery to include symlinks; enforce top-level symlink target checks for embedded skill entries in both list and copy paths; keep existing `validate_dir_symlinks` enforcement for nested symlinks.
4. Update docs site to remove obsolete broken warning and document supported symlink behavior plus security limits.
   - Files: `docs/rule-authoring/rulesets.md`
   - Changes: revise Skills section language/examples and security notes to match implemented behavior.
5. Validate with targeted test suites, then full suite and docs build.
   - Files: `tests/integration/functions/test_skill_sync.test.sh`, `tests/integration/functions/test_skill_list_display.test.sh`, full repo tests/docs commands
   - Changes: run TDD cycle and final verification (`make test`, `make docs-build`).

## Technology Validation

No new technology - validation not required.

## Dependencies

- Existing shell runtime and helper functions in `ai-rizz` (notably `_readlink_f`, `validate_dir_symlinks`, `is_skill`).
- Existing shunit2 integration function test framework.
- Existing docs toolchain (`properdocs`, `mkdocs-material`) already configured.

## Challenges & Mitigations

- Discovery now includes symlinks, which can surface non-directory symlink entries: gate on `-d` and `SKILL.md` checks before processing.
- Security drift risk when adding list-path support: apply the same top-level in-repo symlink resolution guard to list tree expansion.
- Path quoting and shell portability risk: reuse existing variable-prefix conventions and quoting patterns from nearby code.

## Implementation Progress

- [x] Step 1: Added and implemented sync/deploy tests for in-repo and out-of-repo symlinked embedded skills.
- [x] Step 2: Added and implemented list display tests for in-repo and out-of-repo symlinked embedded skills.
- [x] Step 3: Updated runtime embedded-skill discovery and symlink safety checks in `ai-rizz`.
- [x] Step 4: Updated ruleset documentation for symlinked skills support and constraints.
- [x] Step 5: Ran targeted tests, full suite, and docs strict build.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Preflight
- [x] Build
- [x] QA
