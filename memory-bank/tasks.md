# Memory Bank: Tasks

## Current Task: CodeRabbit Feedback Fixes

### Task Overview
Fix five CodeRabbit-identified issues in the ai-rizz codebase:
1. Sync cleanup should also delete stale `.mdc` symlinks (Low Priority)
2. Commands cleanup lifecycle is incomplete (High Priority)
3. `set -e` hazards with `find` in command substitutions (Medium Priority)
4. **CRITICAL**: Symlink security vulnerability in `copy_ruleset_commands()` (CRITICAL)
5. **CRITICAL**: Symlink security vulnerability in `copy_entry_to_target()` (CRITICAL)

### Complexity Level: Level 2
- Multiple related fixes
- Security vulnerabilities require immediate attention
- Some fixes are straightforward, one requires design (Issue 2)

### Creative Phase Status: ✅ Complete

**Creative Phase Document**: `memory-bank/creative/creative-coderabbit-feedback.md`

**Assessment Results**:
- **Issue 1**: ⚠️ Partially Valid - Low Priority - Simple defense-in-depth fix
- **Issue 2**: ✅ Valid - High Priority - Real bug requiring design
- **Issue 3**: ✅ Valid - Medium Priority - Defensive programming improvement
- **Issue 4**: ✅ Valid - **CRITICAL PRIORITY** - Security vulnerability
- **Issue 5**: ✅ Valid - **CRITICAL PRIORITY** - Security vulnerability

---

## Implementation Plan

### Priority Order

1. **Issues 4 & 5 (CRITICAL)** - Security vulnerabilities, must fix first
2. **Issue 2 (High)** - Lifecycle bug, requires design
3. **Issue 3 (Medium)** - Robustness improvement
4. **Issue 1 (Low)** - Defense-in-depth

### Phase 1: CRITICAL Security Fixes (Issues 4 & 5)

#### Requirements
- Validate symlink targets before copying with `cp -L`
- Ensure symlinks point within `REPO_DIR` only
- Skip and warn if symlink points outside repository
- Use existing `_readlink_f()` function for resolution

#### Files to Modify
- `ai-rizz`: `copy_ruleset_commands()` function (line ~3446)
- `ai-rizz`: `copy_entry_to_target()` function (line ~3603)

#### Implementation Steps

**Step 1.1: Fix `copy_ruleset_commands()` (Issue 4)**
- Location: Line ~3445-3449
- Add symlink validation before `cp -L`:
  1. Check if file is symlink: `[ -L "${crc_source_file}" ]`
  2. Resolve target: `crc_resolved_target=$(_readlink_f "${crc_source_file}")`
  3. Validate: Check if `crc_resolved_target` starts with `REPO_DIR`
  4. Skip and warn if outside repository
  5. Only proceed with `cp -L` if validation passes

**Step 1.2: Fix `copy_entry_to_target()` (Issue 5)**
- Location: Line ~3601-3603
- Add symlink validation before `cp -L`:
  1. Check if file is symlink: `[ -L "${cett_rule_file}" ]` (already checked)
  2. Resolve target: `cett_resolved_target=$(_readlink_f "${cett_rule_file}")`
  3. Validate: Check if `cett_resolved_target` starts with `REPO_DIR`
  4. Skip and warn if outside repository
  5. Only proceed with `cp -L` if validation passes

**Step 1.3: Testing**
- Create test cases for malicious symlinks pointing outside `REPO_DIR`
- Verify symlinks are skipped with warning
- Verify valid symlinks (within repo) still work
- Test both functions

#### Success Criteria
- ✅ Symlinks pointing outside `REPO_DIR` are rejected
- ✅ Warning messages are clear and helpful
- ✅ Valid symlinks (within repo) continue to work
- ✅ No regressions in existing functionality
- ✅ All tests pass

---

### Phase 2: High Priority Lifecycle Fix (Issue 2)

#### Requirements
- Track per-ruleset command copies under namespaced subtree
- Enable sync to safely rebuild/clear namespace without touching user commands
- Clean up orphaned commands when rulesets disappear from manifest

#### Design Decision Needed
- **Creative Phase Required**: Namespaced commands approach
- Options to consider:
  1. `.cursor/commands/ai-rizz/<ruleset>/...` - Namespace per ruleset
  2. `.cursor/commands/.ai-rizz/<ruleset>/...` - Hidden namespace
  3. Track mapping file: `.cursor/commands/.ai-rizz-manifest` - Metadata approach

#### Files to Modify
- `ai-rizz`: `copy_ruleset_commands()` - Update target path
- `ai-rizz`: `remove_ruleset_commands()` - Update removal logic
- `ai-rizz`: `sync_manifest_to_directory()` - Add commands cleanup
- `ai-rizz`: `cmd_deinit()` - Clean up commands on deinit

#### Implementation Steps
- **Deferred**: Requires creative phase for design decision
- Will be planned after creative phase completes

---

### Phase 3: Medium Priority Robustness (Issue 3)

#### Requirements
- Make `find` command substitutions resilient to `set -e`
- Prevent script exit on non-critical `find` failures
- Handle permission errors, broken symlinks gracefully

#### Files to Modify
- `ai-rizz`: `cmd_list()` function
  - Line ~2625: `cl_rules=$(find ... | sort 2>/dev/null)`
  - Line ~2651: `cl_rulesets=$(find ... | sort 2>/dev/null)`
  - Line ~2680: `cl_items=$(find ... | sort)`
  - Line ~2705: `cl_cmd_items=$(find ... | sort)`

#### Implementation Steps

**Step 3.1: Fix find command substitutions**
- Add `|| true` or use temporary files pattern
- Pattern: `find ... 2>/dev/null | sort || true`
- Or use temporary file pattern (already used elsewhere in codebase)

**Step 3.2: Testing**
- Test with permission denied scenarios
- Test with broken symlinks
- Verify script doesn't exit unexpectedly

#### Success Criteria
- ✅ Script doesn't exit on non-critical `find` failures
- ✅ Errors are handled gracefully
- ✅ No regressions in list functionality
- ✅ All tests pass

---

### Phase 4: Low Priority Defense-in-Depth (Issue 1)

#### Requirements
- Clean up symlinks in addition to regular files during sync
- Defense-in-depth: handle edge cases even if current code doesn't create symlinks

#### Files to Modify
- `ai-rizz`: `sync_manifest_to_directory()` function (line ~3317)

#### Implementation Steps

**Step 4.1: Update cleanup command**
- Change: `find ... -type f -delete`
- To: `find ... \( -type f -o -type l \) -delete`

**Step 4.2: Testing**
- Verify cleanup still works for regular files
- Verify symlinks are also cleaned up (if present)

#### Success Criteria
- ✅ Both regular files and symlinks are cleaned up
- ✅ No regressions in sync functionality
- ✅ All tests pass

---

## Test Plan

### Security Tests (Phase 1)
1. **Test malicious symlink in commands**: Create ruleset with symlink to `/etc/passwd` → should be rejected
2. **Test malicious symlink in ruleset**: Create ruleset with symlink to `~/.ssh/id_rsa` → should be rejected
3. **Test valid symlink**: Create ruleset with symlink within repo → should work normally
4. **Test relative symlink**: Create relative symlink within repo → should work normally

### Robustness Tests (Phase 3)
1. **Test permission denied**: `find` with no permissions → should not exit script
2. **Test broken symlink**: `find` with broken symlinks → should not exit script
3. **Test normal operation**: Verify list still works correctly

### Lifecycle Tests (Phase 2 - after design)
- TBD based on creative phase design

### Cleanup Tests (Phase 4)
1. **Test symlink cleanup**: Create symlink in target, run sync → should be removed
2. **Test regular file cleanup**: Verify existing behavior still works

---

## Implementation Checklist

### Phase 1: Security Fixes (CRITICAL)
- [ ] Fix `copy_ruleset_commands()` symlink validation
- [ ] Fix `copy_entry_to_target()` symlink validation
- [ ] Write security tests
- [ ] Run all tests
- [ ] Verify no regressions

### Phase 2: Lifecycle Fix (High Priority)
- [ ] Creative phase for namespaced commands design
- [ ] Implement namespaced commands approach
- [ ] Update sync cleanup to handle commands
- [ ] Update deinit to clean commands
- [ ] Write lifecycle tests
- [ ] Run all tests

### Phase 3: Robustness Fix (Medium Priority)
- [ ] Fix `find` command substitutions in `cmd_list()`
- [ ] Write robustness tests
- [ ] Run all tests
- [ ] Verify no regressions

### Phase 4: Defense-in-Depth (Low Priority)
- [ ] Update sync cleanup to delete symlinks
- [ ] Write cleanup tests
- [ ] Run all tests
- [ ] Verify no regressions

---

## Dependencies

- `_readlink_f()` function (already implemented) - Required for Phase 1
- Creative phase design (Issue 2) - Required before Phase 2 implementation

## Time Estimates

- **Phase 1 (Security)**: 1-2 hours (critical, straightforward fix)
- **Phase 2 (Lifecycle)**: 2-4 hours (requires design, more complex)
- **Phase 3 (Robustness)**: 30 minutes - 1 hour (simple fix)
- **Phase 4 (Cleanup)**: 15-30 minutes (trivial fix)

**Total Estimated Time**: 4-8 hours

---

## Planning Status: ✅ Complete

Ready for implementation. Phase 1 (security fixes) should be implemented first.
