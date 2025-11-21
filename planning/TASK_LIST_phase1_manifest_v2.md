# Task List: Phase 1 - Manifest V2 Support

**Status**: ✅ Complete
**Started**: 2025-11-21
**Completed**: 2025-11-21
**Goal**: Add Manifest V2 support with auto-upgrade for command support

## Overview

Implement V2 manifest format that supports 6 fields (adds cmd_path and cmdset_path).
Current V1 format has 4 fields (source, target, rules_path, rulesets_path).
V2 will have 6 fields (source, target, rules_path, rulesets_path, cmd_path, cmdset_path).

## Tasks

### 1. Determine Scope ✅
- [x] Understand current V1 manifest format (4 fields, 3 tabs)
- [x] Understand target V2 manifest format (6 fields, 5 tabs)
- [x] Identify functions to modify:
  - `parse_manifest_metadata()` - needs V2 detection (5 tabs)
  - `write_manifest_with_entries()` - needs to write 6 fields
- [x] Identify constants to add:
  - `SHARED_COMMANDS_DIR`
  - `DEFAULT_COMMANDS_PATH`
  - `DEFAULT_COMMANDSETS_PATH`
- [x] Identify globals to add:
  - `COMMANDS_PATH`
  - `COMMANDSETS_PATH`
- [x] Identify test file: `tests/unit/test_manifest_format.test.sh`

### 2. Preparation (Stubbing) ✅
- [x] Add new constants to `ai-rizz` script
- [x] Add new globals to `ai-rizz` script
- [x] Stub tests in `test_manifest_format.test.sh`:
  - [x] `test_read_v2_format_manifest` - Read 6-field manifest
  - [x] `test_write_v2_format_manifest` - Write 6-field manifest
  - [x] `test_parse_v2_manifest_metadata` - Parse with COMMANDS_PATH/COMMANDSETS_PATH
  - [x] `test_v1_to_v2_auto_upgrade` - Auto-upgrade on write
- [x] Update function signatures (stubs):
  - [x] `parse_manifest_metadata()` - handle 5-tab case
  - [x] `write_manifest_with_entries()` - accept 6 parameters

### 3. Write Tests ✅
- [x] Implement `test_read_v2_format_manifest`
- [x] Implement `test_write_v2_format_manifest`
- [x] Implement `test_parse_v2_manifest_metadata`
- [x] Implement `test_v1_to_v2_auto_upgrade`
- [x] Update existing tests for V2 format
- [ ] Run tests - verify they pass with implemented code

### 4. Write Code ✅
- [x] Implement V2 detection in `parse_manifest_metadata()`
- [x] Implement V2 writing in `write_manifest_with_entries()`
- [x] Update `remove_manifest_entry_from_file()` to write V2 format
- [x] Update `validate_manifest_integrity()` to allow V1/V2 coexistence
- [x] Update all manifest writing calls to pass 6 fields
- [x] Update test assertions to expect V2 format
- [x] Run tests - all tests pass (16/16)
- [x] Run full test suite - no regressions

## Notes

- V1 format: 3 tabs (4 fields) - `source\ttarget\trules_path\trulesets_path`
- V2 format: 5 tabs (6 fields) - `source\ttarget\trules_path\trulesets_path\tcmd_path\tcmdset_path`
- Auto-upgrade: When writing, always write V2 format
- Backward compat: V1 manifests still readable, use defaults for missing fields

## Progress Log

- 2025-11-21: Started Phase 1 implementation
- 2025-11-21: Completed Phase 1 implementation
  - Added V2 manifest format support (6 fields)
  - Implemented backward compatibility with V1 format (4 fields)
  - Updated all manifest reading/writing functions
  - Fixed manifest integrity validation to allow V1/V2 coexistence
  - Updated all tests to expect V2 format
  - All tests passing (10/10 unit, 6/6 integration)

## Summary

Phase 1 successfully implemented V2 manifest format support with the following changes:

### Code Changes
1. **Constants Added**:
   - `SHARED_COMMANDS_DIR="shared-commands"`
   - `DEFAULT_COMMANDS_PATH="commands"`
   - `DEFAULT_COMMANDSETS_PATH="commandsets"`

2. **Globals Added**:
   - `COMMANDS_PATH=""`
   - `COMMANDSETS_PATH=""`

3. **Functions Updated**:
   - `parse_manifest_metadata()` - Now handles V0 (2 fields), V1 (4 fields), and V2 (6 fields)
   - `write_manifest_with_entries()` - Now writes V2 format (6 fields)
   - `remove_manifest_entry_from_file()` - Now preserves V2 format
   - `validate_manifest_integrity()` - Now compares only critical fields (source/target)
   - `cmd_init()` - Now writes V2 manifests
   - `lazy_init_mode()` - Now writes V2 manifests

### Backward Compatibility
- V0 manifests (2 fields) still readable, use all defaults
- V1 manifests (4 fields) still readable, use default command paths
- V2 manifests (6 fields) fully supported
- Auto-upgrade: All new manifests written as V2 format
- Mixed mode: V1 and V2 manifests can coexist (integrity check relaxed)

### Test Updates
- Updated 4 unit test files to expect V2 format
- Updated 1 integration test file to expect V2 format
- All tests passing: 16/16 (10 unit + 6 integration)

The system is now ready for Phase 2: Command Deployment
