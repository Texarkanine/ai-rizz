# System Patterns

## Entity Type Routing

Each entity has a detection function and a target directory getter:
- Rules (`.mdc`) → `is_command()` returns false → `.cursor/rules/<mode>/`
- Commands (`.md`) → `is_command()` returns true → `.cursor/commands/<mode>/`
- Skills (dirs with `SKILL.md`) → `is_skill()` returns true → `.cursor/skills/<mode>/`
- Rulesets (dirs without `SKILL.md`) → iterate → deploy children to above targets

All routing happens in `copy_entry_to_target()`: file vs directory is branched first, then entity-specific logic.

## Magic Subdirectories in Rulesets

Rulesets can have special subdirectories whose contents are routed differently:
- `commands/` — `.md` files copied flat to `.cursor/commands/<mode>/` (actually: all `.md` files anywhere in the ruleset are commands, `commands/` is just organizational convention)
- `skills/` — skill directories (each containing `SKILL.md`) copied to `.cursor/skills/<mode>/`

## Skill Definition Paths

Skills can be defined in exactly two places:
1. `rules/<skill-name>/SKILL.md` — standalone skill, one level only, no nesting
2. `rulesets/<ruleset-name>/skills/<skill-name>/SKILL.md` — embedded in a ruleset's magic `skills/` subdir

Symlinks in rulesets pointing to `rules/<name>/` work the same as for rules (the normal ruleset symlink mechanism). This is not a separate skill detection path.

## POSIX-Compliant Local Variable Prefixes

All functions use a function-specific prefix for local variables to avoid subshell scope issues. Examples:
- `is_command()` → `ic_` prefix
- `cmd_add_rule()` → `car_` prefix
- `copy_entry_to_target()` → `cett_` prefix

## Dual Manifest + Sync Architecture

Adding an item writes to a manifest file only. `sync_all_modes()` then reads manifests and calls `copy_entry_to_target()` for each entry, rebuilding the target directories. This means sync is the single source of truth for what ends up deployed.

Before sync, target directories (rules, commands, skills) for the mode are cleared and rebuilt from scratch.
