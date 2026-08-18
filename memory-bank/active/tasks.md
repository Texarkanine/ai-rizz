# Task: list-installed-default

* Task ID: list-installed-default
* Complexity: Level 2
* Type: simple enhancement

`ai-rizz list` defaults to installed inventory. `-a`/`--all` restores today's catalog. Default view omits empty-of-installed section headers and ends with one footer `N available, not shown` when any top-level catalog item was hidden.

**Rework (after preflight FAIL):** keep the `completion.bash` `list)` flag offers. Do not add dispatcher tests. Do not call that step prose/policy. Operator TDD carve-out: static flag word lists are verified by inspection. Existing name-listing tests stay; they exist because missed rule bodies are not inspectable the same way.

## Test Plan (TDD)

### Behaviors to Verify

- Default inventory: `cmd_list` with a mixed catalog (some installed, some not) → only installed rows (correct mode glyphs); no `○` rows
- Omit empty-of-installed section: catalog has commands but none installed → no `Available commands:` header (same for rules, skills, rulesets)
- Keep section when it has installed members: at least one installed command → `Available commands:` header and that row
- Cumulative footer: default view with hidden items → exactly one line `N available, not shown` after all sections, where `N` equals the number of `○` glyph rows in `cmd_list --all` (top-level rows only; ruleset tree children have no glyph and do not count)
- No footer when nothing hidden: every catalog item installed → no `available, not shown` line
- Nothing installed, nonempty catalog: no section headers; output is the footer only
- `--all` catalog: `cmd_list --all` → today's full listing including `○` rows and uninstalled ruleset trees; no footer
- `-a` alias: `cmd_list -a` → same catalog behavior as `--all`
- Unknown argument: `cmd_list --installed` (or any unknown token) → error, nonzero
- Installed ruleset still expands: default `cmd_list` after adding a ruleset → ruleset row plus existing tree; sibling uninstalled rulesets omitted and counted in `N`
- Uninstalled ruleset omitted: default `cmd_list` without adding that ruleset → no tree for it
- CLI parity: `ai-rizz list` inventory; `ai-rizz list --all` and `ai-rizz list -a` catalog

### Edge Cases

- Invalid input: unknown flag/positional on `list` → actionable error (copy-paste not required; name the bad token)
- Empty catalog (no rules/commands/skills/rulesets in source): default list prints nothing (no footer)
- Boundary: `N=1` uses the same format (`1 available, not shown`), no special plural
- `--all` when everything is installed: catalog listing, still no footer
- Interaction: existing glyph tests that asserted `○` on bare `cmd_list` must assert that on `--all` instead; default `cmd_list` must still show `●`/`◐`/`★` for installed items
- Footer must not appear twice or per-section

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh`
- Test location: `tests/integration/functions/` (direct `cmd_*`) and `tests/integration/` (public CLI)
- Conventions: `test_<behavior>()` in `test_<feature>.test.sh`; temp git repos; `git commit --no-gpg-sign`; never run against this project directory
- New test files: none — extend existing suites
- Completion: `tests/unit/test_bash_completion.test.sh` already tests `_ai_rizz_list_rule_names` and `_get_repo_dir` by sourcing `completion.bash` and calling those helpers. It does not drive `_ai_rizz_completion` (that function calls `_init_completion` from bash-completion). No new completion tests in this task.

### Test File Mapping

- `tests/integration/functions/test_list_display.test.sh` — new cases for default filter, omitted headers, footer oracle (`N` = `○` count from `--all`), `-a`/`--all`, unknown arg, empty-hidden no footer. Retarget `test_list_shows_uninstalled_glyph_for_new_command` and any other `○`/uninstalled-section assertions to `--all`.
- `tests/integration/functions/test_rule_management.test.sh` — glyph tests that currently require `○` on bare `cmd_list` (`test_list_local_mode_only_glyphs`, `test_list_commit_mode_only_glyphs`, `test_list_dual_mode_all_glyphs`) call `cmd_list --all` for the catalog half; add or keep default-`cmd_list` assertions that installed glyphs still appear without `○`.
- `tests/integration/functions/test_skill_list_display.test.sh` — catalog discovery cases (`test_standalone_skill_appears_in_skills_section`, uninstalled-glyph half of `test_standalone_skill_installed_glyph`, section-order when the skill/ruleset is not installed) use `--all`. Installed-glyph and installed-ruleset tree cases can stay on default `cmd_list` (footer extra lines are fine for `grep`).
- `tests/integration/functions/test_ruleset_list_display.test.sh` — tree-shape tests that list a ruleset without adding it must use `--all`; tests that `cmd_add_ruleset` first can stay on default.
- `tests/integration/functions/test_global_only_context.test.sh` — if `test_global_list_shows_available_commands_outside_git_repo` lists an uninstalled command, switch that call to `--all`.
- `tests/integration/test_cli_list_sync.test.sh` — `○` assertions move to `run_ai_rizz list --all`; add CLI cases for default inventory, footer, `-a`, and unknown flag.
- `tests/integration/functions/test_ruleset_management.test.sh` / `test_ruleset_removal_and_structure.test.sh` / `test_custom_path_operations.test.sh` — retarget only if they assert uninstalled rows or section headers for items not in a manifest.
- `tests/unit/test_bash_completion.test.sh` — no new cases. Name-listing coverage is already there. Flag offers on `list` are an operator TDD carve-out (inspection), not a change-detector and not a new `_init_completion` harness.

## Implementation Plan

1. Write failing inventory/footer/flag tests (and retarget catalog assertions to `--all`)
   - Files: `tests/integration/functions/test_list_display.test.sh`, `tests/integration/functions/test_rule_management.test.sh`, `tests/integration/functions/test_skill_list_display.test.sh`, `tests/integration/functions/test_ruleset_list_display.test.sh`, `tests/integration/functions/test_global_only_context.test.sh`, `tests/integration/functions/test_ruleset_management.test.sh`, `tests/integration/functions/test_ruleset_removal_and_structure.test.sh`, `tests/integration/functions/test_custom_path_operations.test.sh`, `tests/integration/test_cli_list_sync.test.sh`
   - Tests first: the new cases in `test_list_display.test.sh` and `test_cli_list_sync.test.sh` listed above; watch them fail on current `cmd_list` (args ignored, `○` still printed, no footer)
   - Changes: test code only. Footer oracle: `N` from counting `○` rows in `--all` output, not a hardcoded catalog size.

2. Parse `-a`/`--all` and unknown args in `cmd_list`
   - Files: `ai-rizz` (`cmd_list`)
   - Tests first: unknown-arg and `--all`/`-a` cases from step 1 must already exist and be failing
   - Changes: at start of `cmd_list` after `ensure_initialized_and_valid` / manifest validation, POSIX `while`/`case` like `cmd_deinit`: set `cl_show_all=true` for `-a`/`--all`; `error "Unknown argument: $1"` otherwise. Document flags in the `cmd_list` header (`-a`, `--all`; return 0/1). Prefix stays `cl_`.

3. Filter default output and print the cumulative footer
   - Files: `ai-rizz` (`cmd_list` rules/commands/skills/rulesets loops)
   - Tests first: inventory, omitted-header, footer, empty-catalog, installed-ruleset-tree cases from step 1
   - Changes: keep section titles (`Available rules:` etc.). For each top-level item: if installed, print header on first row then the glyph row (and ruleset tree); if uninstalled and `cl_show_all`, same as today; if uninstalled and not `cl_show_all`, increment `cl_hidden_count` and skip (no tree). Print section trailing blank line only when the section printed. After all sections, if not `cl_show_all` and `cl_hidden_count` > 0, print `N available, not shown`. `--all` must not increment or print the footer.

4. Help text
   - Files: `ai-rizz` (`cmd_help`)
   - Tests first: `N/A for prose & policy artifacts` (optional: extend `test_help_mentions_global_option` only if a help-contract test already covers list; do not add a help-string change-detector)
   - Changes: `list` usage becomes inventory; add list options `-a, --all` under Command-specific options.

5. Bash completion for list flags
   - Files: `completion.bash`
   - Tests first: Operator TDD carve-out (rework after preflight FAIL). Not prose/policy. Do not add tests. Do not grep `completion.bash` as a change-detector. Existing `test_bash_completion.test.sh` stays unchanged (name-listing helpers only). `_ai_rizz_completion` starts with `_init_completion`; a COMP_WORDS dispatcher harness for a static `compgen -W "-a --all"` line is out of scope. Inspect the new `list)` case arm.
   - Changes: `case "${prev}"` branch for `list` offering `-a --all`.

6. User and author docs
   - Files: `docs/user-guide/commands/list.md`, `docs/user-guide/commands/index.md`, `docs/user-guide/getting-started.md`, `docs/user-guide/advanced/constraints.md`, `docs/rule-authoring/rulesets.md`, `docs/developer-guide/architecture.md` (only if it claims `list` shows the catalog by default)
   - Tests first: `N/A for prose & policy artifacts`
   - Changes: document default inventory, footer, and `--all`. Getting-started discovery `ai-rizz list` after init becomes `ai-rizz list --all`; the post-`add` `ai-rizz list` stays bare (inventory). Ruleset authoring examples that show uninstalled trees use `--all`.

7. Full verification
   - Files: none new
   - Verification: `make test` (entire suite; read full output), then `make docs-build` (strict CI-parity documentation build)
   - Changes: fix any remaining `cmd_list` callers that still expect catalog on the default.

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing `is_installed` helper inside `cmd_list` (status strings `committed`/`local`/`global`/`uninstalled`)
- Existing section omission when a type is absent from the source catalog (extend to “absent from installed set” for default view)
- `cmd_deinit`-style POSIX flag parse
- shunit2 integration fixtures / mock source repos
- Existing completion name-listing tests (unchanged); no bash-completion package / `_init_completion` in this task

## Challenges & Mitigations

- Broad existing `cmd_list` callers: grep all test suites for `cmd_list` / `run_ai_rizz list` and retarget any `○` or uninstalled-section assertion to `--all` in step 1, before implementation, so the red suite is the new inventory tests — not a surprise after the flip
- Footer `N` vs ruleset trees: count only glyph-bearing top-level rows; tree lines have no `○`/`●`/`◐`/`★`. Oracle is `○` count from `--all`, which matches that definition
- Tests that `grep -v` or assert exact output may trip on the new footer: prefer `grep` for installed rows; do not snapshot whole `cmd_list` output
- `cmd_list` currently ignores extra args, so retargeted `--all` tests stay green on old code; that is intended. New tests (no `○` on default, footer present, unknown arg errors) are the red bar
- Default empty-after-init looks “broken” without docs: getting-started must switch the discovery invocation to `--all` in the same change
- Preflight previously FAILed step 5 as TDD encoding (tests or remove the feature). Operator chose a third path: keep the `list)` offers, no dispatcher tests, inspect-by-looking. Encode that as an operator carve-out, not as prose/policy and not as a change-detector. If TDD encoding still has no room for that carve-out, that is workflow friction for the preflight skill — do not add a harness and do not drop the completion line to appease the check

## Pre-Mortem

- Plan fails because we treat `--all` as optional and ship a default flip that turns the existing list suite into a wall of red with no catalog escape in tests: already covered by Challenge 1 (retarget in step 1) plus step 2 parsing `--all` in the same implementation as the filter
- Plan fails because `N` counts tree children or section headers and the footer disagrees with what users can `--all` to see: already covered by Challenge 2; if an implementation PR shows a mismatch, cut scope to “count `○` rows from the `--all` listing” and do not invent a second enumerator
- Plan fails because we rename section headers to `Installed X:` and churn every grep on `Available rules:`: keep existing titles (called out in step 3). Header rename is out of scope
- Plan fails because getting-started still says `list` then `add`, so first-run docs show only a footer: already covered by Challenge 5 / step 6
- Plan fails because preflight TDD encoding still has only “write tests” or “remove the unit” and rejects the operator carve-out: already covered by Challenge 6. Do not invent `_init_completion` stubs, do not grep `completion.bash`, do not relabel it prose. Surface that as workflow friction.

## Preflight Report

**Result:** FAIL

### Findings

1. **BLOCKING — Step 5 violates mandatory TDD encoding.** `completion.bash` is executable behavior, but the plan explicitly schedules no test before adding the `list)` completion branch. Inspection is not a test-first process and the operator carve-out conflicts with `.cursor/rules/shared/always-tdd.mdc`. This does not require installing bash-completion or building a `COMP_WORDS` dispatcher harness: `tests/unit/test_bash_completion.test.sh` can source `completion.bash`, stub `_init_completion` to set the dynamically scoped `cur`/`prev` locals, invoke `_ai_rizz_completion`, and assert `COMPREPLY`. Because the current operator decision forbids any such test, the plan has no compliant build path. Re-run `/niko-plan` after deciding whether to test the completion behavior, remove it from scope, or change the governing TDD policy.
2. **RESOLVED — Strict docs verification was missing.** Step 6 changes the ProperDocs site, while the original Step 7 ran only `make test`. Step 7 now also runs `make docs-build`, the documented CI-parity strict documentation gate.
3. **PASS — Convention, dependency, conflict, and requirement coverage.** The plan keeps changes in the established single-file command and completion dispatcher, preserves the `cl_` variable prefix, uses existing integration suites, accounts for direct-function and public-CLI consumers, and maps all Project Brief requirements to concrete files and behavior.

### Advisory

- A normalized internal record stream could make the catalog rows, installed view, and hidden count derive from one source of truth: emit one record per top-level item with type/status/label and render either all records or installed records while expanding trees only for selected rulesets. This would eliminate four parallel filtering/counting branches, but it broadens this Level 2 enhancement into a renderer refactor, so it is not incorporated into the current plan.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight (FAIL — build blocked)
- [ ] Build
- [ ] QA
