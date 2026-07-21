# Project Brief

## User Story

As a repository user, I want `deinit` to remove project-scoped (local/commit) configuration without also wiping my global settings, so that cleaning up a single repo is not a footgun against machine-wide `ai-rizz` state.

## Use-Case(s)

### Use-Case 1

In a git repo with local and/or commit mode initialized (and possibly global as well), I run `ai-rizz deinit --both` and only local + commit are removed; global remains intact.

### Use-Case 2

`ai-rizz deinit --all` is no longer available (or no longer acts as a silent wipe of everything including global), so I cannot accidentally destroy global settings while deiniting a project.

## Requirements

1. Add `deinit --both` that wipes local + commit only (not global).
2. Remove the `deinit --all` footgun.
3. Update help, docs, shell completion, and tests to match the new surface.

## Constraints

1. Explicit `--local`, `--commit`, and `--global` remain valid for single-mode deinit.
2. Follow project TDD and testing practices (`make test`; never run `ai-rizz` against this repo for ad-hoc testing).
3. Scope is as specified in [issue #42](https://github.com/Texarkanine/ai-rizz/issues/42).

## Acceptance Criteria

1. `deinit --both` removes local and commit configuration and leaves global untouched.
2. `deinit --all` / `-a` is removed (or rejected) so it cannot wipe global as a side effect of project deinit.
3. Docs, help text, and `completion.bash` reflect the new flags.
4. Relevant tests pass; full suite (`make test`) passes.
