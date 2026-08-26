---
task_id: list-empty-inventory-catalog
complexity_level: 2
date: 2026-08-26
status: completed
---

# TASK ARCHIVE: list shows full catalog when inventory is empty

## SUMMARY

When every active manifest is empty (fresh init, nothing installed), plain `ai-rizz list` now shows the full source catalog — same output as `--all`, with `○` glyphs and no footer. Once anything is installed, default `list` stays inventory-only with `N available, not shown`. Draft PR [#53](https://github.com/Texarkanine/ai-rizz/pull/53).

## REQUIREMENTS

- Empty inventory across active modes: default `list` equals `list --all` (catalog sections, uninstalled glyphs, no footer).
- Non-empty inventory: inventory-only default and footer unchanged; explicit `-a`/`--all` unchanged.
- Empty source catalog (no rules/commands/rulesets in repo): still prints nothing.
- Tests in function and CLI integration suites; docs and `systemPatterns` list-view contract updated.

## IMPLEMENTATION

- **[`ai-rizz`](https://github.com/Texarkanine/ai-rizz/blob/no-empty-list/ai-rizz) `cmd_list`:** After flag parse, scan active manifests (local/commit/global). If no entries and `--all` not passed, set `cl_show_all=true` before the listing loop.
- **Tests:** `test_list_nothing_installed_shows_full_catalog` replaces footer-only empty case; `test_list_fresh_init_shows_catalog` in CLI suite.
- **Docs:** [`list.md`](https://github.com/Texarkanine/ai-rizz/blob/no-empty-list/docs/user-guide/commands/list.md), [`getting-started.md`](https://github.com/Texarkanine/ai-rizz/blob/no-empty-list/docs/user-guide/getting-started.md) — plain `list` after init.
- **Persistent bank:** `systemPatterns.md`, `productContext.md` listing use case.

## TESTING

- `test_list_display.test.sh`: 25/25 pass (function-level).
- PR #53 CI: ShellCheck, Unit Tests, Docs strict build — success.
- `/niko-qa`: PASS (advisories: repeated manifest-scan blocks mirror existing style; optional fresh-init example tab in `list.md`).

Niko workflow was retroactively backfilled after implementation shipped; QA ran against backfilled plan.

## LESSONS LEARNED

Inlined from ephemeral reflection:

- Reusing `cl_show_all` avoided a second listing path — the flag was already the catalog switch.
- Invoking a delivery skill immediately after intent confirmation skipped Niko Step 7; retroactive backfill works but costs more than following the state machine.
- Manifest entry scan is the correct empty-inventory signal (not footer heuristic).

## PROCESS IMPROVEMENTS

- Do not treat PR-open skills as a substitute for Niko phase transitions after `/niko` intent approval; Step 7 (complexity analysis + ephemeral files) must run before build/QA.

## TECHNICAL IMPROVEMENTS

- Optional: add a "Fresh init" example tab to `list.md` (QA advisory).
- Optional: dual-mode empty-inventory test (not required by plan).

## NEXT STEPS

Merge [PR #53](https://github.com/Texarkanine/ai-rizz/pull/53) when ready.
