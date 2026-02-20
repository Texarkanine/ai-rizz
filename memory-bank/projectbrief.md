# Project Brief

## User Story

As an ai-rizz user, I want skills to be fully supported so that I can manage AI skill directories (containing `SKILL.md`) through the same `add`/`remove`/`list`/`sync` workflow as rules, commands, and rulesets — with skills deployed to `.cursor/skills/<mode>/`.

## Requirements

### Skill Detection (`is_skill`)
- `rules/<name>/SKILL.md` → skill (no nesting: `rules/a/b` not a skill)
- `rulesets/skills/<name>/SKILL.md` → skill (top-level magic dir, no nesting)
- `rulesets/<ruleset>/skills/<name>/SKILL.md` → skill inside a ruleset's magic `skills/` subdir
- `rulesets/<name>` as symlink to `rules/<name>` where `SKILL.md` exists → skill
- No other paths are recognized as skills

### Skill Deployment
- Skills are copied as whole directories to `.cursor/skills/<mode>/` via `copy_entry_to_target()`
- Skills inside a ruleset's `skills/` subdirectory are deployed when the ruleset is added/synced
- `cp -rL` used to follow symlinks within the skill directory

### List Display
- Skills displayed in "Available skills:" section
- Each skill shown with trailing `/` suffix: `  ○ niko-refresh/`
- Skills discovered from all four detection paths
- Installation status glyph: `●` committed, `◐` local, `★` global, `○` uninstalled

### Sync Behavior
- Skills directory for the mode is cleared and rebuilt on sync (like commands dir)
- Skills from ruleset `skills/` subdirectory are synced as part of the ruleset sync

### No Changes Needed
- `add rule` / `add ruleset` / `remove rule` / `remove ruleset` CLI surface (manifest entries remain as paths)
- Manifest format (existing entries cover skills via their path)
- Mode logic (local/commit/global)

## Constraints
- POSIX shell, TDD required (tests first), `make test` must pass
- Must not break any existing test
