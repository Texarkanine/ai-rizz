# Project Brief

## User Story

As an ai-rizz CLI user, I want bash tab completion to offer `skill` (and skill names) the same way it offers `rule`/`ruleset`, so that I can discover and select skills without typing them out.

## Use-Case(s)

### Use-Case 1

After typing `ai-rizz add ` or `ai-rizz remove `, tab completion includes `skill` alongside `rule` and `ruleset`.

### Use-Case 2

After typing `ai-rizz add skill ` (or `remove skill `), tab completion lists available skill names from the current project's repository.

## Requirements

1. Fix bash tab completion so skills are completable ([issue #44](https://github.com/Texarkanine/ai-rizz/issues/44)).
2. Preserve existing completion behavior for commands, rules, and rulesets.

## Constraints

1. Change is scoped to bash completion (and its tests); do not expand into unrelated CLI work.
2. Follow project TDD practices: tests first, then implementation.
3. Never test `ai-rizz` commands in the project directory itself.

## Acceptance Criteria

1. `add`/`remove` type completion includes `skill`.
2. After `skill`, available skill names from the project repo complete via tab.
3. Existing rule/ruleset/command completion still works.
4. Automated tests cover the new skill-completion behavior and pass.
