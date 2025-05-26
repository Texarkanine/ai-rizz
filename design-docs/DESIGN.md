# AI-Rizz Per-Rule/Ruleset Mode Support - Design Document

## Overview

This document outlines the design for extending ai-rizz to support per-rule and per-ruleset mode selection, moving away from the current repository-wide mode system to a more granular approach with progressive initialization.

## Current State

- **Single mode per repository**: Either all rules are in "local" mode (git-ignored) or "commit" mode (git-tracked)
- **Single manifest**: `ai-rizz.inf` tracks all rules/rulesets
- **Single target directory**: `.cursor/rules/shared/` for all rules
- **Two-state display**: Installed (●) vs Uninstalled (○) glyphs
- **Mode set at init time**: Cannot be changed per rule/ruleset

## Proposed Architecture

### Progressive Mode System

**Core Concept**: "Nothing → Local → Committed" progression with lazy initialization

- **Nothing**: No ai-rizz setup in repository
- **Local Only**: Only `ai-rizz.local.inf` and `.cursor/rules/local/` exist
- **Committed Only**: Only `ai-rizz.inf` and `.cursor/rules/shared/` exist  
- **Dual Mode**: Both modes active (achieved through lazy initialization)

### Manifest System

1. **`ai-rizz.inf`** (committed manifest)
   - Always tracked in git when it exists
   - Contains rules/rulesets intended to be committed
   - Format: `source_repo<tab>target_dir` followed by entries

2. **`ai-rizz.local.inf`** (local manifest)
   - Added to `.git/info/exclude` (git-ignored) when it exists
   - Contains rules/rulesets intended to be local-only
   - Same format as committed manifest

**Key**: It's valid for only one manifest to exist initially; the other will be created via lazy initialization if needed, or explicitly by the user with a 2nd `ai-rizz init` command.

### Directory System

1. **`.cursor/rules/shared/`** (committed directory)
   - Always tracked in git when it exists
   - Contains rules from committed manifest
   - Created when committed mode is initialized

2. **`.cursor/rules/local/`** (local directory)
   - Added to `.git/info/exclude` (git-ignored) when it exists
   - Contains rules from local manifest
   - Created when local mode is initialized

### Three-State Glyph System

1. **○** (Empty circle) - Rule/ruleset not installed in any initialized mode
2. **◐** (Half-filled circle) - Rule/ruleset installed locally only
3. **●** (Filled circle) - Rule/ruleset installed and committed

**Note**: Glyphs remain abstracted as variables for future customization.
**Key**: Glyphs only reflect states that are possible based on initialized modes.

## Command Changes

### `init` Command

**Current behavior**: Sets up repository for single mode
**New behavior**: Initializes ONE mode only, with progressive setup

```bash
ai-rizz init [<source_repo>] [-d <target_dir>] [-l|--local] [-c|--commit]
```

**Changes**:
- **Single mode initialization**: Creates only one manifest and directory structure
- **Mode selection required**: Prompts if no mode flag provided
- **Local mode setup**:
  - Creates `ai-rizz.local.inf` with header
  - Creates `<target_dir>/local/` directory
  - Adds to `.git/info/exclude`: `ai-rizz.local.inf`, `<target_dir>/local`
- **Commit mode setup**:
  - Creates `ai-rizz.inf` with header
  - Creates `<target_dir>/shared/` directory
  - No git exclude changes
- **Target directory**: `-d` specifies BASE directory (default: `.cursor/rules`)

### `add` Command

**Current behavior**: Adds to single manifest based on repository mode
**New behavior**: Mode-aware addition with smart defaults and lazy initialization

```bash
ai-rizz add rule <rule>... [-c|--commit] [-l|--local]
ai-rizz add ruleset <ruleset>... [-c|--commit] [-l|--local]
```

**Changes**:
- **Smart mode selection**: 
  - If only one mode initialized: automatically use that mode
  - If both modes initialized: require mode flag or prompt user
  - If no modes initialized: error with "please run init first"
- **Lazy initialization**: If target mode not initialized, auto-initialize it:
  - Copy `source_repo` and `target_dir` from existing manifest
  - Create missing manifest with header
  - Create missing directory structure
  - Update `.git/info/exclude` if initializing local mode
- **Mode migration**: If rule/ruleset exists in opposite mode, move it
- **Sync after changes**: Always call sync after manifest modifications to handle git tracking changes

### `remove` Command

**Current behavior**: Removes from single manifest
**New behavior**: Simplified removal from initialized modes only

```bash
ai-rizz remove rule <rule>...
ai-rizz remove ruleset <ruleset>...
```

**Changes**:
- **Auto-detection**: Finds and removes from whichever initialized mode contains the rule
- **No mode flags needed**: Rules can only exist in one mode
- **Graceful handling**: Silently ignores non-existent manifests
- **Sync after changes**: Always call sync after manifest modifications to handle git tracking changes

### `list` Command

**Current behavior**: Shows two-state status (installed/uninstalled)
**New behavior**: Shows status based on initialized modes only

**Changes**:
- **Progressive display**: Only shows glyphs for states possible with current initialization
- **Single mode examples**:
  - Local only: Shows ○ (not installed) and ◐ (local)
  - Commit only: Shows ○ (not installed) and ● (committed)
- **Dual mode**: Shows all three states ○, ◐, ●
- **Reads available manifests**: Gracefully handles missing manifests

### `sync` Command

**Current behavior**: Syncs single manifest to single directory
**New behavior**: Syncs all initialized modes

**Changes**:
- **Multi-mode sync**: Syncs each existing manifest to its directory
- **Graceful handling**: Skips non-existent manifests/directories
- **Conflict resolution**: Handles duplicates across modes (committed wins)

### `deinit` Command

**Current behavior**: Removes single manifest and directory
**New behavior**: Mode-selective removal

```bash
ai-rizz deinit [-l|--local] [-c|--commit] [-a|--all]
```

**Changes**:
- **Mode selection required**: Must specify which mode(s) to remove
- **Interactive mode**: If no flag provided, prompt for local/commit/all
- **Selective cleanup**: Only removes specified mode's files and git exclude entries
- **All mode**: `-a/--all` removes both modes completely

## Lazy Initialization Logic

### Trigger Conditions
- User runs `add` command targeting non-initialized mode
- At least one mode is already initialized

### Initialization Process
1. **Detect existing mode**: Read existing manifest for metadata
2. **Copy metadata**: Use same `source_repo` and `target_dir`
3. **Create missing manifest**: Write header with copied metadata
4. **Create directory structure**: Set up target mode's directory
5. **Update git excludes**: If initializing local mode
6. **Proceed with add**: Continue with original add operation

### Example Scenarios

**Scenario 1**: Local-only repo, user adds committed rule
```bash
# Starting state: only ai-rizz.local.inf exists
ai-rizz add rule my-rule --commit
# Result: ai-rizz.inf created, .cursor/rules/shared/ created, rule added to commit mode
# Output: "Added rule: rules/my-rule.mdc"
```

**Scenario 2**: Commit-only repo, user adds local rule
```bash
# Starting state: only ai-rizz.inf exists  
ai-rizz add rule my-rule --local
# Result: ai-rizz.local.inf created, .cursor/rules/local/ created, git excludes updated
# Output: "Added rule: rules/my-rule.mdc"
```

## Conflict Resolution

### Rule/Ruleset Mode Conflicts

**Scenario**: Rule/ruleset exists in one mode, user adds it in different mode
**Resolution**: Move the rule/ruleset to the new mode

**Process**:
1. Remove from current manifest
2. Add to target manifest  
3. **Immediately sync** to move files between directories and update git tracking
4. For rulesets: All constituent rules move together

**Critical**: Sync must occur after any manifest modification to ensure git tracking changes are applied immediately.

### Duplicate Entries (Manual Editing Recovery)

**Scenario**: Rule/ruleset exists in both manifests (due to manual editing)
**Resolution**: Committed mode takes precedence, local entry silently removed

**Process**:
1. During sync, detect duplicates
2. **Silently** remove from local manifest
3. Keep in committed manifest
4. Move file from local to shared directory (if needed)
5. **No warning** - automatic cleanup of user error

## Backward Compatibility

### Existing Repositories

**Challenge**: Existing repos have single manifest and may be in either mode
**Solution**: Automatic migration on first command execution

#### Migration Process for Local-Mode Repositories

**Detection**: `.git/info/exclude` contains `ai-rizz.inf` entry (guaranteed detection of old-style local mode)

**Migration Steps**:
1. Rename `ai-rizz.inf` → `ai-rizz.local.inf`
2. Move rules from `<target_dir>/shared/` → `<target_dir>/local/`
3. Remove empty `<target_dir>/shared/` directory
4. Update `.git/info/exclude` entries:
   - Remove old `<target_dir>/shared` entry
   - Remove `ai-rizz.inf` entry
   - Add `ai-rizz.local.inf` entry  
   - Add `<target_dir>/local` entry
5. **No committed manifest created** - remains local-only

#### Migration Process for Commit-Mode Repositories

**Detection**: `.git/info/exclude` does NOT contain `ai-rizz.inf` entry

**Migration Steps**:
1. Keep `ai-rizz.inf` as-is (already correct)
2. **No local manifest created** - remains commit-only
3. **No local directory created** - remains commit-only
4. **No git exclude changes** - remains commit-only

**Key**: Backward compatibility preserves single-mode setup; dual-mode only via lazy initialization.

## Implementation Phases

### Phase 0: Documentation Update
- [x] **README rewrite**: Document new progressive initialization behavior
- [x] **HUMAN REVIEW CHECKPOINT**: Approve README before test development

### Phase 1: Unit Test Development
- [x] **HUMAN REVIEW CHECKPOINT**: Draft comprehensive unit tests based on README
- [x] Write unit tests for progressive initialization  
- [x] Write unit tests for lazy initialization logic
- [x] Write unit tests for smart mode selection in add operations
- [x] Write unit tests for sync-after-modification behavior
- [x] Write unit tests for migration scenarios
- [x] **Expected**: Tests FAIL against current system
- [x] **Required**: Human approval before implementation begins

### Phase 2: Core Infrastructure ✅ COMPLETED
- [x] Mode detection utilities
- [x] Lazy initialization logic
- [x] Progressive manifest handling
- [x] Mode-selective git exclude management
- [x] Enhanced `sync` command for multi-mode
- [x] Backward compatibility migration

**Phase 2 Implementation Notes**:
- ✅ All core infrastructure successfully implemented
- ✅ Progressive initialization working (Nothing → Local/Commit → Dual)
- ✅ Lazy initialization triggers correctly when adding to uninitialized mode
- ✅ Migration from legacy single-mode repositories working
- ✅ Test suite shows significant progress (1/8 → improved error patterns)
- ✅ Mode detection and caching system robust and efficient

### Phase 3: Command Updates ✅ COMPLETED
- [x] Update `init` command for single-mode setup
- [x] Update `add` commands with lazy initialization
- [x] Update `remove` commands for mode detection
- [x] Update `list` command for progressive display
- [x] Update `deinit` command for mode selection

**Phase 3 Status**: ✅ **COMPLETED** - All command updates and test fixes implemented:
- ✅ **Test Suite Issues**: All timeout and interactive prompt issues resolved
- ✅ **Test Argument Updates**: All tests updated with proper `-d` and `-y` flags
- ✅ **Confirmation Prompts**: Interactive prompts eliminated from test execution
- ✅ **Command Logic**: All command logic correctly implemented and working
- ✅ **Progressive Behavior**: Commands correctly handle single-mode, dual-mode, and lazy initialization
- ✅ **Core Migration Logic**: Variable name collision bug identified and fixed
- ✅ **Test Infrastructure**: Proper test isolation and state cleanup implemented
- ✅ **Debug Cleanup**: All temporary debug scripts removed from test suite

**Phase 3 Achievements**:
- [x] Fix remaining test argument issues (add missing `-d` and `-y` flags)
- [x] Verify all test scenarios pass with updated command interfaces  
- [x] Validate edge cases and error handling in test suite
- [x] Resolve core migration logic failures
- [x] Clean up debug artifacts and maintain canonical test suite

### Phase 4: Advanced Features ✅ **COMPLETED**
- [x] **Conflict resolution logic** ✅ COMPLETED
- [x] **Repository isolation fixes** ✅ COMPLETED  
- [x] **Code cleanup and simplification** ✅ COMPLETED
- [x] **Error handling improvements** ✅ COMPLETED (17/17 tests passing)
- [x] **Mode operations fixes** ✅ COMPLETED (16/16 tests passing)
- [x] **Upgrade/downgrade constraints** ✅ COMPLETED
- [x] **Comprehensive test coverage** ✅ COMPLETED
- [x] **File-level conflict resolution** ✅ COMPLETED (Phase 4.7)

**Phase 4 Status**: ✅ **COMPLETELY FINISHED** - All objectives achieved:
- ✅ **Conflict Resolution**: Sophisticated file-level conflict resolution with partial ruleset handling
- ✅ **Upgrade/Downgrade Constraints**: Individual rules correctly prevented from downgrading from committed rulesets
- ✅ **Repository Isolation**: Fixed by using `${REPO_DIR}` directly instead of function calls
- ✅ **Code Quality**: Simplified architecture and improved maintainability
- ✅ **Error Handling**: Comprehensive validation and error recovery (17/17 tests passing)
- ✅ **Mode Operations**: All command interactions working correctly (16/16 tests passing)
- ✅ **Conflict Resolution**: All complex scenarios working correctly (10/10 tests passing)
- 📊 **Success Rate**: 8/8 test suites passing completely (100% success rate)

### Phase 5: Polish & Testing
- [ ] Update help text and usage documentation
- [ ] Error handling improvements
- [ ] **README update**
- [ ] in-script Documentation updates

### Phase 6: Integration Testing

- [ ] integration tests of the user-facing commands

## Data Structures

### Architecture Principles

- **Read-only Globals**: Global variables are set once during initialization and read-only afterward
- **No Global State Pollution**: Functions return data via stdout/return codes, not by setting global variables
- **Clean Function Interfaces**: Functions have clear inputs/outputs without side effects on global state

### Global Variables (New/Modified)

```bash
# Manifest files
COMMIT_MANIFEST_FILE="ai-rizz.inf"
LOCAL_MANIFEST_FILE="ai-rizz.local.inf"

# Directory structure
SHARED_DIR="shared"
LOCAL_DIR="local"

# Status tracking (cached during initialization, read-only afterward)
COMMIT_SOURCE_REPO=""
LOCAL_SOURCE_REPO=""
COMMIT_TARGET_DIR=""
LOCAL_TARGET_DIR=""

# Mode state
HAS_COMMIT_MODE=false
HAS_LOCAL_MODE=false

# Glyphs (abstracted for customization)
COMMITTED_GLYPH="●"      # Committed
LOCAL_GLYPH="◐"          # Local only
UNINSTALLED_GLYPH="○"    # Not installed
```

### Utility Functions (New/Modified)

```bash
# Detect which modes are initialized
detect_initialized_modes()

# Cache manifest metadata (replaces read_available_manifests)
cache_manifest_metadata()

# Lazy initialize missing mode
lazy_init_mode()

# Mode-aware manifest operations (return data via stdout, not globals)
read_manifest_metadata()        # Returns "source_repo\ttarget_dir" via stdout
read_manifest_entries()         # Returns entries via stdout, one per line  
write_manifest_with_entries()   # Writes metadata + entries from stdin
add_manifest_entry()            # Adds single entry to manifest file
remove_manifest_entry()         # Removes single entry from manifest file

# Get rule/ruleset status based on available modes (Phase 3)
get_install_status()

# Move rule/ruleset between modes (Phase 3)
migrate_rule_mode()

# Detect and resolve conflicts (Phase 3)
resolve_conflicts()

# Detect legacy repository and migrate
migrate_legacy_repository()

# Check if repository needs migration
needs_migration()
```

## Error Handling

### No Manifests Exist
```bash
ai-rizz add rule my-rule --local
# Error: No ai-rizz configuration found. Please run 'ai-rizz init' first.
# 
# Usage: ai-rizz init [<source_repo>] [-d <target_dir>] [-l|--local] [-c|--commit]
```

### Mode Not Initialized (Lazy Init Triggered)
```bash
# Commit mode exists, user adds local rule
ai-rizz add rule my-rule --local
# Result: Local mode auto-initialized, rule added
# Output: "Added rule: rules/my-rule.mdc"
```

## User Output Principles

**Core Principle**: Output should only confirm the user's explicit request, not document internal operations.

**Examples**:
- ✅ `"Added rule: rules/my-rule.mdc"` - confirms the requested action
- ✅ `"Removed rule: rules/my-rule.mdc"` - confirms the requested action  
- ❌ `"Local mode initialized. Added rule: rules/my-rule.mdc"` - documents internal mechanics
- ❌ `"Migrating rule from local to commit mode..."` - documents internal mechanics

**Exceptions**: Only show internal operations when they represent user-facing problems or require user decisions:
- Error conditions that block the request
- Conflicts requiring user input
- Warnings about destructive operations

## Testing Strategy

### Unit Test Requirements

**Critical**: Unit tests must be written and human-approved BEFORE implementation begins.

#### Test Files Structure
```
tests/
├── unit/
│   ├── test_progressive_init.sh        # Single-mode initialization
│   ├── test_lazy_initialization.sh     # Auto-mode-creation logic
│   ├── test_mode_detection.sh          # Mode state detection
│   ├── test_mode_operations.sh         # Add/remove with mode detection
│   ├── test_conflict_resolution.sh     # Conflict resolution algorithms  
│   ├── test_migration.sh               # Legacy repository migration
│   └── test_error_handling.sh          # Error cases and edge conditions
└── integration/
    ├── test_complete_workflows.sh      # End-to-end scenarios
    ├── test_backward_compat.sh         # Migration scenarios
    └── test_progressive_usage.sh       # Local → dual → commit workflows
```

#### Unit Test Expectations
- Tests should cover progressive initialization thoroughly
- Tests should verify lazy initialization in both directions
- Tests will FAIL against the current system (this is expected)
- Tests define the contract for the new system
- Human review and approval required before implementation

## Resolved Design Questions

1. **Init default mode**: ✅ Prompts if no mode flag provided (maintains current UX)

2. **Lazy initialization**: ✅ Copy source_repo and target_dir from existing manifest

3. **Deinit behavior**: ✅ Requires mode selection, can choose local/commit/all

4. **No manifests error**: ✅ Same as current - error with init help message

5. **Glyph display**: ✅ Only show states possible with initialized modes

6. **Progressive initialization**: ✅ Nothing → local/commit → dual via lazy init

## Future Considerations

### Potential Enhancements
- Rule-level metadata (version, last-updated, etc.)
- Dependency tracking between rules
- Bulk operations (add multiple rules with different modes)
- Configuration profiles (predefined rule/mode combinations)

### Performance Optimizations
- Lazy manifest loading (only read when needed)
- Incremental sync (only update changed rules)
- Parallel operations for large rulesets

---

**Implementation Status**: 
1. ✅ Design validated with progressive initialization approach
2. ✅ **PHASE 0**: README rewrite completed and approved
3. ✅ **PHASE 1**: Comprehensive unit tests drafted and approved
4. ✅ **PHASE 2**: Core infrastructure implementation completed
5. ✅ **PHASE 3**: Command updates and test fixes completed
6. ✅ **PHASE 4**: Advanced features completely finished - all objectives achieved
7. ✅ **PHASE 4.7**: Final test resolution completed (8/8 test suites passing, 100% success rate)
8. **CURRENT**: Phase 4 completely delivered - ready for Phase 5
9. **NEXT**: Phase 5 (Polish & Testing) - documentation updates and final integration testing

**Key Achievements**:
- ✅ **Progressive Mode System**: Nothing → Local/Commit → Dual mode progression working
- ✅ **Conflict Resolution**: Sophisticated file-level conflict resolution with partial ruleset handling
- ✅ **Upgrade/Downgrade Constraints**: Correct prevention of invalid rule movements
- ✅ **Lazy Initialization**: Automatic mode creation when needed
- ✅ **Backward Compatibility**: Seamless migration from legacy single-mode repositories
- ✅ **Test Coverage**: Comprehensive test suite with 100% pass rate 