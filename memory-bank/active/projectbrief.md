# Project Brief

## User Story

As a ruleset author, I want `ai-rizz list` to show only supported ruleset contents so that I am not misled into thinking unsupported root-level skill-like directories will install as embedded skills.

## Use-Case(s)

### Use-Case 1

A ruleset contains a valid embedded skill at `rulesets/example/skills/magic-skill/SKILL.md`, and `ai-rizz list` shows that skill under the `skills` magic directory in the ruleset tree.

### Use-Case 2

A ruleset contains an unsupported root-level directory like `rulesets/example/local-skill/SKILL.md`, and `ai-rizz list` does not display that directory as if it were installable ruleset content.

### Use-Case 3

A ruleset contains a regular top-level helper directory with nested `.mdc` rules, and `ai-rizz list` still displays that directory because it contains supported deployable rules.

## Requirements

1. Update ruleset tree listing in `cmd_list` so unsupported top-level directories are excluded.
2. Preserve display of supported top-level entries: `.mdc` files, `commands`, `skills`, and other directories that contain deployable `.mdc` rules.
3. Add or update integration tests to cover the unsupported root-level `SKILL.md` directory case.
4. Ensure existing list behavior for valid `skills/` magic directory and nested rule directories does not regress.
5. Update docs under `docs/` to match the intended ruleset contract for list display.

## Constraints

1. Keep implementation POSIX-shell compliant and consistent with existing variable-prefix and temp-file patterns.
2. Follow strict TDD workflow: tests first, then implementation.
3. Run targeted suite(s) during iteration and `make test` for final verification.

## Acceptance Criteria

1. `ai-rizz list` no longer shows unsupported root-level skill-like directories as ruleset tree entries.
2. `ai-rizz list` still shows embedded skills only under `rulesets/<ruleset>/skills/<skill>/SKILL.md`.
3. Existing supported top-level deployable rule subdirectories remain visible in ruleset list output.
4. Integration tests cover this issue and pass.
5. Documentation accurately describes the supported ruleset layout and list behavior.
