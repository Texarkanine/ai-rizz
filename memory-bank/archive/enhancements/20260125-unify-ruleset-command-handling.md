# TASK ARCHIVE: Unify Ruleset Command Handling

## METADATA

- **Task ID**: unify-ruleset-command-handling
- **Date Completed**: 2026-01-25
- **Complexity**: Level 2
- **Branch**: `global-and-command-tab-completion`
- **Category**: Enhancement

## SUMMARY

Unified how commands (`.md` files) are discovered and copied from rulesets. Previously, only files in a "magic" `commands/` subdirectory were treated as commands. Now, all non-uppercase `.md` files anywhere in a ruleset are treated as commands, aligning with how standalone commands in `rules/` are handled.

## REQUIREMENTS

**Problem Statement:**
The `commands/` subdirectory in rulesets was a vestigial "magic" concept from when commands could only be added in commit mode. With commands now working in all modes, this special handling was inconsistent.

**Before:**
- `rules/*.md` → commands (worked)
- `rulesets/foo/*.md` → **IGNORED** (inconsistent!)
- `rulesets/foo/commands/*.md` → commands (magic subdir)

**After:**
- `rules/*.md` → commands (unchanged)
- `rulesets/foo/*.md` → commands (new! consistent with rules/)
- `rulesets/foo/commands/*.md` → commands (still works, no longer "magic")

**Design Decisions:**
1. Exclude uppercase `.md` files (e.g., `README.md`) - these are documentation, not commands
2. Copy commands flat (like symlinks), not preserving directory structure
3. Remove dedicated `copy_ruleset_commands`/`remove_ruleset_commands` functions

## IMPLEMENTATION

### Code Changes

1. **`copy_entry_to_target`**: Added `.md` file handling for rulesets
   - Find `*.md` files in ruleset (in addition to `*.mdc`)
   - Exclude uppercase filenames (README.md, CHANGELOG.md, etc.)
   - Copy to commands directory (flat, like symlinks)

2. **Removed `copy_ruleset_commands` and `remove_ruleset_commands`**: No longer needed - unified handling in `copy_entry_to_target`

3. **`sync_manifest_to_directory`**: Migration improvements
   - Added empty directory cleanup
   - Extended flat migration to handle standalone commands (not just ruleset dirs)
   - For `rules/*` manifest entries that are commands, clean up `.cursor/commands/<name>.md`

4. **README.md**: Updated documentation to reflect new behavior

### Technical Improvements

- **Simplified codebase**: Removed ~170 lines of code
- **Consistent behavior**: `.md` files in rulesets now behave identically to `.md` files in `rules/`
- **Flat copy pattern**: Commands are always copied flat (no directory structure preservation)

## TESTING

### TDD Approach
All 9 new test cases were implemented before code changes.

### Test Coverage
- `.md` files in ruleset root treated as commands
- Uppercase `.md` files (README.md) ignored
- `commands/` subdir still works (not special)
- Migration: cleans old `<commands_dir>/<ruleset>/` subdirs
- Migration: cleans old flat standalone commands
- Migration: preserves user-created commands and directories

### Results
All 30/30 tests pass.

## LESSONS LEARNED

1. **Automated tests can't cover all legacy scenarios**: Real-world testing on repos with actual historical structures is invaluable. The migration bug (flat commands at commands root) would have gone unnoticed without testing on an actual legacy repo.

2. **Document historical file layouts explicitly**: When planning migrations, enumerate ALL known historical layouts upfront. Create test cases from actual legacy repo `tree` outputs.

3. **"Surgical" migration is the right pattern**: Only touching managed items (manifest entries) is safer than attempting to migrate everything. Users may have custom files that should be preserved.

4. **Source-based migration works better than target-based**: The fix for the final migration case worked by checking what files exist in the *source* (`rulesets/*/commands/`) rather than trying to guess what might be in the target.

## PROCESS IMPROVEMENTS

1. **Create "legacy repo snapshot" tests**: Before implementing migrations, create test cases that exactly replicate known legacy structures.

2. **Test on real legacy repos before declaring done**: Add a step to test on at least one repo with the old structure before marking migration work complete.

3. **Document migration scenarios in test names**: Test names like `test_sync_cleans_old_flat_commands_from_ruleset` clearly describe the migration scenario.

## FILES CHANGED

- `ai-rizz`: Core implementation (~50 lines modified, ~170 lines removed)
- `tests/unit/test_ruleset_commands.test.sh`: +9 new tests
- `tests/unit/test_cache_isolation.test.sh`: Removed 2 obsolete tests
- `tests/unit/test_ruleset_bug_fixes.test.sh`: Updated 2 tests for flat copy
- `tests/unit/test_ruleset_removal_and_structure.test.sh`: Updated 2 tests for flat copy
- `tests/unit/test_symlink_security.test.sh`: Updated 1 test for .md-only policy
- `README.md`: Updated documentation for new behavior

## REFERENCES

- Reflection: `memory-bank/reflection/reflection-unify-ruleset-command-handling.md`
- Related task: `20260125-global-mode-command-support.md` (same branch)
