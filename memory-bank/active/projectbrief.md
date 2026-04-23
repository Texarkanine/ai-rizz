# Project Brief

## User Story

As an ai-rizz user, I want skills to be fully supported so that I can manage AI skill directories (containing `SKILL.md`) through the same `add`/`remove`/`list`/`sync` workflow as rules, commands, and rulesets — with skills deployed to `.cursor/skills/<mode>/`.

## Requirements

### Skill Detection (`is_skill`)

Only two places skills may be defined:
- `rules/<skill-name>/SKILL.md` — standalone skill (no nesting: `rules/a/b` is not a skill)
- `rulesets/<ruleset-name>/skills/<skill-name>/SKILL.md` — skill inside a ruleset's magic `skills/` subdir

Symlinks inside rulesets may point to `rules/<name>/` directories (same mechanism as rule symlinks), but this is just the normal ruleset symlink pattern — NOT a special skill detection path.

No other paths are recognized as skills. Specifically:
- `rulesets/skills/<name>` is NOT valid (no top-level magic skills dir in rulesets root)
- `rulesets/<name>` as symlink to a skill is NOT valid (skills don't live at top-level of rulesets)

### Skill Deployment
- Skills are copied as whole directories to `.cursor/skills/<mode>/` via `copy_entry_to_target()`
- Standalone skills (`rules/<name>`) are manifest entries — deployed directly when added/synced
- Embedded skills (`rulesets/<r>/skills/<name>`) are deployed as part of their parent ruleset's sync
- `cp -rL` used to follow symlinks within the skill directory

### List Display
- Skills displayed in "Available skills:" section
- Each skill shown with trailing `/` suffix: `  ○ niko-refresh/`
- Skills discovered from both valid paths
- Installation status glyph: `●` committed, `◐` local, `★` global, `○` uninstalled
- Ruleset tree rendering shows `skills/` as a magic subdir with expanded contents (like `commands/`)

### Sync Behavior
- Skills directory for the mode is cleared and rebuilt on sync (like commands dir)
- Embedded skills synced as part of parent ruleset sync

### No Changes Needed
- `add rule` / `add ruleset` / `remove rule` / `remove ruleset` CLI surface
- Manifest format (existing entries cover skills via their path)
- Mode logic (local/commit/global)

## Constraints
- POSIX shell, TDD required (tests first), `make test` must pass
- Must not break any existing test
