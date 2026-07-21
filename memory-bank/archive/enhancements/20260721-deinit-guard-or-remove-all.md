---
task_id: deinit-guard-or-remove-all
complexity_level: 2
date: 2026-07-21
status: completed
---

# TASK ARCHIVE: deinit --both replaces --all footgun (#42)

## SUMMARY

Shipped [#42](https://github.com/Texarkanine/ai-rizz/issues/42): `deinit --both`/`-b` removes local+commit only; `--all`/`-a` is rejected with an actionable hint so project deinit cannot wipe global settings. Docs, help, completion, and tests updated. PR [#47](https://github.com/Texarkanine/ai-rizz/pull/47).

## REQUIREMENTS

- Add `deinit --both` that wipes local + commit only (not global).
- Remove the `deinit --all` footgun.
- Update help, docs, shell completion, and tests.
- Explicit `--local` / `--commit` / `--global` remain valid.

## IMPLEMENTATION

- **`cmd_deinit` (`ai-rizz`)**: Parse `--both`/`-b`; reject `--all`/`-a` with hint toward `--both` / `--global`; interactive prompt and no-mode default use `both`; `AI_RIZZ_MODE=both` accepted, `all` ignored; typed `all` gets the same actionable invalid-mode error.
- **Integrity Option 3**: Suggests `deinit --both` (project reset), not a machine-wide wipe.
- **Docs / help / completion**: `init-deinit.md`, commands index help mirror, `cmd_help` deinit options, `completion.bash` deinit flags.
- **PR feedback**: Dropped redundant pre-`cmd_init` `init_global_paths` in the global-preservation test.

## TESTING

- Extended `test_deinit_modes.test.sh` and `test_cli_deinit.test.sh` (`--both`, global preservation, `--all`/`-a` rejection, prompt text).
- `make test` 35/35; Level 2 QA PASS (no code changes from QA).
- Manual smoke on PR #47: prompt offers `both` not `all`; choosing `both` left global rules intact.

## LESSONS LEARNED

Inlined from ephemeral reflection:

- Integrity-error “reset everything” copy had been recommending a machine-wide wipe for a local/commit metadata mismatch — flag renames are a good moment to audit suggested fix commands, not only the flag parser.
- If `--both` (project modes) vs `--global` had always been the aggregation model, there would never have been an “all modes” flag that crossed the project/user boundary.

## PROCESS IMPROVEMENTS

Nothing notable beyond keeping the TDD red→green cycle tight on the existing deinit suites.

## TECHNICAL IMPROVEMENTS

None required. Optional taste (dismissed on PR review): word `--all` rejection as “Deprecated flag” instead of “Unknown argument” — current message already carries the actionable hint.

## NEXT STEPS

None. Merge PR #47 when ready.
