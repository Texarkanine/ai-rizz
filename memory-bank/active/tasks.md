# Task: issue-30-ruleset-list-root-skill-dir-filtering

* Task ID: issue-30-ruleset-list-root-skill-dir-filtering
* Complexity: Level 2
* Type: bug fix + documentation update

Fix `cmd_list` ruleset tree rendering so unsupported root-level directories (including skill-like dirs with `SKILL.md` outside `skills/`) are not shown as ruleset contents, while preserving display of valid entries and documenting the contract in `docs/`.

## Test Plan (TDD)

### Behaviors to Verify

- **Unsupported root-level skill-like dirs are hidden:** `rulesets/<r>/<name>/SKILL.md` outside `skills/` → `<name>` is not shown in ruleset tree.
- **Valid embedded skills remain visible:** `rulesets/<r>/skills/<name>/SKILL.md` → list shows `skills` and `<name>`.
- **Supported nested-rule directories remain visible:** `rulesets/<r>/<subdir>/**.mdc` → `<subdir>` remains listed as deployable rules content.
- **Regression for non-rules dirs:** top-level dir with no `.mdc` and not magic `commands`/`skills` remains excluded.

### Test Infrastructure

- Framework: shunit2 with `tests/common.sh` helpers.
- Test location: `tests/integration/functions/`.
- Conventions: `test_<feature>.test.sh` files, `test_<behavior>()` functions, repository fixture setup + `cmd_init` + `cmd_list`.
- New test files: none.

## Implementation Plan

1. Add test stubs for new list filtering behaviors.
   - Files: `tests/integration/functions/test_ruleset_list_display.test.sh`
   - Changes: add empty test case(s) for root-level skill-like exclusion and magic `skills/` visibility.
2. Implement tests and verify they fail against current behavior.
   - Files: `tests/integration/functions/test_ruleset_list_display.test.sh`
   - Changes: fill assertions that unsupported root-level `SKILL.md` directory is absent while `skills/<skill>` is present.
3. Update ruleset item discovery/filtering in `cmd_list`.
   - Files: `ai-rizz`
   - Changes: replace broad top-level directory inclusion with supported-entry filtering (`commands`, `skills`, `.mdc`, directories containing `.mdc`).
4. Update docs to match supported list/display contract.
   - Files: `docs/rule-authoring/rulesets.md`
   - Changes: clarify that root-level skill directories are unsupported and only `skills/<skill>/SKILL.md` appears as embedded skills.
5. Validate with targeted suite and full suite.
   - Files: test suite commands only
   - Changes: run `./tests/integration/functions/test_ruleset_list_display.test.sh` then `make test`.

## Technology Validation

No new technology - validation not required.

## Dependencies

- Existing `cmd_list` implementation in `ai-rizz`.
- Existing function integration tests in `tests/integration/functions/`.
- Existing docs site source under `docs/rule-authoring/`.

## Challenges & Mitigations

- **Tree rendering stability:** changing inclusion filters can alter ordering or branch glyphs; preserve sorted temp-file flow and count-based tree rendering.
- **Over-filtering risk:** must not hide valid nested-rule directories; detect `.mdc` recursively for non-magic dirs.
- **POSIX compatibility:** avoid arrays and maintain prefixed variables with temp-file loops.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [x] Build
- [x] QA

## QA Results

- PASS: `cmd_list` ruleset tree filtering now shows only supported top-level entries and excludes unsupported root-level skill-like directories.
- PASS: Integration coverage in `test_ruleset_list_display.test.sh` validates hidden unsupported root-level `SKILL.md` dirs and visible magic `skills/` entries.
- PASS: `docs/rule-authoring/rulesets.md` now reflects supported list-display contract and unsupported root-level embedded-skill path behavior.
