# Troubleshooting: Initialization Test Failures

**Date**: 2026-01-29
**Issue**: 4 tests failing in test_initialization.test.sh despite assertions appearing to pass
**Context**: Implementing hook-based-ignore as default for local mode
**Status**: RESOLVED

## Problem Description

After implementing changes to make hook-based-ignore the default local mode:
- test_initialization.test.sh reports 4 failures
- However, ASSERT: messages show tests are checking conditions
- test_lazy_init_creates_hook_by_default shows passing assertions but test fails

## Root Cause

**Lazy initialization path was not updated to use hook-based mode by default.**

In `lazy_init_mode()` function (line 1685), when lazy-initializing local mode, the code was still calling `setup_local_mode_excludes()` instead of `setup_pre_commit_hook()`.

The lazy init code path is triggered when:
1. User has commit mode initialized
2. User runs `ai-rizz add rule --local` (local mode doesn't exist yet)
3. ai-rizz lazy-creates local mode

Since we changed the default to hook-based mode, this lazy init path needed to be updated too.

## Solution

Changed `lazy_init_mode()` to use `setup_pre_commit_hook()` instead of `setup_local_mode_excludes()`:

```bash
# Before (git-exclude mode):
setup_local_mode_excludes "${lim_target_dir}"

# After (hook-based mode - new default):
setup_pre_commit_hook "${lim_target_dir}"
```

Also updated integration tests to expect hook-based behavior instead of git-exclude behavior.

## Verification

- All 23 unit tests pass
- All 7 integration tests pass
- Full test suite: `make test` - 30/30 passed
