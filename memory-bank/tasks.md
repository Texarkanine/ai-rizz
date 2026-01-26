# Memory Bank: Tasks

## Current Task

**Task ID**: tab-completion-and-local-commands
**Title**: Tab completion for commands and local mode protection for commands
**Complexity**: Level 2
**Status**: Complete
**Branch**: `global-and-command-tab-completion`

## Description

Two bugs discovered during `ai-rizz add rule` usage:

### Issue 1: Tab Completion Missing Commands
Tab completion only shows `.mdc` files (rules), not `.md` files (commands).
User cannot tab-complete to add commands like `wiggum-niko-coderabbit-pr.md`.

**Root Cause**: `completion.bash` line 80 only searches for `*.mdc`:
```bash
COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rules" -name "*.mdc" -printf "%f\n" | sed 's/\.mdc$//')" -- "${cur}") )
```

### Issue 2: Local Mode Protection Missing for Commands
Neither git exclude NOR hook-based mode properly protects local commands:

**Part A - Regular git exclude**: `setup_local_mode_excludes()` only adds rules dir to `.git/info/exclude`:
- `${LOCAL_MANIFEST_FILE}`
- `${target_dir}/${LOCAL_DIR}` (rules dir)
- **MISSING**: `.cursor/commands/${LOCAL_DIR}` (commands dir)

**Part B - Hook-based mode**: Pre-commit hook only resets rules, not commands:
```sh
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST" 2>/dev/null || true
# MISSING: ".cursor/commands/local/"
```

### Issue 3: Flat Command Structure Migration
Prior versions stored commands flat in `.cursor/commands/`. New subdirectory structure
(`.cursor/commands/{local,shared}/`) causes duplicates (e.g., two "niko" commands).

**Root Cause**: `sync_manifest_to_directory()` only clears subdir commands, not flat ones.

## Implementation Plan

### Test Planning (TDD)
1. Identify existing test coverage
2. Add test for tab completion of commands
3. Add test for git exclude protecting commands
4. Add test for hook-based mode protecting commands

### Code Changes
1. **completion.bash**: Update rule completion to include `*.md` files
2. **ai-rizz `setup_local_mode_excludes`**: Add `.cursor/commands/local/` to git exclude
3. **ai-rizz `remove_local_mode_excludes`**: Remove `.cursor/commands/local/` from git exclude  
4. **ai-rizz `setup_pre_commit_hook`**: Include `.cursor/commands/local/` in hook
5. **ai-rizz `sync_manifest_to_directory`**: Add migration to clean flat command structure

## Definition of Done

- [x] Tab completion includes both `.mdc` and `.md` files
- [x] Git exclude mode protects `.cursor/commands/local/` 
- [x] Hook-based mode unstages `.cursor/commands/local/`
- [x] Sync cleans up flat command structure (migration)
- [x] All new behaviors have tests
- [x] All existing tests pass (30/30)

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
