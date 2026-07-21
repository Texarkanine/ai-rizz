# Task: fix-issues-40-41-repo-global-select

* Task ID: fix-issues-40-41-repo-global-select
* Complexity: Level 2
* Type: bug fix + simple enhancement

In git repositories, `select_mode()` must ignore global when auto-selecting (global requires explicit `--global` / `AI_RIZZ_MODE=global`). That restores single local/commit convenience (#41) and makes unflagged `add` in a global-only repo error instead of writing an invalid project manifest (#40). Outside git, global-only auto-select remains.

## Test Plan (TDD)

### Behaviors to Verify

- [#41 local+global]: local init'd, global active, `select_mode ""` in git repo → `local`
- [#41 commit+global]: commit init'd, global active, `select_mode ""` in git repo → `commit`
- [#41 explicit global]: local+global active, `select_mode "global"` → `global`
- [#40 global-only in repo]: only global active, git repo present, `select_mode ""` → error (require explicit mode); no `./ai-rizz.skbd` / `./ai-rizz.local.skbd` created by subsequent `cmd_add_rule` without flag
- [#40 CLI add]: only global, in git repo, `cmd_add_rule <rule>` unflagged → non-zero; project manifests absent/unchanged; global manifest unchanged except no spurious project files
- [preserve] only global outside git: `select_mode ""` → `global`
- [preserve] local+commit (no flag): still mode-selection error
- [preserve] all three modes (no flag): still mode-selection error
- [preserve] `AI_RIZZ_MODE=global` with multi-mode repo: still selects global
- [edge] only global in git repo + explicit `--global` add → succeeds against global manifest

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh` / `source_ai_rizz`
- Test location: `tests/integration/functions/`
- Conventions: `test_<behavior>.test.sh`; `setup_global_test_environment` + `APP_DIR` (git) / non-git dirs; HOME isolation via `TEST_HOME`
- New test files: none preferred — extend `tests/integration/functions/test_global_mode_detection.test.sh`; add #40 add-path coverage in same file or `test_global_only_context.test.sh` if CLI-ish flow fits better (prefer function-level `cmd_add_rule` in detection suite with git APP_DIR)

### Existing tests to update

- `test_select_mode_two_modes_local_global` — currently expects error; must expect auto-select `local`

## Implementation Plan

1. **Update/extend select_mode tests (failing first)**
   - Files: `tests/integration/functions/test_global_mode_detection.test.sh`
   - Changes: rewrite `test_select_mode_two_modes_local_global` expectation; add `test_select_mode_commit_and_global_auto_selects_commit`; add `test_select_mode_only_global_in_git_repo_requires_flag`; add `test_add_rule_only_global_in_git_repo_errors_without_project_manifest` (and optional `--global` success counterpart)

2. **Implement repo-aware auto-select in `select_mode()`**
   - Files: `ai-rizz` (`select_mode`)
   - Changes: when `.git` exists, count only local+commit for auto-select; if count==1 return that mode; if count==2 keep `show_mode_selection_error`; if count==0 error requiring explicit `--local`/`--commit`/`--global` (actionable message — not “multiple modes” when none). When `.git` absent, keep current global-only auto-select. Explicit arg and `AI_RIZZ_MODE` unchanged.

3. **Doc touch for mode auto-select policy**
   - Files: `docs/user-guide/rule-modes.md`
   - Changes: short note that in a repo, unflagged commands auto-select the single local/commit mode; global always needs `--global`

4. **Verify**
   - Run updated suite verbose, then `make test`

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing `is_mode_active`, `show_mode_selection_error`, global test HOME isolation
- Possibly a small new error helper if “no project mode” messaging should differ from multi-mode messaging

## Challenges & Mitigations

- **Misleading error copy**: calling `show_mode_selection_error` when zero repo modes says “Multiple modes available”. Mitigation: add a focused error (or branch message) for “no local/commit init; pass --global or init”.
- **Regressing non-git global-only**: keep explicit outside-git path covered by existing `test_select_mode_only_global_active`.
- **Callers beyond add**: `select_mode` is shared — policy change is intentional; full suite catches remove/list/etc.

## Pre-Mortem

- **Wrong git detection** (e.g. only checking cwd `.git` while commands run from subdirs): already how `is_mode_active` gates local/commit; stay consistent with that invariant rather than inventing `git rev-parse`.
- **Fix only add, leave select_mode**: would leave remove/other commands inconsistent — plan keeps change in `select_mode` (Challenge already covers shared callers).
- **Ship without updating `test_select_mode_two_modes_local_global`**: suite would fail or mask intent — called out in Test Plan.

## Preflight Findings

- PASS — TDD ordering explicit (tests step before `select_mode` impl); conventions match `tests/integration/functions/`; `select_mode` callers are `cmd_add_rule` / `cmd_add_ruleset` only (narrower than assumed — full suite still required).
- Advisory (non-blocking): optional `cmd_add_ruleset` mirror of the #40/#41 cases; skipped to keep scope on `select_mode` + one add-rule smoke.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [ ] Build
- [ ] QA
