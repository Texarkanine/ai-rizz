# Memory Bank: Tasks

## Current Task

**Task ID**: local-mode-default-switch
**Title**: Make Hook-Based Ignore the Default Local Mode
**Complexity**: Level 2
**Status**: Planning Complete
**Branch**: `local-mode-fix`

## Description

Cursor on Windows now ignores files based on git ignored state, not just .gitignore presence. This means the `.git/info/exclude` exclusion technique doesn't work for Cursor users on Windows.

**Required Changes:**
1. Make hook-based-ignore the DEFAULT local ignore mode
2. Allow re-init to convert from .git/info/exclude to hook-based mode
3. Keep .git/info/exclude available behind new `--git-exclude-ignore` flag

## Test Planning (TDD)

### Behaviors to Test

**New Default Behavior:**
- `init --local` (no flag) creates pre-commit hook, NOT git exclude entries
- `init --local` (no flag) on existing git-exclude mode converts to hook-based mode

**New Flag Behavior:**
- `--git-exclude-ignore` flag creates git exclude entries, NOT hook
- `--git-exclude-ignore` flag on existing hook-based mode converts to git-exclude mode

**Backwards Compatibility:**
- `--hook-based-ignore` is accepted but treated as no-op (already default)

**Edge Cases:**
- Re-init detects current mode correctly and performs appropriate conversion
- Help text shows correct flag names

### Test Infrastructure

- **Test framework:** shunit2
- **Test locations:**
  - `tests/unit/test_hook_based_local_mode.test.sh` - Primary test file (needs updates)
  - `tests/unit/test_initialization.test.sh` - General init tests (needs updates)
- **New test files needed:** None (existing files cover the scenarios)

### Tests to Modify

**`test_hook_based_local_mode.test.sh`:**
1. `test_init_local_with_hook_based_ignore_creates_hook` → rename/modify: default behavior now
2. `test_init_local_without_flag_uses_git_exclude` → invert: now uses hook by default
3. `test_switch_from_regular_to_hook_based_mode` → update: use `--git-exclude-ignore` to setup "regular"
4. `test_switch_from_hook_based_to_regular_mode` → update: no flag is hook-based now
5. Add new: `test_git_exclude_ignore_flag_uses_git_exclude`
6. Add new: `test_hook_based_ignore_flag_is_noop`

**`test_initialization.test.sh`:**
1. `test_init_local_mode_only` → update assertions: expects hook, NOT git exclude

## Technology Stack

- Language: POSIX shell (bash features allowed per project rules)
- No new dependencies required

## Implementation Plan

### Phase 1: Update ai-rizz Script (Code Changes)

**Step 1.1: Change default flag value**
- File: `ai-rizz`
- Line ~2491: Change `ci_hook_based=false` to `ci_hook_based=true`

**Step 1.2: Add `--git-exclude-ignore` flag parsing**
- File: `ai-rizz`
- Location: `cmd_init()` argument parsing (after line ~2512)
- Add case for `--git-exclude-ignore` that sets `ci_hook_based=false`

**Step 1.3: Make `--hook-based-ignore` a no-op**
- File: `ai-rizz`
- Line ~2512-2515: Change to do nothing (since hook-based is now default)
- Optionally print deprecation notice

**Step 1.4: Update mode switching logic**
- File: `ai-rizz`
- Lines ~2618-2646: Logic already checks `ci_hook_based` vs `ci_current_hook_based`
- **No changes needed** - the boolean comparisons work correctly

**Step 1.5: Update new local init logic**
- File: `ai-rizz`
- Lines ~2698-2705: Swap the if/else branches
- When `ci_hook_based=true` (default): setup hook
- When `ci_hook_based=false` (--git-exclude-ignore): setup git excludes

**Step 1.6: Update help text**
- File: `ai-rizz`
- Line ~4588: Change `--hook-based-ignore` description to `--git-exclude-ignore`
- Add note that hook-based is now default

### Phase 2: Update Tests

**Step 2.1: Update `test_hook_based_local_mode.test.sh`**
- Rename `test_init_local_without_flag_uses_git_exclude` to `test_init_local_without_flag_uses_hook`
- Update assertions to expect hook, not git exclude
- Add `test_git_exclude_ignore_flag_creates_git_exclude`
- Add `test_hook_based_ignore_flag_is_accepted_as_noop`
- Update mode switching tests to use `--git-exclude-ignore` for git-exclude setup

**Step 2.2: Update `test_initialization.test.sh`**
- `test_init_local_mode_only`: Change assertions from git-exclude to hook expectations

### Phase 3: Verification

**Step 3.1: Run full test suite**
- Command: `make test`

**Step 3.2: Manual verification**
- Test in temporary directory:
  - `ai-rizz init <repo> --local` → verify hook created, no git exclude
  - `ai-rizz init <repo> --local --git-exclude-ignore` → verify git exclude, no hook
  - Re-init scenarios work correctly

## Dependencies

- None (internal changes only)

## Challenges & Mitigations

| Challenge | Mitigation |
|-----------|------------|
| Breaking change for users with existing `--hook-based-ignore` in scripts | Keep flag as accepted no-op |
| Users expecting git-exclude behavior by default | Document in help text that `--git-exclude-ignore` provides old behavior |
| Test updates may miss edge cases | Run full test suite, check all local mode tests |

## Creative Phases Required

None - this is a straightforward flag/default swap with well-defined behavior.

## Definition of Done

- [ ] Hook-based mode is default for `init --local`
- [ ] `--git-exclude-ignore` flag available for legacy behavior
- [ ] `--hook-based-ignore` flag accepted as no-op (backwards compat)
- [ ] Users can run `init --local` to convert existing git-exclude mode to hook-based
- [ ] All existing tests updated for new defaults
- [ ] New tests for `--git-exclude-ignore` flag
- [ ] Help text updated with correct flag names

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
