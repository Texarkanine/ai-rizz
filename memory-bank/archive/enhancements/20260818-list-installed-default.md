---
task_id: list-installed-default
complexity_level: 2
date: 2026-08-18
status: completed
---

# TASK ARCHIVE: list defaults to installed inventory

## SUMMARY

`ai-rizz list` now shows installed inventory (mode glyphs). `-a`/`--all` restores the previous catalog, including uninstalled `○` rows. Default view omits empty-of-installed section headers and, when anything is hidden, prints one footer `N available, not shown` (`N` = omitted top-level glyph-bearing rows, not ruleset tree children). Draft PR [#51](https://github.com/Texarkanine/ai-rizz/pull/51).

## REQUIREMENTS

- Default `list` is inventory only (`●` / `◐` / `★`); no `○` rows.
- Section headers print only when that section has at least one installed member.
- Uninstalled rulesets (and their trees) are omitted; installed rulesets still expand.
- One cumulative footer `N available, not shown` when anything is hidden; no footer under `--all`.
- Flags (`-a`/`--all`), not a `list installed` subcommand; unknown args error.
- Help and user docs follow; getting-started discovery uses `list --all`.
- Existing catalog tests keep covering catalog via `--all`.

## IMPLEMENTATION

- **[`ai-rizz`](https://github.com/Texarkanine/ai-rizz/blob/list-installed/ai-rizz) `cmd_list`:** After init/manifest validate, POSIX parse of `-a`/`--all` (unknown → `Unknown argument: $1`). Nested `cl_note_item`: installed prints; uninstalled + `--all` prints; else increment `cl_hidden_count` and skip (no ruleset tree). Headers on first printed row. Footer when not `--all` and count > 0.
- **[`completion.bash`](https://github.com/Texarkanine/ai-rizz/blob/list-installed/completion.bash):** `list)` arm offers `-a --all` only. Mode flags (`--global`, etc.) are not list flags — `list` is cross-mode; glyphs distinguish modes.
- **Docs/help:** inventory default; `--all` catalog; getting-started first list after init is `list --all`.
- **Persistent bank:** listing use case, list-view test contract, completion stub recipe.

Footer-hint advisory (`N available, not shown (ai-rizz list --all)`) was not applied — Requirement 4 pins the exact string.

## TESTING

- Inventory/footer/flag cases in `test_list_display.test.sh` and `test_cli_list_sync.test.sh`; catalog/`○` assertions retargeted to `--all`.
- Cheap completion test: source `completion.bash` with `AI_RIZZ_COMPLETION_TEST=1`, stub `_init_completion` to set dynamically scoped `cur`/`prev` via `COMP_TEST_PREV`/`COMP_TEST_CUR` (not stub argv — `_init_completion` is called with no args; do not `local` those names).
- `make test` passed; `make docs-build` (`properdocs --strict`) passed.
- Preflight: two FAILs on completion TDD, then PASS WITH ADVISORY after the cheap stub.
- QA: FAIL (docs footer 6 vs five `○` rows; skill test wholesale-retargeted to `--all` dropped the inventory half; missing empty-catalog and nonzero-unknown-arg asserts), then PASS after rework.

## LESSONS LEARNED

Inlined from ephemeral reflection:

- A mixed installed/uninstalled list test cannot be wholesale-retargeted to `--all`; keep a default `cmd_list` call for the installed half.
- `_init_completion` takes no arguments. Stub `cur`/`prev` through the environment, and do not `local` those names in the stub (bash dynamic scope).
- `VERBOSE_TESTS` prefixes `DEBUG: Running: …` onto CLI output, so full-string equality of `list -a` vs `list --all` is not a valid CLI assertion.
- Inspection is not a TDD carve-out for executable completion. The cheap stub was enough; a tty/`COMP_WORDS` harness was not. Name-listing tests stay (missed rule bodies before); flag offers deserve the same class of test.
- Inventory as the default and catalog behind `--all` is the shape `cmd_list` should have had from the start: one printer, a show-uninstalled flag, headers on first printed row. No second command, no header rename.

## PROCESS IMPROVEMENTS

- Preflight's tests-or-remove fork was correct to hold. Plan-upstream friction is real; auto-amending the plan under the operator would have been worse. Operator interrogation is not a preference to rewrite the workflow.
- A TDD Plan Encoding FAIL that is a missing tests-first line on an agreed executable step still stops for `/niko-plan`.

## TECHNICAL IMPROVEMENTS

None required. Optional later work (not this task): a mode-filtered inventory (`list --global` → only `★` rows) would be new behavior, not a completion gap — `--global` on `list` currently errors as unknown.

## NEXT STEPS

Merge [PR #51](https://github.com/Texarkanine/ai-rizz/pull/51) when ready.
