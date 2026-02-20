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
- `commands/` — `.md` files copied flat to `.cursor/commands/<mode>/`
- `skills/` — skill directories (each with `SKILL.md`) copied to `.cursor/skills/<mode>/`

This is analogous to how `commands/` in a ruleset causes its `.md` files to be treated as commands, `skills/` causes its subdirectories to be treated as skills.

## Skill Discovery Paths

Skills can live in four places:
1. `rules/<name>/SKILL.md` — top-level in rules dir, no nesting
2. `rulesets/skills/<name>/SKILL.md` — top-level magic skills dir in rulesets
3. `rulesets/<ruleset>/skills/<name>/SKILL.md` — skills subdir inside a specific ruleset
4. `rulesets/<name>` as symlink → `rules/<name>` — ruleset-level symlink to a skill

Cases 1, 2, 4 are standalone manifest entries. Case 3 is discovered during ruleset deployment.

## POSIX-Compliant Local Variable Prefixes

All functions use a function-specific prefix for local variables to avoid subshell scope issues. Examples:
- `is_skill()` → `is_` prefix
- `get_skills_target_dir()` → `gstd_` prefix
- `cmd_add_rule()` → `car_` prefix
- `copy_entry_to_target()` → `cett_` prefix

## Dual Manifest + Sync Architecture

Adding an item writes to a manifest file only. `sync_all_modes()` then reads manifests and calls `copy_entry_to_target()` for each entry, rebuilding the target directories. This means sync is the single source of truth for what ends up deployed.

Before sync, target directories (rules, commands, skills) for the mode are cleared and rebuilt from scratch.
