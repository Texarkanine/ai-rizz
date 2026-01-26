# Memory Bank: Tasks

## Current Task

**Task ID**: unify-ruleset-command-handling
**Title**: Unify ruleset command handling - remove magic commands/ subdirectory
**Complexity**: Level 2
**Status**: Complete (Reflected)
**Branch**: `global-and-command-tab-completion`

## Description

The `commands/` subdirectory in rulesets is a vestigial "magic" concept from when commands
could only be added in commit mode. Now that commands work in all modes, we should unify
the handling:

**Current behavior:**
- `rules/*.md` → commands (works)
- `rulesets/foo/*.md` → **IGNORED** (inconsistent!)
- `rulesets/foo/commands/*.md` → commands (magic subdir)

**Proposed behavior:**
- `rules/*.md` → commands (unchanged)
- `rulesets/foo/*.md` → commands (new! consistent with rules/)
- `rulesets/foo/commands/*.md` → commands (still works, no longer "magic")

This aligns behavior and removes the special-case `commands/` subdirectory handling.

**Key design decisions:**
1. Exclude uppercase `.md` files (e.g., `README.md`) - these are documentation, not commands
2. Copy commands flat (like symlinks), not preserving directory structure
3. Remove dedicated `copy_ruleset_commands`/`remove_ruleset_commands` functions

## Implementation Plan

### Test Planning (TDD)
1. Add test for `.md` files in ruleset root being treated as commands
2. Add test for uppercase `.md` files (README.md) being ignored
3. Update existing `test_ruleset_commands.test.sh` tests
4. Remove tests for old `commands/` magic behavior
5. Migration tests:
   - Old `<commands_dir>/<ruleset>/` subdir → cleaned up (existing test)
   - Old flat standalone command `.cursor/commands/foo.md` → cleaned up
   - User-created `.cursor/commands/my-personal.md` → NOT touched

### Code Changes
1. **`copy_entry_to_target`**: Add `.md` file handling for rulesets
   - Find `*.md` files in ruleset (in addition to `*.mdc`)
   - Exclude uppercase filenames (README.md, CHANGELOG.md, etc.)
   - Copy to commands directory (flat, like symlinks)
2. **Remove `copy_ruleset_commands`**: No longer needed (handled by unified logic)
3. **Remove `remove_ruleset_commands`**: No longer needed
4. **Update callers**: Remove calls to removed functions
5. **`sync_manifest_to_directory`**: Migration improvements
   - Add empty directory cleanup: `find "${smtd_commands_dir}" -type d -empty -delete`
   - Extend flat migration to handle standalone commands (not just ruleset dirs)
   - For `rules/*` manifest entries that are commands, clean up `.cursor/commands/<name>.md`
6. **README.md**: Update documentation to reflect new behavior

## Definition of Done

- [x] `.md` files in ruleset root are treated as commands
- [x] Uppercase `.md` files (README.md) are ignored
- [x] `commands/` subdir still works (not special, just contains .md files)
- [x] Old `copy_ruleset_commands`/`remove_ruleset_commands` removed
- [x] Migration cleans up old `<commands_dir>/<ruleset>/` subdirs
- [x] Migration cleans up old flat standalone commands (`.cursor/commands/<name>.md`)
- [x] Migration does NOT touch user-created commands
- [x] All tests pass (30/30)
- [x] README updated

---

## Task Template

When starting a new task, populate this section:

```markdown
**Task ID**: <task-id>
**Title**: <task title>
**Complexity**: Level <1-4>
**Status**: <status>
**Branch**: `<branch-name>`

## Description

<task description>

## Implementation Plan

<steps>

## Definition of Done

- [ ] <criteria>
```
