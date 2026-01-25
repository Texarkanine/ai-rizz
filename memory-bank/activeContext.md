# Memory Bank: Active Context

## Current Focus

**Task**: Phase 8 Bug Fixes
**Phase**: ✅ COMPLETE
**Branch**: `command-support-2`
**PR**: https://github.com/Texarkanine/ai-rizz/pull/15

## Bugs Fixed

### Bug 1: Global Mode Rule Removal (CRITICAL) - ✅ FIXED

Added global mode handling to `cmd_remove_rule()`:
- Added `global)` case in mode-specific handling section
- Added global mode check in mode-agnostic fallback section

### Bug 2: Test Infrastructure - ✅ ALL FIXED

| Test Suite | Status | Fix Applied |
|------------|--------|-------------|
| `test_cache_isolation.test.sh` | ✅ Fixed | Added setUp/tearDown with HOME isolation and separate APP_DIR |
| `test_custom_path_operations.test.sh` | ✅ Fixed | Added HOME isolation, use REPO_DIR for source |
| `test_manifest_format.test.sh` | ✅ Fixed | Added HOME isolation, use REPO_DIR for source |

## Final Test Status

- **Unit Tests**: 23/23 pass
- **Integration Tests**: 7/7 pass
- **Total**: 30/30 pass

## Files Modified

| File | Changes Made |
|------|--------------|
| `ai-rizz` | Added global mode to `cmd_remove_rule()` (~20 lines) |
| `tests/unit/test_cache_isolation.test.sh` | New setUp/tearDown with HOME isolation |
| `tests/unit/test_custom_path_operations.test.sh` | HOME isolation + use REPO_DIR |
| `tests/unit/test_manifest_format.test.sh` | HOME isolation + use REPO_DIR |

## Next Steps

- Commit and push changes
- PR ready for final review
