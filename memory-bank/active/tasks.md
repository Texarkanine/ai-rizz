# Task: list-installed-default

* Task ID: list-installed-default
* Complexity: Level 2
* Type: simple enhancement

`ai-rizz list` defaults to installed inventory. `-a`/`--all` restores today's catalog. Default view omits empty-of-installed section headers and ends with one footer `N available, not shown` when any top-level catalog item was hidden.

**Rework (after second preflight FAIL):** operator accepted the cheap completion test. Keep the `completion.bash` `list)` offers. Before adding them, add a failing test in `tests/unit/test_bash_completion.test.sh`: source `completion.bash`, stub `_init_completion` so it sets the dynamically scoped `cur`/`prev` locals, invoke `_ai_rizz_completion`, assert `COMPREPLY` contains `-a` and `--all`. No bash-completion package, no `COMP_WORDS` tty harness. Name-listing tests stay.

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
- List completion: `_ai_rizz_completion` with `prev=list` and empty `cur` → `COMPREPLY` contains `-a` and `--all`

### Edge Cases

- Invalid input: unknown flag/positional on `list` → actionable error (copy-paste not required; name the bad token)
- Empty catalog (no rules/commands/skills/rulesets in source): default list prints nothing (no footer)
- Boundary: `N=1` uses the same format (`1 available, not shown`), no special plural
- `--all` when everything is installed: catalog listing, still no footer
- Interaction: existing glyph tests that asserted `○` on bare `cmd_list` must assert that on `--all` instead; default `cmd_list` must still show `●`/`◐`/`★` for installed items
- Footer must not appear twice or per-section
- Completion stub: `_init_completion` is overridden after sourcing `completion.bash`; `AI_RIZZ_COMPLETION_TEST=1` still skips `complete -F`. Do not require the bash-completion package. A grep of `completion.bash` is not the test.

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh`
- Test location: `tests/integration/functions/` (direct `cmd_*`), `tests/integration/` (public CLI), `tests/unit/test_bash_completion.test.sh` (completion)
- Conventions: `test_<behavior>()` in `test_<feature>.test.sh`; temp git repos; `git commit --no-gpg-sign`; never run against this project directory
- New test files: none — extend existing suites
- Completion helper: add a `bash -c` wrapper next to `_list_rule_names` / `_call_get_repo_dir`. Source `completion.bash` with `AI_RIZZ_COMPLETION_TEST=1`, define `_init_completion` to assign `cur` and `prev` (bash dynamic scope: those names are `local` in `_ai_rizz_completion`), call `_ai_rizz_completion`, print `COMPREPLY` one per line.

### Test File Mapping

- `tests/integration/functions/test_list_display.test.sh` — new cases for default filter, omitted headers, footer oracle (`N` = `○` count from `--all`), `-a`/`--all`, unknown arg, empty-hidden no footer. Retarget `test_list_shows_uninstalled_glyph_for_new_command` and any other `○`/uninstalled-section assertions to `--all`.
- `tests/integration/functions/test_rule_management.test.sh` — glyph tests that currently require `○` on bare `cmd_list` (`test_list_local_mode_only_glyphs`, `test_list_commit_mode_only_glyphs`, `test_list_dual_mode_all_glyphs`) call `cmd_list --all` for the catalog half; add or keep default-`cmd_list` assertions that installed glyphs still appear without `○`.
- `tests/integration/functions/test_skill_list_display.test.sh` — catalog discovery cases (`test_standalone_skill_appears_in_skills_section`, uninstalled-glyph half of `test_standalone_skill_installed_glyph`, section-order when the skill/ruleset is not installed) use `--all`. Installed-glyph and installed-ruleset tree cases can stay on default `cmd_list` (footer extra lines are fine for `grep`).
- `tests/integration/functions/test_ruleset_list_display.test.sh` — tree-shape tests that list a ruleset without adding it must use `--all`; tests that `cmd_add_ruleset` first can stay on default.
- `tests/integration/functions/test_global_only_context.test.sh` — if `test_global_list_shows_available_commands_outside_git_repo` lists an uninstalled command, switch that call to `--all`.
- `tests/integration/test_cli_list_sync.test.sh` — `○` assertions move to `run_ai_rizz list --all`; add CLI cases for default inventory, footer, `-a`, and unknown flag.
- `tests/integration/functions/test_ruleset_management.test.sh` / `test_ruleset_removal_and_structure.test.sh` / `test_custom_path_operations.test.sh` — retarget only if they assert uninstalled rows or section headers for items not in a manifest.
- `tests/unit/test_bash_completion.test.sh` — new case `test_list_completes_all_flags` (name may vary): `prev=list`, empty `cur` → output contains `-a` and `--all`. Watch it fail (today there is no `list)` arm). Then implement the arm. Do not expand this task into testing every completion surface.

### Retarget Enumeration (from preflight)

Every existing test that calls bare `cmd_list` / `run_ai_rizz list` and asserts on catalog content for an item that was never added. Retarget these to `--all` in step 1; the mapping above named only a subset.

`tests/integration/functions/test_list_display.test.sh`
- `test_list_shows_uninstalled_glyph_for_new_command`
- `test_list_shows_commands_with_slash_prefix`
- `test_list_strips_md_extension_from_commands`
- `test_list_commands_alignment_correct`
- `test_list_expands_commands_directory`
- `test_list_handles_empty_commands_directory`
- `test_list_commands_last_sibling_uses_blank_stem`
- `test_list_commands_middle_sibling_keeps_pipe_stem`
- `test_list_skills_last_sibling_uses_blank_stem`
- `test_list_skills_middle_sibling_keeps_pipe_stem`
- `test_list_empty_rules_section_omitted`, `test_list_empty_commands_section_omitted`, `test_list_empty_skills_section_omitted`, `test_list_empty_rulesets_section_omitted` — these pass vacuously after the flip (empty-of-installed also yields no header), which silently drops the catalog-empty contract they exist for. Move them to `--all` so they keep testing it.

`tests/integration/functions/test_skill_list_display.test.sh`
- `test_standalone_skill_appears_in_skills_section`
- `test_standalone_skill_installed_glyph` (uninstalled half only)
- `test_embedded_skill_not_in_skills_section`
- `test_skill_deduplicated_when_in_both_paths`
- `test_ruleset_tree_expands_skills_subdir`
- `test_ruleset_tree_shows_in_repo_symlinked_embedded_skill`
- `test_ruleset_tree_skills_subdir_shows_only_valid_skills`
- `test_ruleset_tree_skips_out_of_repo_symlinked_embedded_skill`
- `test_rulesets_section_comes_after_skills_section`

`tests/integration/functions/test_ruleset_list_display.test.sh`
- `test_list_keeps_magic_skills_directory_visible`
- `test_list_hides_unsupported_root_level_skill_like_directory`
- Tests that call `cmd_add_ruleset` first stay on default `cmd_list`: `test_list_shows_subdirs_as_entries_but_hides_their_contents`, `test_list_shows_tree_for_all_rulesets`, `test_mdc_files_visible_in_list`, `test_complex_ruleset_display`

`tests/integration/functions/test_rule_management.test.sh`
- `test_list_local_mode_only_glyphs`, `test_list_commit_mode_only_glyphs`, `test_list_dual_mode_all_glyphs` (catalog half)

`tests/integration/functions/test_global_only_context.test.sh`
- `test_global_list_shows_available_commands_outside_git_repo` — confirmed: it asserts on `cmd1.md`, which setUp creates but never adds. Must use `--all`.

`tests/integration/test_cli_list_sync.test.sh`
- `○` assertions in the three `test_list_shows_correct_glyphs_*` cases move to `list --all`; add the new default/footer/`-a`/unknown-flag CLI cases.

Confirmed **not** affected — do not touch:
- `tests/integration/functions/test_error_handling.test.sh` — all six `cmd_list` callers either error before listing or assert on an installed rule; `test_graceful_empty_repository` asserts exit 0 with no `error:`/`fatal:`, which the empty catalog still satisfies (no footer, no sections)
- `test_list_progressive_display_no_modes` — errors before listing
- `test_list_without_initialization` — errors before listing
- `tests/integration/functions/test_ruleset_management.test.sh` — every assertion is on an added rule/ruleset
- `test_ruleset_removal_and_structure.test.sh` — `●` positive plus a negative `○` assertion, both still true
- `tests/integration/functions/test_custom_path_operations.test.sh` — `test_list_shows_custom_paths` adds first
- `tests/integration/test_ruleset_commands.test.sh` — only *defines* `UNINSTALLED_GLYPH` in setUp; never asserts on it
- `tests/integration/test_help_and_usage.test.sh` — help assertions are loose substrings (`list`, `init`, …), so the step 4 help edit cannot break them

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
   - Files: `tests/unit/test_bash_completion.test.sh`, `completion.bash`
   - Tests first: `test_bash_completion.test.sh` — new helper plus `test_list_completes_all_flags`; watch fail (no `list)` arm → empty `COMPREPLY`)
   - Changes: helper stubs `_init_completion` as above. Add `case "${prev}"` branch `list)` offering `-a --all`. Do not grep `completion.bash` as the assertion.

6. User and author docs
   - Files: `docs/user-guide/commands/list.md`, `docs/user-guide/commands/index.md`, `docs/user-guide/getting-started.md`, `docs/user-guide/advanced/constraints.md`, `docs/rule-authoring/rulesets.md`. Preflight checked `docs/developer-guide/architecture.md`: it makes no `list` catalog claim, so it needs no edit.
   - `docs/user-guide/commands/index.md` embeds `ai-rizz help` output verbatim; the step 4 help edit must be mirrored into that block or `make docs-build` ships a stale help transcript. `docs/user-guide/commands/list.md` shows a full example listing with `○` rows — it becomes the `--all` example, plus a new default-inventory example with the footer.
   - Tests first: `N/A for prose & policy artifacts`
   - Changes: document default inventory, footer, and `--all`. Getting-started discovery `ai-rizz list` after init becomes `ai-rizz list --all`; the post-`add` `ai-rizz list` stays bare (inventory). Ruleset authoring examples that show uninstalled trees use `--all`.

7. Full verification
   - Files: none new
   - Tests first: `make test` (entire suite; read full output), then `make docs-build` (strict CI-parity documentation build)
   - Changes: fix any remaining `cmd_list` callers that still expect catalog on the default.

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing `is_installed` helper inside `cmd_list` (status strings `committed`/`local`/`global`/`uninstalled`)
- Existing section omission when a type is absent from the source catalog (extend to “absent from installed set” for default view)
- `cmd_deinit`-style POSIX flag parse
- shunit2 integration fixtures / mock source repos
- Existing `test_bash_completion.test.sh` `bash -c` sourcing pattern; bash dynamic scoping of `local cur prev` inside `_ai_rizz_completion`

## Challenges & Mitigations

- Broad existing `cmd_list` callers: grep all test suites for `cmd_list` / `run_ai_rizz list` and retarget any `○` or uninstalled-section assertion to `--all` in step 1, before implementation, so the red suite is the new inventory tests — not a surprise after the flip
- Footer `N` vs ruleset trees: count only glyph-bearing top-level rows; tree lines have no `○`/`●`/`◐`/`★`. Oracle is `○` count from `--all`, which matches that definition
- Tests that `grep -v` or assert exact output may trip on the new footer: prefer `grep` for installed rows; do not snapshot whole `cmd_list` output
- `cmd_list` currently ignores extra args, so retargeted `--all` tests stay green on old code; that is intended. New tests (no `○` on default, footer present, unknown arg errors) are the red bar
- Default empty-after-init looks “broken” without docs: getting-started must switch the discovery invocation to `--all` in the same change
- Completion stub must assign `cur`/`prev` so `_ai_rizz_completion`'s locals receive them (bash dynamic scope). If the stub sets its own `local cur prev`, the test is a false green. Do not install bash-completion. Do not simulate `COMP_WORDS`.

## Pre-Mortem

- Plan fails because we treat `--all` as optional and ship a default flip that turns the existing list suite into a wall of red with no catalog escape in tests: already covered by Challenge 1 (retarget in step 1) plus step 2 parsing `--all` in the same implementation as the filter
- Plan fails because `N` counts tree children or section headers and the footer disagrees with what users can `--all` to see: already covered by Challenge 2; if an implementation PR shows a mismatch, cut scope to “count `○` rows from the `--all` listing” and do not invent a second enumerator
- Plan fails because we rename section headers to `Installed X:` and churn every grep on `Available rules:`: keep existing titles (called out in step 3). Header rename is out of scope
- Plan fails because getting-started still says `list` then `add`, so first-run docs show only a footer: already covered by Challenge 5 / step 6
- Plan fails because the completion test stubs `_init_completion` with new locals and never actually feeds `prev=list` into `_ai_rizz_completion`: already covered by Challenge 6; assert on `COMPREPLY` contents, not on a grep of `completion.bash`

## Preflight Notes

- Completion test route verified empirically against `completion.bash`: stubbing `_init_completion() { cur=""; prev="list"; }` after sourcing yields `COMPREPLY` count 0 today (the red bar) and `-a --all` once the `list)` arm exists. `compgen -W "-a --all" -- ""` returns both words, and `-- "--"` narrows to `--all`.
- Step 2 places the flag parse after `ensure_initialized_and_valid`, so `ai-rizz list --bogus` in an uninitialized repo reports "no configuration found" rather than the bad token. `cmd_deinit` parses first. Both are defensible; this is a deliberate choice, not an oversight. The parse still lands before `git_sync`, so a bad flag costs no network fetch.
- `-a`/`--all` collides with nothing: the tool's only other `-a` is `cmd_deinit`'s rejection arm steering users to `--both`. Note the vocabulary asymmetry (`-a` means "all" for `list`, "not a thing" for `deinit`).
- `cmd_list` has exactly one caller (the dispatcher), which already forwards `"$@"`. No `ai-rizz list --global` / `list -g` usage exists in the tool, tests, or docs.
- `cl_hidden_count` is safe to increment inside every `cmd_list` display loop: the rules/commands/rulesets loops are plain `for`, and the skills loop reads from a temp file rather than a pipe, so none of them run in a subshell.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight (PASS WITH ADVISORY)
- [x] Build
- [x] Build
- [ ] QA
