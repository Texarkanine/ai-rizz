# Reflection: Global Mode Command Support Bug Fixes (Post Phase 8)

**Task ID**: global-mode-post-phase8-bugs
**Parent Task**: global-mode-command-support
**Date**: 2026-01-25
**Complexity**: Level 2 (Multiple related bug fixes)
**Duration**: ~2 hours
**PR**: https://github.com/Texarkanine/ai-rizz/pull/16

---

## Summary

Fixed multiple related bugs in global mode command support discovered during manual testing:

1. **cmd_list repo dir**: Used `REPO_DIR` instead of `GLOBAL_REPO_DIR` in global-only context
2. **Extensionless add/remove**: `ai-rizz add rule foo` didn't find `foo.md` commands
3. **--global flag for remove**: `cmd_remove_rule` didn't parse `--global` flag
4. **Command file cleanup**: Removing commands left orphan files in commands directory
5. **copy_entry_to_target repo dir**: Used wrong repo dir for global mode sync

---

## Bug 1: cmd_list Repo Dir

**Symptom**: `ai-rizz list` showed "No commands found" in global-only context even when commands existed.

**Root Cause**: `cmd_list` used `${REPO_DIR}` directly in `find` commands. In global-only context, `REPO_DIR` pointed to wrong location.

**Fix**: Add mode-aware repo dir selection - use `GLOBAL_REPO_DIR` when only global mode is active.

---

## Bug 2: Extensionless Add/Remove

**Symptom**: `ai-rizz add rule foo` failed with "Rule not found: rules/foo.mdc" even when `foo.md` existed.

**Root Cause**: When no extension provided, code defaulted to `.mdc` without checking for `.md`.

**Fix**: Try `.mdc` first, fall back to `.md` if not found. Applied to both `cmd_add_rule` and `cmd_remove_rule`.

---

## Bug 3: --global Flag for Remove

**Symptom**: `ai-rizz remove rule foo --global` treated `--global` as a rule name.

**Root Cause**: `cmd_remove_rule` didn't parse flags - just iterated all arguments as rule names.

**Fix**: Add proper argument parsing matching `cmd_add_rule` pattern.

---

## Bug 4: Command File Cleanup

**Symptom**: `ai-rizz remove rule foo` updated manifest but left `~/.cursor/commands/ai-rizz/foo.md` on disk.

**Root Cause**: `sync_manifest_to_directory` only cleared `*.mdc` files, not `*.md` commands.

**Fix**: Also clear the commands directory during sync.

---

## Bug 5: copy_entry_to_target Repo Dir

**Symptom**: Sync warning "Entry not found in repository" for global mode entries.

**Root Cause**: `copy_entry_to_target` used `REPO_DIR` directly instead of mode-specific repo dir.

**Fix**: Use `get_repo_dir_for_mode()` to get correct path.

---

## Debugging Journey (Bug 1)

### Initial Hypothesis (Wrong)
Suspected the `! -name "*.mdc"` filter was too aggressive.

### Investigation with Mermaid Diagram
Drawing sequence diagrams revealed the execution flow and where the bug occurred.

### Discovery 1: CONFIG_DIR Not Updated
`init_global_paths()` didn't update `CONFIG_DIR` when `HOME` changed.

### Discovery 2: Test Infrastructure Override
`tests/common.sh` overrides `get_global_repo_dir()` to return `REPO_DIR`, which masked the real behavior during investigation.

---

## What Went Well

### 1. Mermaid Diagrams Helped
Drawing sequence diagrams revealed execution flow and made issues obvious.

### 2. TDD Caught the Final Bug
Writing tests for extensionless add/remove revealed the command cleanup bug - tests for "remove deletes file" failed, exposing a bug we hadn't noticed yet.

### 3. User-Reported Bugs Led to Complete Fix
Each bug the user reported led to finding related issues. The "extensionless add" request uncovered missing `--global` flag support and the command cleanup bug.

---

## Challenges Encountered

### 1. Test Infrastructure Shadowing Production Code
The `common.sh` override of `get_global_repo_dir()` masked real behavior during investigation.

### 2. Multiple Related Bugs
What seemed like one bug (commands not showing) was actually five related bugs across different code paths.

### 3. Inconsistent Command Handling
Rules and commands had different cleanup logic - rules were deleted on sync, commands weren't.

---

## Lessons Learned

### 1. Test Infrastructure Can Mask Bugs
The `common.sh` override was helpful for most tests but created a blind spot during debugging.

### 2. TDD Reveals Hidden Bugs
Writing tests for one feature (extensionless remove) revealed another bug (command cleanup).

### 3. Commands Need Parity with Rules
Anywhere rules are handled, commands should be too. The sync cleanup only handled `*.mdc`.

### 4. Argument Parsing Must Be Consistent
`cmd_add_rule` had flag parsing, but `cmd_remove_rule` didn't - inconsistency leads to bugs.

---

## Process Improvements

### For New Features

1. **Ensure parity**: When adding command support, audit ALL rule code paths
2. **Test cleanup**: Don't just test add - test remove deletes files too
3. **Consistent interfaces**: If add has `--global`, remove should too

### For Debugging

1. **Draw diagrams** when stuck
2. **Check test infrastructure** when production looks correct
3. **Write regression tests** before considering a bug fixed

---

## Technical Changes Made

| File | Change |
|------|--------|
| `ai-rizz` | `init_global_paths()` - add `CONFIG_DIR` update |
| `ai-rizz` | `cmd_list()` - mode-aware repo dir selection |
| `ai-rizz` | `cmd_add_rule()` - extensionless lookup (.mdc then .md) |
| `ai-rizz` | `cmd_remove_rule()` - add flag parsing, extensionless lookup |
| `ai-rizz` | `copy_entry_to_target()` - use mode-specific repo dir |
| `ai-rizz` | `sync_manifest_to_directory()` - clear commands dir too |
| `test_command_sync.test.sh` | 6 new tests for extensionless and cleanup |
| `test_global_only_context.test.sh` | 1 new test for commands in list |

---

## Metrics

| Metric | Value |
|--------|-------|
| Bugs fixed | 5 |
| Lines changed (ai-rizz) | ~200 |
| Tests added | 7 |
| Time to fix all | ~2 hours |

---

## Conclusion

What started as "commands not showing in list" turned into five related bugs across different code paths. The TDD approach was crucial - writing tests for extensionless remove revealed the command cleanup bug that would have gone unnoticed.

**Key insight**: When adding a new entity type (commands), audit EVERY code path that handles the existing type (rules). Cleanup, sync, add, remove, list - all need updating.
