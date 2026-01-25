# Memory Bank: Active Context

## Current Focus

**Task**: Phase 8 Bug Fixes
**Phase**: 🔴 PLANNING - Ready for Implementation
**Branch**: `command-support-2`
**PR**: https://github.com/Texarkanine/ai-rizz/pull/15

## Bugs to Fix

### Bug 1: Global Mode Rule Removal (CRITICAL)

**Symptom**: 
```
$ ai-rizz add rule java-gradle-tdd --global
Added rule: rules/java-gradle-tdd.mdc

$ ai-rizz list
  ★ java-gradle-tdd.mdc  # Shows as installed

$ ai-rizz remove rule java-gradle-tdd
Warning: Rule not found in any mode: java-gradle-tdd.mdc  # BUG!
```

**Root Cause**: `cmd_remove_rule()` only checks local and commit manifests, never checks `GLOBAL_MANIFEST_FILE`.

**Fix Location**: `ai-rizz` lines ~3751-3810

### Bug 2: Test Infrastructure (3 suites failing)

| Test Suite | Failures | Root Cause |
|------------|----------|------------|
| `test_cache_isolation.test.sh` | 4 | No HOME isolation, global paths point to real HOME |
| `test_custom_path_operations.test.sh` | 9 | No HOME isolation, URL expectation mismatch |
| `test_manifest_format.test.sh` | 1 | No HOME isolation, URL expectation mismatch |

**Common Fix**: Add HOME isolation to each test's setUp(), use consistent repo paths.

## Current Test Status

- **Unit Tests**: 20/23 pass
- **Integration Tests**: 7/7 pass
- **Total**: 27/30 pass

## Implementation Order

1. **Fix `cmd_remove_rule`** (~20 lines)
   - Add global mode case to mode-specific handling
   - Add global mode check to mode-agnostic fallback

2. **Fix `test_cache_isolation.test.sh`** (~30 lines)
   - Replace oneTimeSetUp with proper setUp/tearDown
   - Add HOME isolation

3. **Fix `test_custom_path_operations.test.sh`** (~20 lines)
   - Add HOME isolation to setUp
   - Change URL assertions to use $REPO_DIR

4. **Fix `test_manifest_format.test.sh`** (~10 lines)
   - Add HOME isolation
   - Fix URL assertion

## Key Files

| File | Status | Changes Needed |
|------|--------|----------------|
| `ai-rizz` | Needs fix | Add global to `cmd_remove_rule` |
| `tests/unit/test_cache_isolation.test.sh` | Needs fix | HOME isolation |
| `tests/unit/test_custom_path_operations.test.sh` | Needs fix | HOME isolation + URL fix |
| `tests/unit/test_manifest_format.test.sh` | Needs fix | HOME isolation + URL fix |

## Context from Previous Work

The HOME isolation issue was partially fixed in the previous session:
- `tests/common.sh` `setUp()` now overrides HOME
- `setup_integration_test()` now overrides HOME

But tests with custom `setUp()` functions don't inherit this and need individual fixes.

## Next Steps

Ready for `/niko/build` to implement fixes.

## Blockers

None - plan is complete and ready for implementation.
