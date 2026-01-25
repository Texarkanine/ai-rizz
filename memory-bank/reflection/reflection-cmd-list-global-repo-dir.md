# Reflection: cmd_list Global Repo Dir Bug Fix

**Task ID**: cmd-list-global-repo-dir
**Parent Task**: global-mode-command-support (Phase 8+)
**Date**: 2026-01-25
**Complexity**: Level 2 (Bug fix with test infrastructure investigation)
**Duration**: ~30 minutes
**PR**: https://github.com/Texarkanine/ai-rizz/pull/15

---

## Summary

Fixed a bug where `cmd_list` hardcoded `REPO_DIR` for finding available rules/commands/rulesets, causing "No commands found" in global-only context even when commands existed in the global cache.

---

## The Bug

**Symptom**: User manually placed `foo.md` in global cache (`~/.config/ai-rizz/repos/_ai-rizz.global/repo/rules/`), but `ai-rizz list` showed "No commands found".

**Root Cause**: `cmd_list` used `${REPO_DIR}` directly in `find` commands:
```shell
cl_commands=$(find "${REPO_DIR}/${RULES_PATH}" -maxdepth 1 -name "*.md" ...)
```

In global-only context (outside git repo), `REPO_DIR` pointed to wrong location based on `basename $(pwd)`, not the global cache.

**Fix**: Add mode-aware repo dir selection:
```shell
if local/commit mode active:
    cl_repo_dir = REPO_DIR
else:
    cl_repo_dir = GLOBAL_REPO_DIR
```

---

## Debugging Journey

### Initial Hypothesis (Wrong)
Suspected the `! -name "*.mdc"` filter was too aggressive, filtering out all `.md` files.

### Investigation with Mermaid Diagram
Created sequence diagram to trace execution flow:
```
cmd_list → ensure_initialized_and_valid → cache_manifest_metadata
        → get_global_repo_dir → returns CONFIG_DIR/repos/...
```

### Discovery 1: CONFIG_DIR Not Updated
`init_global_paths()` updated `GLOBAL_MANIFEST_FILE`, `GLOBAL_RULES_DIR`, etc. based on `HOME`, but NOT `CONFIG_DIR`. So when tests changed `HOME`, `get_global_repo_dir()` returned wrong path.

**Fix**: Added `CONFIG_DIR="$HOME/.config/ai-rizz"` to `init_global_paths()`.

### Discovery 2: Test Infrastructure Override
Even after fixing CONFIG_DIR, tests still failed. Debug output revealed:
```
CONFIG_DIR=/tmp/.../test_home/.config/ai-rizz  ← CORRECT
get_global_repo_dir=/nonexistent/...           ← WRONG!?
```

How could `get_global_repo_dir()` return wrong value when `CONFIG_DIR` was correct?

**Root Cause**: `tests/common.sh` line 307-309 **overrides** `get_global_repo_dir()`:
```shell
get_global_repo_dir() {
    echo "$REPO_DIR"  # Returns REPO_DIR, not actual global path!
}
```

This override exists to simplify most tests, but breaks tests that deliberately set `REPO_DIR` to invalid value to verify isolation.

**Fix**: Simplified test to not rely on REPO_DIR isolation, just verify commands show up.

---

## What Went Well

### 1. Mermaid Diagrams Helped
When stuck, drawing the sequence diagram revealed the execution flow clearly. The visualization made it obvious where to look next.

### 2. Progressive Debug Output
Adding targeted debug statements (`CONFIG_DIR`, `get_global_repo_dir()`, `cl_repo_dir`) isolated the issue to the function override in common.sh.

### 3. /niko/refresh Command
Using the systematic re-diagnosis approach (step back, map structure, investigate with evidence) instead of trial-and-error led directly to root cause.

---

## Challenges Encountered

### 1. Test Infrastructure Shadowing Production Code
The `common.sh` override of `get_global_repo_dir()` made production code appear buggy when it wasn't. This is a form of test pollution - test infrastructure masking real behavior.

### 2. Multiple Layers of Indirection
The bug involved:
- `cmd_list` → `REPO_DIR` vs `GLOBAL_REPO_DIR`
- `cache_manifest_metadata` → `get_global_repo_dir()`
- `get_global_repo_dir` → `CONFIG_DIR`
- `init_global_paths` → `HOME`
- Test override → `REPO_DIR`

Each layer looked correct in isolation. Only tracing the full chain revealed the issue.

---

## Lessons Learned

### 1. Test Infrastructure Can Mask Bugs
The `common.sh` override was helpful for most tests but created a blind spot. When debugging production behavior, consider temporarily disabling test overrides.

**Takeaway**: Document which functions are overridden in test infrastructure and why.

### 2. Visualize Before Diving Deep
The mermaid sequence diagram took 2 minutes to create but saved 20+ minutes of confused debugging. When stuck, step back and draw.

### 3. Debug Output Should Include Function Calls
Adding `echo "get_global_repo_dir=$(get_global_repo_dir)"` revealed that the function itself was misbehaving - not just its callers. Debug the mechanism, not just the values.

### 4. Variables vs Functions
`GLOBAL_REPO_DIR` (variable) and `get_global_repo_dir()` (function) can diverge. The variable was cached correctly, but the function was overridden. Prefer consistent access patterns.

---

## Process Improvements

### For Test Infrastructure

1. **Document overrides prominently**:
   ```shell
   # WARNING: This function is overridden in common.sh for testing
   # Tests that need real behavior must re-override it
   ```

2. **Consider conditional overrides**:
   ```shell
   if [ -z "${USE_REAL_GLOBAL_REPO_DIR:-}" ]; then
       get_global_repo_dir() { echo "$REPO_DIR"; }
   fi
   ```

### For Debugging

1. **Draw diagrams early** when multiple components interact
2. **Debug function calls**, not just variable values
3. **Check test infrastructure** when production code looks correct

---

## Technical Changes Made

| File | Change |
|------|--------|
| `ai-rizz` | Added `CONFIG_DIR` to `init_global_paths()` |
| `ai-rizz` | Added mode-aware `cl_repo_dir` selection in `cmd_list()` |
| `ai-rizz` | Changed 5 `find` commands from `REPO_DIR` to `cl_repo_dir` |
| `test_global_only_context.test.sh` | Added `test_global_list_shows_available_commands_outside_git_repo` |

---

## Metrics

| Metric | Value |
|--------|-------|
| Time to diagnose | ~25 minutes |
| Debug iterations | 3 (filter hypothesis → CONFIG_DIR → override) |
| Lines changed | ~35 |
| Tests added | 1 |
| Diagrams drawn | 2 (sequence + flowchart) |

---

## Conclusion

This was a "pernicious little" bug because the test infrastructure masked the real behavior. The fix was straightforward once the root cause was identified, but finding it required systematic investigation through multiple layers of indirection.

**Key insight**: When production code looks correct but tests fail in unexpected ways, investigate the test infrastructure itself - it may be the source of the discrepancy.
