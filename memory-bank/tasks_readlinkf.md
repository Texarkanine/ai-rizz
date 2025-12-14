# Memory Bank: Tasks

## Current Task: Portable `_readlink_f()` Function Implementation

### Task Overview
Create a portable `_readlink_f()` function to replace `readlink -f` calls that fail on macOS (BSD readlink doesn't support `-f` flag). This function will provide cross-platform symlink resolution and replace the existing fallback logic in the `is_installed()` function.

**Analysis Result**: After comprehensive codebase search, this is the **only location** with inline `readlink -f` workarounds. The existing fallback logic (lines 2488-2496) also contains a `readlink -f` call that fails on macOS, making the fallback ineffective. No other code locations would benefit from this function.

### Complexity Level: Level 2
- Single utility function addition
- One replacement site (replacing entire fallback block)
- Requires comprehensive testing for portability
- No architectural changes

---

## 1. Scope Determination

### Code Changes Required

1. **New Function**: `_readlink_f()` 
   - Location: Add to utility functions section (after `warn()` function, around line 112)
   - Purpose: Portable symlink resolution that works on both GNU/Linux and macOS/BSD
   - Signature: `_readlink_f(path)` → returns absolute resolved path

2. **Function Replacement** (single replacement):
   - Replace lines 2487-2496 (entire block including fallback) with single call: `_readlink_f "${cl_check_match}"`
   - The existing fallback logic (lines 2488-2496) is ineffective on macOS because it also uses `readlink -f` at line 2494
   - Location: Inside `check_rulesets_for_item()` nested function within `is_installed()`
   - **Note**: This is the only location in the codebase with `readlink -f` workarounds - no other locations need this function

### Behaviors to Test

1. **Absolute symlink resolution**:
   - Symlink pointing to absolute path → returns absolute path
   - Nested symlinks → resolves all levels
   - Symlink chain → resolves to final target

2. **Relative symlink resolution**:
   - Relative symlink → resolves to absolute path
   - Relative symlink with `../` → resolves correctly
   - Relative symlink in subdirectory → resolves relative to symlink location

3. **Edge cases**:
   - Non-existent symlink target → handles gracefully
   - Circular symlinks → detects and handles
   - Regular file (not symlink) → returns absolute path of file
   - Directory symlink → resolves correctly

4. **Cross-platform compatibility**:
   - Works on GNU/Linux (where `readlink -f` exists)
   - Works on macOS/BSD (where `readlink -f` doesn't exist)
   - Works when `readlink -f` is available but fails for other reasons

5. **Integration with existing code**:
   - `is_installed()` function still works correctly
   - Symlink detection in rulesets still functions
   - No regression in existing functionality

### Test Infrastructure Location

- **New Test Suite**: `tests/unit/test_readlink_f.test.sh`
  - Unit tests for the `_readlink_f()` function in isolation
  - Tests all behaviors listed above
  - Uses `source_ai_rizz` to access the function

- **Integration Test**: Add test case to existing `tests/unit/test_rule_management.test.sh`
  - Test that `is_installed()` works with symlinks after replacement
  - Verify no regression in ruleset symlink detection

---

## 2. TDD Implementation Plan

### Phase 1: Preparation (Stubbing)

#### Step 1.1: Stub Test Suite
Create `tests/unit/test_readlink_f.test.sh` with:
- Empty test functions for all behaviors listed above
- Proper test structure (setUp, tearDown, source_ai_rizz)
- Multi-line comments explaining what each test validates
- **DO NOT implement tests yet**

#### Step 1.2: Stub Function Interface
Add `_readlink_f()` function to `ai-rizz`:
- Location: After `warn()` function (around line 112)
- Full function signature with documentation
- Empty implementation (just `return 0` or echo empty string)
- Follow existing function documentation style
- **DO NOT implement logic yet**

#### Step 1.3: Stub Integration Test
Add test case stub to `tests/unit/test_rule_management.test.sh`:
- Empty test function `test_is_installed_with_symlinks_after_readlink_f()`
- Comment explaining it tests integration with `is_installed()`

### Phase 2: Write Tests

#### Step 2.1: Implement Unit Tests
Fill out all test functions in `test_readlink_f.test.sh`:
- `test_readlink_f_absolute_symlink()` - Absolute path resolution
- `test_readlink_f_relative_symlink()` - Relative path resolution  
- `test_readlink_f_nested_symlinks()` - Multi-level resolution
- `test_readlink_f_relative_with_dotdot()` - `../` handling
- `test_readlink_f_regular_file()` - Non-symlink file
- `test_readlink_f_directory_symlink()` - Directory symlink
- `test_readlink_f_circular_symlink()` - Circular reference detection
- `test_readlink_f_nonexistent_target()` - Missing target handling
- `test_readlink_f_works_on_macos()` - macOS compatibility (if testable)

#### Step 2.2: Implement Integration Test
Fill out `test_is_installed_with_symlinks_after_readlink_f()`:
- Create test scenario with symlinks in rulesets
- Verify `is_installed()` correctly detects symlinked rules
- Test both absolute and relative symlinks

#### Step 2.3: Run Tests (Should Fail)
Execute test suite:
```bash
./tests/unit/test_readlink_f.test.sh
```
- All tests should fail (expected - function not implemented)
- Verify test infrastructure works correctly

### Phase 3: Implement Function

#### Step 3.1: Implement `_readlink_f()` Function

**Algorithm**:
1. Try `readlink -f` if available (GNU/Linux)
   - Test with: `readlink -f / >/dev/null 2>&1`
   - If available, use it and return result
2. Fallback to portable method (macOS/BSD):
   - Use `cd` + `readlink` loop to resolve symlinks
   - Handle relative paths by changing to symlink's directory
   - Build absolute path incrementally
   - Detect circular references

**Implementation approach**:
```sh
_readlink_f() {
  _rlf_path="${1}"
  
  # Try GNU readlink -f first (fast path for Linux)
  if readlink -f / >/dev/null 2>&1; then
    _rlf_result=$(readlink -f "${_rlf_path}" 2>/dev/null)
    if [ -n "${_rlf_result}" ]; then
      echo "${_rlf_result}"
      return 0
    fi
  fi
  
  # Portable fallback for macOS/BSD
  # ... cd + readlink loop implementation ...
}
```

#### Step 3.2: Replace Existing Calls
- Replace entire block (lines 2487-2496) with: `cl_check_target=$(_readlink_f "${cl_check_match}")`
- The old fallback logic is removed entirely (it was ineffective on macOS anyway)

#### Step 3.3: Run Tests Iteratively
- Start with first failing test
- Implement minimum code to pass
- Run tests, verify pass
- Move to next test
- Repeat until all tests pass

### Phase 4: Verification

#### Step 4.1: Run Full Test Suite
```bash
make test
```
- Verify no regressions
- All new tests pass
- Existing tests still pass

#### Step 4.2: Manual Testing
- Test on Linux system (if available)
- Test symlink resolution in real scenarios
- Verify `is_installed()` works with various symlink configurations

---

## 3. Implementation Details

### Function Documentation Style
Follow existing pattern from `warn()` function:
- Multi-line comment block
- Globals section
- Arguments section  
- Outputs section
- Returns section

### Function Naming
- Use `_readlink_f` (leading underscore indicates internal utility)
- Matches existing pattern (`_readlink_f` is descriptive)

### Portable Implementation Strategy
1. **Detection**: Test if `readlink -f` works before using it
2. **Fallback**: Use POSIX-compliant `cd` + `readlink` loop
3. **Path Building**: Construct absolute paths manually for relative symlinks
4. **Safety**: Detect and handle circular references

### Error Handling
- Return empty string if path doesn't exist (matches current behavior)
- Handle circular symlinks gracefully
- Don't exit script (use return codes, not exit)

---

## 4. Files to Modify

1. **`ai-rizz`** (main script):
   - Add `_readlink_f()` function (~50-80 lines)
   - Replace 2 instances of `readlink -f` calls
   - Remove fallback logic (lines 2488-2496)

2. **`tests/unit/test_readlink_f.test.sh`** (new file):
   - Complete test suite for `_readlink_f()` function
   - ~200-300 lines of test code

3. **`tests/unit/test_rule_management.test.sh`** (existing):
   - Add one integration test case
   - ~20-30 lines

---

## 5. Success Criteria

✅ All unit tests pass for `_readlink_f()` function
✅ Integration test verifies `is_installed()` works correctly
✅ No regressions in existing test suite
✅ Function works on both GNU/Linux and macOS/BSD
✅ Code follows existing style and documentation patterns
✅ All `readlink -f` instances replaced
✅ Old fallback logic removed

---

## 6. Codebase Analysis Results

**Comprehensive Search Performed**: Searched entire codebase for:
- All `readlink` usage (with and without `-f` flag)
- Manual `cd` + `readlink` patterns
- Other symlink resolution workarounds
- Path resolution patterns that might benefit

**Findings**:
- ✅ **Only one location** uses `readlink -f`: `is_installed()` function (lines 2487-2496)
- ✅ **No other inline workarounds** found in codebase
- ✅ **No other `cd` + `readlink` loops** that would benefit
- ✅ **Other symlink usage** (`cp -L`) is for copying, not path resolution (different use case)

**Conclusion**: This function will be used in exactly one place. The existing fallback logic is ineffective on macOS because it also uses `readlink -f` at line 2494.

## 7. Potential Challenges

1. **Circular symlink detection**: Need to track visited paths
2. **Relative path resolution**: Must handle `../` correctly
3. **Performance**: Portable method may be slower than `readlink -f`
4. **Edge cases**: Non-existent targets, broken symlinks

---

## 8. Creative Phase Decision

**🎨 Creative Phase Completed**: See `memory-bank/creative/creative-readlink_f.md`

**Decision**: Use **readlinkf_posix (Option 4)** - Pure POSIX Implementation
- Adopt the battle-tested `readlinkf_posix` algorithm from the readlinkf project
- **NO GNU `readlink -f` fast path** (violates POSIX compliance)
- Adapt to our naming conventions and interface

**Rationale**:
- ✅ **True POSIX compliance**: Uses only POSIX-specified commands (`cd -P`, `ls -dl`)
- ✅ **Maximum portability**: Works on any POSIX-compliant system
- ✅ **Aligns with project goals**: Script explicitly states "POSIX-compliant shell script"
- ✅ Battle-tested across 9+ shells and 5+ platforms
- ✅ Simple, clean, maintainable (~35 lines)
- ✅ No syntax errors (our implementation is currently broken)
- ✅ CC0 license (public domain, free to use)
- ✅ Fast implementation (minutes vs. hours of debugging)

**Key Insight**: Since the script explicitly states "POSIX-compliant shell script for maximum portability" (line 9), we must use only POSIX-specified commands. GNU `readlink -f` is not POSIX and violates this principle, even as an optimization.

**Trade-off**: Slightly slower performance (parsing `ls -dl` output) in exchange for true POSIX compliance and maximum portability.

---

## 9. Next Steps

After creative phase complete:
1. Proceed to TDD implementation following the 4 phases
2. Use the hybrid approach from creative phase
3. Execute `/build` command to implement

---

## Planning Status: ✅ Complete

## Creative Phase Status: ✅ Complete

## Implementation Status: ✅ Complete

## Reflection Status: ✅ Complete

Reflection document:
- `memory-bank/reflection/reflection-20251213-readlinkf.md`
