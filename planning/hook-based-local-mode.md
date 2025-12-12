# Hook-Based Local Mode Implementation

## Problem Statement

Cursor on Mac now ignores ALL files ignored by git (including `.git/info/exclude`), breaking local mode. We need an alternative that:
- Keeps local files visible to Cursor
- Prevents local files from being committed
- Accepts "dirty" git status as trade-off

## Solution: Pre-Commit Hook

Always-run pre-commit hook that unstages local mode files before commit. Hook is harmless if files are already git-ignored (no-op).

## Implementation Plan

### Core Components

1. **Hook Creation Function**
   - Creates/updates `.git/hooks/pre-commit`
   - Appends ai-rizz section to existing hooks (if any)
   - Hook reads manifest to get target directory dynamically

2. **Hook Removal Function**
   - Removes ai-rizz section from pre-commit hook
   - Preserves user's existing hooks

3. **Flag Support & Mode Switching**
   - `--hook-based-ignore` flag in `cmd_init`
   - When set: Skip `.git/info/exclude` setup, create hook
   - Default: Do both (hook is harmless)
   - **Idempotent mode switching:**
     - If already init'd with regular local mode → `init --local --hook-based-ignore` switches to hook-based (removes git exclude, ensures hook)
     - If already init'd with hook-based mode → `init --local` switches back to regular (adds git exclude, removes hook)
     - Critical for users broken by Cursor updates

4. **Deinit Integration**
   - Remove hook section when deinitializing local mode

### Hook Implementation

```bash
#!/bin/sh
# BEGIN ai-rizz hook (do not edit this section manually)
# Find local manifest in repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOCAL_MANIFEST=""
for file in "$REPO_ROOT"/*.local.skbd; do
    [ -f "$file" ] && LOCAL_MANIFEST=$(basename "$file") && break
done
[ -z "$LOCAL_MANIFEST" ] && exit 0

# Parse target directory from manifest
MANIFEST_PATH="$REPO_ROOT/$LOCAL_MANIFEST"
TARGET_DIR=$(head -n1 "$MANIFEST_PATH" 2>/dev/null | cut -f2)
[ -z "$TARGET_DIR" ] && exit 0

# Unstage local files (safe even if already ignored)
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST" 2>/dev/null || true
# END ai-rizz hook
```

**Semaphore comment:** `# BEGIN ai-rizz hook` serves as marker for detection

### Edge Case Handling

- No manifest found: Exit gracefully (not ai-rizz repo or no local mode)
- Bad manifest: Exit gracefully (malformed, shrug)
- Manifest not in root: Exit gracefully (invalid config, shrug)
- No git repo: Hook creation skipped (already handled by existing code)

### Functions to Add/Modify

1. **`setup_pre_commit_hook(target_dir)`**
   - Creates/updates pre-commit hook
   - Appends ai-rizz section with markers (if not already present)
   - Makes hook executable
   - Idempotent: Can be called multiple times safely

2. **`remove_pre_commit_hook()`**
   - Removes ai-rizz section from hook (between BEGIN/END markers)
   - Preserves user hooks outside markers
   - If hook file only contains ai-rizz section, removes entire file

3. **`is_hook_based_mode_active()`**
   - Checks if hook exists and contains "BEGIN ai-rizz hook" marker
   - Returns true/false for validation logic

3. **`cmd_init()` modifications**
   - Parse `--hook-based-ignore` flag
   - **Idempotent mode switching logic:**
     - If local mode already exists:
       - With flag: Remove git exclude entries, ensure hook exists
       - Without flag: Add git exclude entries, hook remains (harmless)
   - Call `setup_pre_commit_hook()` when appropriate
   - Call `setup_local_mode_excludes()` or `remove_local_mode_excludes()` based on flag

4. **`cmd_deinit()` modifications**
   - Call `remove_pre_commit_hook()` when removing local mode

5. **`validate_git_exclude_state()` modifications**
   - Check for hook presence via semaphore comment ("BEGIN ai-rizz hook")
   - If hook exists: Don't warn about missing git exclude entries
   - If hook doesn't exist: Warn if files not in git exclude (existing behavior)

### Testing Requirements

- Hook created on init with `--hook-based-ignore`
- Hook unstages local files when staged
- Hook is no-op when files are git-ignored
- Hook removed on deinit
- Existing user hooks preserved
- Works with custom manifest names
- Works with custom target directories

### Test Compatibility Issues

**Tests that will fail with hook-based mode** (assume local files are git-ignored):
- `test_initialization.test.sh:370-371` - `assert_git_exclude_contains` checks
- `test_cli_init.test.sh:43-44` - `assert_git_excludes` checks  
- `test_deinit_modes.test.sh:104, 118, 124-125` - `assert_git_exclude_contains` checks
- `test_cli_deinit.test.sh:91-92, 322-323` - `assert_git_excludes` checks

**Code that needs updates:**
- `validate_git_exclude_state()` (ai-rizz:803, 806) - Check for hook presence via semaphore comment
  - If hook exists with ai-rizz marker, files don't need to be in git exclude
  - Function's purpose: verify things work as designed
  - Hook presence = working as designed, even if not in git exclude

## Implementation Notes

- Hook always runs (harmless if files ignored)
- No complex edge case handling (graceful exit on errors)
- Accept "dirty" git status as documented limitation
- DRY: Reuse manifest parsing pattern from existing code
- Minimal: Only what's needed, no YAGNI features
- **Critical:** Mode switching must be idempotent to unblock users broken by Cursor updates
- **Semaphore detection:** Use "BEGIN ai-rizz hook" comment to detect hook-based mode

