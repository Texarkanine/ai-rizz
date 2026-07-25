---
task_id: fix-sync-standalone-entry-relocates
complexity_level: 2
date: 2026-07-25
status: completed
---

# TASK ARCHIVE: Sync remaps slug-preserving standalone relocates

## SUMMARY

Fixed `ai-rizz sync` so standalone manifest entries whose exact path is gone but whose name-slug still exists under `rules/` as another entity form (rule `.mdc` / command `.md` / skill dir) are remapped: sync deploys the current form, rewrites the manifest path, and stops emitting “Entry not found” for those entries. Truly missing slugs still warn and stay in the manifest. Ruleset entries unchanged (existing walk handles layout churn).

## REQUIREMENTS

- Diagnose and fix sync failure / partial apply when upstream relocates entries by identical name-slug across rule ↔ command ↔ skill.
- Remap + deploy + rewrite manifest for standalone `rules/*` only; do not slug-remap `rulesets/*`.
- Cover forward/reverse form changes, exact-path wins, ambiguous priority, and truly-missing.
- Align resolution priority with `cmd_add_rule` bare-name order (skill → `.mdc` → `.md`).
- Full suite passes (`make test`).

## IMPLEMENTATION

- **`resolve_standalone_entry` (`ai-rizz`):** Shared helper — exact path if present; else probe skill → `.mdc` → `.md` under `RULES_PATH` for the slug; ignore `rulesets/*`; stdout canonical relative path or empty.
- **`cmd_add_rule`:** Bare-name branch calls the shared resolver (add/sync cannot drift).
- **`sync_manifest_to_directory`:** Before copy, resolve standalone entries; on path change, rewrite manifest (remove old + add new), `warn "Relocated old → new"`, then copy resolved path; “Entry not found” only when resolve returns empty.
- **Tests:** `tests/unit/test_resolve_standalone_entry.test.sh` (12); `tests/integration/functions/test_sync_entry_relocates.test.sh` (7).
- **Docs:** `docs/user-guide/commands/sync.md`, `docs/developer-guide/manifest.md`.
- **Patterns:** `memory-bank/systemPatterns.md` — sync remap note.

## TESTING

- New unit + integration suites green (19 tests).
- Full suite: `make test` 37/37.
- Level 2 QA: PASS (semantic review; no code changes). Preflight/QA status lived in ephemeral `.preflight-status` / `.qa-validation-status` (removed at archive).

## LESSONS LEARNED

Inlined from ephemeral `reflection-fix-sync-standalone-entry-relocates.md` (removed with archive):

- Manifests store exact paths; entity-form moves are invisible unless sync rewrites. Ruleset entries already tolerate layout churn via live tree walk — standalone entries need an explicit remap step.
- `grep && fail` under `set -e` fails the test when grep misses; prefer `if grep; then fail; fi`.
- Plan sequence held; preflight’s shared-resolver amendment paid off immediately.
- Smallest correct patch on the existing contract is path identity + sync-time remap; elegant long-term shape would be slug-primary identity (paths as deploy detail).

## PROCESS IMPROVEMENTS

Nothing notable beyond keeping TDD red→green tight after the `set -e` / `grep` assertion fix.

## TECHNICAL IMPROVEMENTS

Optional (out of scope, recorded as insight only): move manifests to slug-primary (or typed) identity and resolve current form on every sync/add/list.

## NEXT STEPS

None for this task. Operator can heal stale global installs (e.g. `~/ai-rizz.skbd`) with one `ai-rizz sync` after the fix.
