# Memory Bank: Tasks

## Current Task

**Task ID**: phase-8-bug-fixes
**Title**: Fix remaining bugs from global mode implementation
**Complexity**: Level 2 (Bug fixes with test infrastructure implications)
**Status**: ✅ COMPLETE
**Branch**: `command-support-2`
**PR**: https://github.com/Texarkanine/ai-rizz/pull/15

## Task Summary

Fix three categories of bugs discovered after Phase 7 implementation:
1. Global mode rule removal doesn't work
2. Three unit test suites failing due to test infrastructure issues
3. Integration issues with HOME isolation

---

## Bug 1: Global Mode Rule Removal Broken

**Severity**: Critical (User-facing bug)
**Symptom**: `ai-rizz remove rule <rule>` says "Rule not found in any mode" even when rule is installed in global mode with ★ glyph visible in list.

### Root Cause

`cmd_remove_rule()` only checks local and commit modes, never checks global mode.

**Evidence from code** (lines 3716-3828):
- Lines 3751-3775: Handles mode-specific removal (local/commit only)
- Lines 3776-3810: Handles mode-agnostic removal (checks local then commit)
- **NO CODE** checks `GLOBAL_MANIFEST_FILE` for rule removal

**Contrast with `cmd_remove_ruleset()`** (lines 3829-3884):
- Lines 3863-3873: **DOES** check global mode correctly

### Fix Required

Add global mode check to `cmd_remove_rule()` in two places:
1. Mode-specific handling section (if `crr_mode = "global"`)
2. Mode-agnostic fallback section (check global manifest after local/commit)

---

## Bug 2: Test Infrastructure Issues (3 failing test suites)

### Bug 2a: `test_cache_isolation.test.sh` (4 failures)

**Failing tests**:
- `test_global_repo_dir_set_when_global_active`
- `test_repos_match_different_source`
- `test_add_rule_global_uses_global_repo_dir`

**Root Cause**: The test file uses `oneTimeSetUp()` which calls `source_ai_rizz` but doesn't set up HOME isolation. `GLOBAL_MANIFEST_FILE` points to user's actual `~/ai-rizz.skbd` instead of test directory.

**Fix Required**:
1. Add HOME isolation to `oneTimeSetUp()` or use standard `setUp()`
2. Ensure `GLOBAL_MANIFEST_FILE` points to test directory
3. Clean up global manifest in test teardown

### Bug 2b: `test_custom_path_operations.test.sh` (9 failures)

**Failing tests**: All tests expecting specific source repo URLs

**Root Cause**: Test has its own `setUp()` that:
1. Doesn't call common `setUp()` 
2. Doesn't override HOME (so global mode interferes)
3. Sets `TEST_SOURCE_REPO="https://example.com/repo.git"` but manifest gets actual repo URL

**Evidence from test output**:
```
ASSERT:Should use custom paths in manifest 
expected:<https://example.com/repo.git	.cursor/rules	docs	kb/sections> 
but was:</tmp/tmp.xxx/test_repo	.cursor/rules	docs	kb/sections>
```

The manifest uses the local test repo path, not the URL the test expects.

**Fix Required**:
1. Add HOME isolation to test's `setUp()`
2. Fix the expectation mismatch - either:
   - a) Update test to use actual repo path from `$REPO_DIR`, OR
   - b) Mock `git_sync` to use the test's expected URL

### Bug 2c: `test_manifest_format.test.sh` (1 failure)

**Failing test**: `test_init_with_custom_paths`

**Root Cause**: Same as 2b - expects `https://example.com/repo.git` but gets actual repo path.

**Fix Required**: Same as 2b - add HOME isolation and fix URL expectation.

---

## Implementation Plan

### Phase 8.1: Fix `cmd_remove_rule` for Global Mode

**Changes to `ai-rizz`**:

1. Add global mode to mode-specific handling (~line 3751):
```shell
case "${crr_mode}" in
    local) ...
    commit) ...
    global)  # ADD THIS CASE
        if [ "$(is_mode_active global)" = "true" ]; then
            if read_manifest_entries "$GLOBAL_MANIFEST_FILE" | grep -q "^$rule_path$"; then
                remove_manifest_entry_from_file "$GLOBAL_MANIFEST_FILE" "$rule_path"
                echo "Removed rule: $rule_path"
                removed=true
            else
                warn "Rule not found in global mode: ${crr_item}"
            fi
        fi
        ;;
esac
```

2. Add global mode to mode-agnostic fallback (~line 3800):
```shell
# After checking local and commit...
if [ "$removed" = "false" ] && [ "$(is_mode_active global)" = "true" ]; then
    if read_manifest_entries "$GLOBAL_MANIFEST_FILE" | grep -q "^$rule_path$"; then
        remove_manifest_entry_from_file "$GLOBAL_MANIFEST_FILE" "$rule_path"
        echo "Removed rule: $rule_path"
        removed=true
    fi
fi
```

**Tests**: No new tests needed - existing behavior should now work

---

### Phase 8.2: Fix Test Infrastructure

**Changes to test files**:

#### 8.2.1 `test_cache_isolation.test.sh`

Replace `oneTimeSetUp()` pattern with proper test isolation:

```shell
setUp() {
    # Save and override HOME
    _ORIGINAL_HOME="${HOME}"
    TEST_DIR="$(mktemp -d)"
    HOME="${TEST_DIR}"
    export HOME
    
    cd "${TEST_DIR}" || fail "Failed to cd to test dir"
    
    # Create git repo for tests
    git init . >/dev/null 2>&1
    git config user.email "test@test.com" >/dev/null 2>&1
    git config user.name "Test" >/dev/null 2>&1
    mkdir -p .git/info && touch .git/info/exclude
    echo "test" > README.md
    git add README.md && git commit -m "init" >/dev/null 2>&1
    
    # Source ai-rizz AFTER HOME is set
    source_ai_rizz
    
    # Now GLOBAL_MANIFEST_FILE will be $TEST_DIR/ai-rizz.skbd
}

tearDown() {
    HOME="${_ORIGINAL_HOME}"
    export HOME
    cd / && rm -rf "${TEST_DIR}"
}
```

#### 8.2.2 `test_custom_path_operations.test.sh`

Fix the setUp to:
1. Override HOME for test isolation
2. Use `$REPO_DIR` consistently instead of hardcoded URL

```shell
setUp() {
    # Save and override HOME
    _ORIGINAL_HOME="${HOME}"
    TEST_DIR="$(mktemp -d)"
    HOME="${TEST_DIR}"
    export HOME
    
    cd "$TEST_DIR" || fail "Failed to change to test directory"
    
    source_ai_rizz
    reset_ai_rizz_state
    
    REPO_DIR=$(get_repo_dir)
    mkdir -p "$REPO_DIR"
    # Use REPO_DIR as the source, not a fake URL
    TEST_SOURCE_REPO="$REPO_DIR"
    ...
}
```

Update test assertions to use `$REPO_DIR` instead of `https://example.com/repo.git`:
```shell
assertEquals "Should use custom paths in manifest" \
    "$REPO_DIR	$TEST_TARGET_DIR	docs	kb/sections" "$first_line"
```

#### 8.2.3 `test_manifest_format.test.sh`

Same fix as 8.2.2 - add HOME isolation and use consistent repo paths.

---

### Files to Modify

| File | Changes |
|------|---------|
| `ai-rizz` | Add global mode handling to `cmd_remove_rule()` |
| `tests/unit/test_cache_isolation.test.sh` | Add HOME isolation, proper setUp/tearDown |
| `tests/unit/test_custom_path_operations.test.sh` | Add HOME isolation, fix URL expectations |
| `tests/unit/test_manifest_format.test.sh` | Add HOME isolation, fix URL expectations |

---

### Definition of Done

- [x] `ai-rizz remove rule <rule>` works when rule is in global mode
- [x] All 23 unit tests pass
- [x] All 7 integration tests pass
- [x] Manual testing confirms global add/remove/list cycle works (via test suite)

---

### Test Plan

1. **Manual test for Bug 1**:
```bash
cd /tmp
ai-rizz deinit --global -y 2>/dev/null
ai-rizz init --global
ai-rizz add rule java-gradle-tdd --global
ai-rizz list  # Should show ★ java-gradle-tdd.mdc
ai-rizz remove rule java-gradle-tdd
ai-rizz list  # Should show ○ java-gradle-tdd.mdc
```

2. **Automated tests**:
```bash
make test  # Should be 30/30 (23 unit + 7 integration)
```

---

## Progress Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-25 | Phase 1-7 | COMPLETE | Global mode + command support |
| 2026-01-25 | Phase 8 | COMPLETE | All 4 bugs fixed, 30/30 tests pass |

---

## Previous Task Summary (Phases 1-7)

Completed implementation of:
- Global mode (`--global/-g`)
- Unified command support (commands in all modes)
- Cache isolation (GLOBAL_REPO_DIR separate from REPO_DIR)
- Mode transition warnings
- All 30+ tests passing before recent bug discoveries

See `memory-bank/archive/` for detailed Phase 1-7 documentation once archived.
