# Project Brief

## User Story

As an ai-rizz operator authoring rulesets, I want slash commands to install only from `rulesets/<ruleset>/commands/` so that root-level or support `.md` files are not mistaken for commands and the install contract matches `ai-rizz list`.

## Use-Case(s)

### Use-Case 1

A ruleset contains `local-command.md` at the ruleset root and `commands/magic-command.md`. Only the latter should appear under `.cursor/commands/<mode>/`.

### Use-Case 2

Documentation or reference `.md` files outside `commands/` stay in the ruleset tree for rules/skills and must not be flattened into the workspace commands directory.

## Requirements

1. During sync/copy of a ruleset, discover deployable command files only under `rulesets/<name>/commands/` (recursive `*.md` within that subtree), not elsewhere in the ruleset.
2. Continue to skip embedded skill reference trees under `rulesets/<name>/skills/` (unchanged).
3. Preserve existing behavior for `.mdc` rules, uppercase `.md` skip inside the command tree, symlinks, and flat copy to the mode commands directory.

## Constraints

- Align with GitHub issue #31 intended contract; update tests and docs that assumed root-level `.md` commands.

## Acceptance Criteria

1. Root-level `*.md` in a ruleset are not copied to `.cursor/commands/<mode>/`.
2. `commands/**/*.md` (with existing uppercase and symlink rules) still deploy flat to `.cursor/commands/<mode>/`.
3. Full `make test` passes.
