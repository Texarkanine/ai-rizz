# Project Brief

## User Story

As a developer using `ai-rizz list`, I want ruleset trees to draw correct box-drawing connectors so that last-sibling parents (`└──`) do not leave a dangling vertical bar under their children.

## Use-Case(s)

### Use-Case 1

Run `ai-rizz list` when a ruleset ends with a `skills/` (or `commands/`) directory. Nested children under that last sibling indent with spaces, not `│`.

### Use-Case 2

Run `ai-rizz list` when `commands/` or `skills/` is a middle sibling (`├──`). Nested children still use `│` as the stem, unchanged from current correct behavior.

## Requirements

1. Nested items under `commands/` and `skills/` in `cmd_list` must key the stem prefix off whether the parent used `└──` or `├──`.
2. Last-sibling parents use a blank stem (`    `) for children; non-last parents keep `│   `.
3. No other list behavior changes (glyphs, ordering, discovery, non-nested items).

## Constraints

1. POSIX-compliant shell (`ai-rizz`); follow existing `cl_` variable prefix patterns.
2. TDD: tests first, then implementation.
3. Do not test `ai-rizz` in the project directory — use the test suite / temp dirs.

## Acceptance Criteria

1. When `skills` (or `commands`) is the last top-level child of a ruleset, its children print with spaces under `└──`, not `│`.
2. When `commands` (or `skills`) is not last, children still print with `│` under `├──`.
3. Existing list tests continue to pass; new coverage asserts the stem for last vs non-last parents.
