# Project Brief

## User Story

As a user with global mode initialized, I want repo-scoped `add` to auto-select local/commit without offering global, and I want bare-repo `add` (no local/commit init) to error instead of writing a broken manifest, so that global stays opt-in via `--global` and invalid manifests are never created.

## Use-Case(s)

### Use-Case 1 — [#41](https://github.com/Texarkanine/ai-rizz/issues/41)

Repo has only local (or only commit) init'd; global is also active user-wide. `ai-rizz add rule <x>` (or ruleset) proceeds without a mode prompt/error; global requires explicit `--global`.

### Use-Case 2 — [#40](https://github.com/Texarkanine/ai-rizz/issues/40)

Global is init'd; current directory is a git repo with no local/commit init. `ai-rizz add rule <x>` errors (does not write invalid `ai-rizz.skbd`). Explicit `--global` still adds to global.

## Requirements

1. Fix [#40](https://github.com/Texarkanine/ai-rizz/issues/40) as described in the issue.
2. Fix [#41](https://github.com/Texarkanine/ai-rizz/issues/41) as described in the issue.
3. Outside a git repo, global-only auto-select continues to work.
4. Explicit `--global` / `--local` / `--commit` remain authoritative.

## Constraints

1. Do not change `deinit --all` / [#42](https://github.com/Texarkanine/ai-rizz/issues/42) in this task.
2. Prefer fixing mode selection policy in `select_mode()` so all callers benefit.

## Acceptance Criteria

1. Local XOR commit + global active → unflagged add auto-selects the repo mode.
2. Only global active inside a git repo → unflagged add errors; no invalid project manifest written.
3. Only global outside git → unflagged operations still auto-select global.
4. Explicit `--global` works in a repo with or without local/commit.
5. Existing multi-mode (local+commit, or all three) still requires an explicit flag.
6. Tests cover the above; `make test` passes.
