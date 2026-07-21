# Project Brief

## User Story

As an ai-rizz CLI user, I want bash tab completion after `add rule` / `remove rule` to include standalone skill names (directories under `rules/` with `SKILL.md`), so that I can discover and select skills the same way I select rules and commands.

## Use-Case(s)

### Use-Case 1

After typing `ai-rizz add rule ` (or `remove rule `), tab completion lists standalone skill names from the current project's repository alongside existing `.mdc` rules and `.md` commands.

### Use-Case 2

Directories under `rules/` that are not skills (no `SKILL.md`) are not offered as skill completions.

### Use-Case 3

Outside a git repository (global-only context), tab completion after `add rule` lists skills from the global cache (`_ai-rizz.global`), not a stale `repos/$(basename "$PWD")` cache.

## Requirements

1. Fix bash tab completion so standalone skills are completable after `rule` ([issue #44](https://github.com/Texarkanine/ai-rizz/issues/44)).
2. Preserve existing completion behavior for commands, rules, and rulesets.
3. Do not invent an `add skill` / `remove skill` type — skills use `add rule` / `remove rule`.
4. Repo-dir selection for completion mirrors `cmd_list`: project manifests → project cache; otherwise global cache.

## Constraints

1. Change is scoped to bash completion (and its tests); do not expand into unrelated CLI work.
2. Follow project TDD practices: tests first, then implementation.
3. Never test `ai-rizz` commands in the project directory itself.

## Acceptance Criteria

1. After `rule`, available standalone skill names from `rules/<name>/SKILL.md` complete via tab.
2. Existing rule/ruleset/command completion still works.
3. Non-skill directories under `rules/` are not offered as completions solely for being directories.
4. Outside a git repo (and in git repos without project manifests), completion uses the global cache so globally available skills appear.
5. Automated tests cover skill listing and repo-dir selection and pass.
