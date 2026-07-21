---
task_id: fix-issues-40-41-repo-global-select
complexity_level: 2
date: 2026-07-21
status: completed
---

# TASK ARCHIVE: Repo-aware mode select excludes global (#40, #41)

## SUMMARY

Fixed [#40](https://github.com/Texarkanine/ai-rizz/issues/40) and [#41](https://github.com/Texarkanine/ai-rizz/issues/41): inside a git repository, `select_mode()` ignores global when auto-selecting. Unflagged commands pick the single local or commit mode; global always requires `--global` / `AI_RIZZ_MODE=global`. When neither local nor commit is initialized, the command errors with an actionable message instead of silently using global (and writing an invalid project manifest). Outside git, global-only auto-select is unchanged.

## REQUIREMENTS

- Local XOR commit + global active → unflagged add auto-selects the repo mode (#41).
- Only global active inside a git repo → unflagged add errors; no invalid project manifest (#40).
- Only global outside git → still auto-selects global.
- Explicit `--global` / `--local` / `--commit` remain authoritative; multi-mode (local+commit) still requires a flag.
- Tests cover the above; `make test` passes. Out of scope: `deinit --all` / #42.

## IMPLEMENTATION

- **`select_mode()` (`ai-rizz`):** When `.git` exists, count only local+commit for auto-select; zero repo modes → `show_repo_mode_required_error`; one → that mode; two → existing multi-mode error. Outside git, preserve prior global-only path. Explicit arg and `AI_RIZZ_MODE` unchanged.
- **`show_repo_mode_required_error`:** Actionable stderr (init local/commit or pass `--global`) instead of the misleading “multiple modes” message when none exist.
- **Tests:** `tests/integration/functions/test_global_mode_detection.test.sh` — flipped `test_select_mode_two_modes_local_global` to expect local; added commit+global, only-global-in-repo error, unflagged `cmd_add_rule` smoke, and `--global` success counterpart.
- **Docs:** `docs/user-guide/rule-modes.md` — choosing-a-mode policy note.

## TESTING

- Targeted suite: `test_global_mode_detection` 15/15.
- Full suite: `make test` 34/34.
- Level 2 QA: PASS (semantic review; no code changes). Status lived in ephemeral `.qa-validation-status` (removed at archive).

## LESSONS LEARNED

Inlined from ephemeral `reflection-fix-issues-40-41-repo-global-select.md` (removed with archive):

- Delivered as specified; closed the auto-select-global path rather than chasing a separate invalid-manifest writer.
- Plan held: lever was `select_mode`, tests in the global detection suite, existing local+global expectation needed flipping.
- Helpers that `exit` never reach a sibling `|| echo` inside `$(...)`; assert on stderr text the way neighboring tests already do.
- Treat “global is never part of repo auto-select” as the original contract for `select_mode` — which is what was implemented.

## PROCESS IMPROVEMENTS

Nothing notable beyond keeping TDD red→green tight after assertion-shape fixes.

## TECHNICAL IMPROVEMENTS

None required. Optional advisory from preflight (not done): mirror #40/#41 cases for `cmd_add_ruleset` as well as `cmd_add_rule`.

## NEXT STEPS

None for this task. #42 (`deinit --all`) remains out of scope.
