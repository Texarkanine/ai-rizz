# Implementation Phase 4.5: Repository Isolation Fix

## Problem Statement

**Critical Issue**: All ai-rizz instances share the same `~/.config/ai-rizz/repo` directory, causing:

1. **Test Contamination**: Test artifacts (like `rule1.mdc`) leak into production environment
2. **Multi-Project Conflicts**: Different projects can't use different source repositories
3. **Mode Conflicts**: Local and commit modes can't use different source repositories
4. **Concurrent Usage**: Can't work on multiple projects simultaneously

## Solution Overview

Implement **per-project, per-mode repository isolation** using directory structure:
```
~/.config/ai-rizz/repos/
├── project-name/
│   ├── local/          # Local mode's repo clone
│   └── commit/         # Commit mode's repo clone
└── another-project/
    ├── local/
    └── commit/
```

Where `project-name` is derived from `basename "$(pwd)"`.

## Implementation Strategy

### Phase 1: Core Repository Path Logic
**Goal**: Minimal changes to make `REPO_DIR` dynamic based on project and mode

### Phase 2: Update git_sync Function  
**Goal**: Clone/update repositories in the correct per-project, per-mode directories

### Phase 3: Test Infrastructure Updates
**Goal**: Ensure all tests use isolated environments and don't contaminate production

### Phase 4: Documentation Updates
**Goal**: Update README and bash completion to reflect new directory structure

## Detailed Implementation Plan

### 1. Core Changes (ai-rizz script)

#### 1.1 Replace Static REPO_DIR
**File**: `ai-rizz`
**Lines**: 12
**Change**: Replace static `REPO_DIR="$CONFIG_DIR/repo"` with dynamic function

```bash
# OLD:
REPO_DIR="$CONFIG_DIR/repo"

# NEW:
# Remove static REPO_DIR, add function:
get_repo_dir() {
    mode="$1"  # "local" or "commit"
    project_name=$(basename "$(pwd)")
    echo "$CONFIG_DIR/repos/$project_name/$mode"
}
```

#### 1.2 Update All REPO_DIR Usage
**Files**: `ai-rizz`
**Lines**: 588, 620, 653, 676, 1100, 1134, 1160, 1279, 1412, 1627

**Strategy**: Replace `$REPO_DIR` with `$(get_repo_dir "$current_mode")` where `$current_mode` is determined by context.

**Context Analysis**:
- **Conflict resolution functions**: Need to handle both modes
- **List command**: Use any available mode (prefer commit, fallback to local)
- **Add/remove commands**: Use the target mode being operated on
- **Sync functions**: Use the mode being synced

#### 1.3 Update git_sync Function
**File**: `ai-rizz`
**Function**: `git_sync`

```bash
# OLD:
git_sync() {
  repo_url="$1"
  
  # Ensure config directory exists
  mkdir -p "$CONFIG_DIR"
  
  # Clone/update permanent repository
  if [ ! -d "$CONFIG_DIR/repo" ]; then
    git clone "$repo_url" "$CONFIG_DIR/repo" || error "Failed to clone repository: $repo_url"
  else
    (cd "$CONFIG_DIR/repo" && git pull) || error "Failed to update repository: $repo_url"
  fi
  
  return 0
}

# NEW:
git_sync() {
  repo_url="$1"
  mode="$2"  # "local" or "commit"
  
  repo_dir=$(get_repo_dir "$mode")
  
  # Ensure config directory exists
  mkdir -p "$(dirname "$repo_dir")"
  
  # Clone/update mode-specific repository
  if [ ! -d "$repo_dir" ]; then
    git clone "$repo_url" "$repo_dir" || error "Failed to clone repository: $repo_url"
  else
    (cd "$repo_dir" && git pull) || error "Failed to update repository: $repo_url"
  fi
  
  return 0
}
```

#### 1.4 Update All git_sync Calls
**Strategy**: Add mode parameter to all `git_sync` calls based on context. Entry-point `cmd_sync` will sync both modes by calling `git_sync` for each available mode.

**Key Changes**:
- `cmd_sync`: Call `git_sync` for both modes if available
- Mode-specific commands: Call `git_sync` with appropriate mode
- Use curly braces for all variable expansions: `"${current_mode}"`, `$(get_repo_dir "${mode}")`, etc.

### 2. Function-by-Function Updates

#### 2.1 Conflict Resolution Functions
**Functions**: `get_files_from_manifest`, `remove_local_entries_deploying_file`, `restore_non_conflicting_rules_from_ruleset`

**Strategy**: These functions need to work with both modes, so they need to determine the appropriate `REPO_DIR` based on the manifest file being processed.

**New Helper Function**:
```bash
# Helper function to get repo dir from manifest file
get_repo_dir_for_manifest() {
    manifest_file="$1"
    if [ "${manifest_file}" = "${COMMIT_MANIFEST_FILE}" ]; then
        get_repo_dir "commit"
    elif [ "${manifest_file}" = "${LOCAL_MANIFEST_FILE}" ]; then
        get_repo_dir "local"
    else
        error "Unknown manifest file: ${manifest_file}"
    fi
}
```

**Updates Required**:
- Replace all `"${REPO_DIR}"` with `"$(get_repo_dir_for_manifest "${manifest_file}")"`
- Use curly braces for all variables: `"${entry}"`, `"${filename}"`, etc.

#### 2.2 List Command
**Function**: `cmd_list`

**Strategy**: Must always list everything from both modes. Use commit mode repo if available, fallback to local mode repo. The list command shows multi-glyph status (●◐○) indicating installation status across both modes.

**Key Requirements**:
- Always show complete repository contents (not mode-limited)
- Use appropriate repo directory for file discovery
- Maintain multi-glyph status display
- Use curly braces for all variables

#### 2.3 Add/Remove Commands
**Functions**: `cmd_add_rule`, `cmd_add_ruleset`, `cmd_remove_rule`, `cmd_remove_ruleset`

**Strategy**: Use the target mode's repo directory and call `git_sync` with the appropriate mode.

**Updates Required**:
- Replace `git_sync "${source_repo}"` with `git_sync "${source_repo}" "${mode}"`
- Use curly braces for all variables
- Ensure mode-specific repo directory usage

#### 2.4 Entry-Point Sync Command
**Function**: `cmd_sync`

**Strategy**: Sync both modes if available, ensuring both local and commit repositories are up-to-date.

**New Implementation**:
```bash
cmd_sync() {
    # Check if any mode is initialized
    if [ "${HAS_COMMIT_MODE}" = "false" ] && [ "${HAS_LOCAL_MODE}" = "false" ]; then
        error "No ai-rizz configuration found. Run 'ai-rizz init' first."
    fi
    
    # Sync commit mode repository if available
    if [ "${HAS_COMMIT_MODE}" = "true" ] && [ -n "${COMMIT_SOURCE_REPO}" ]; then
        git_sync "${COMMIT_SOURCE_REPO}" "commit"
    fi
    
    # Sync local mode repository if available
    if [ "${HAS_LOCAL_MODE}" = "true" ] && [ -n "${LOCAL_SOURCE_REPO}" ]; then
        git_sync "${LOCAL_SOURCE_REPO}" "local"
    fi
    
    # Sync all initialized modes
    sync_all_modes
    
    echo "Sync complete"
    return 0
}
```

### 3. Test Infrastructure Updates

#### 3.1 Update tests/common.sh
**File**: `tests/common.sh`
**Lines**: 33-34, 245, 274, 279-280

**Changes**:
1. Remove static `REPO_DIR` override
2. Update `setUp` to use isolated test directories
3. Ensure tests don't touch production `~/.config/ai-rizz/repos`

```bash
# OLD:
REPO_DIR="${TEST_DIR}/${SOURCE_REPO}"

# NEW:
# Override get_repo_dir function for tests
get_repo_dir() {
    mode="${1}"
    echo "${TEST_DIR}/repos/test-project/${mode}"
}
```

#### 3.2 Update All Test Files
**Files**: All test files that reference `REPO_DIR`

**Strategy**: 
1. Remove manual `REPO_DIR` overrides
2. Rely on `get_repo_dir` function override in `tests/common.sh`
3. Ensure test isolation

#### 3.3 Clean Up Debug Scripts
**Files**: `debug_*.sh`, `test_*.sh`

**Strategy**: Update to use new repository structure or mark as deprecated.

### 4. Documentation Updates

#### 4.1 Update README.md
**File**: `README.md`
**Line**: 104

```markdown
# OLD:
ai-rizz stores a permanent copy of the source repository in `${HOME}/.config/ai-rizz/repo`.

# NEW:
ai-rizz stores copies of source repositories in `${HOME}/.config/ai-rizz/repos/PROJECT-NAME/MODE/` where:
- `PROJECT-NAME` is the current directory name
- `MODE` is either `local` or `commit`

This allows different projects and modes to use different source repositories without conflicts.
```

#### 4.2 Update Bash Completion
**File**: `completion.bash`
**Lines**: 14-15, 20-21

**Strategy**: Update to search in the current project's repository directories.

```bash
# OLD:
if [ -d "$HOME/.config/ai-rizz/repo/rules" ]; then
    COMPREPLY=( $(compgen -W "$(find "$HOME/.config/ai-rizz/repo/rules" -name "*.mdc" -printf "%f\n" | sed 's/\.mdc$//')" -- "$cur") )

# NEW:
project_name=$(basename "$(pwd)")
for mode in local commit; do
    repo_dir="${HOME}/.config/ai-rizz/repos/${project_name}/${mode}"
    if [ -d "${repo_dir}/rules" ]; then
        COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rules" -name "*.mdc" -printf "%f\n" | sed 's/\.mdc$//')" -- "${cur}") )
        break
    fi
done
```

## POSIX Style Requirements

**Critical**: All variable expansions must use curly braces per @posix-style.mdc:

- ✅ `"${variable}"` 
- ✅ `$(get_repo_dir "${mode}")`
- ✅ `"${HOME}/.config/ai-rizz/repos/${project_name}/${mode}"`
- ❌ `"$variable"`
- ❌ `$(get_repo_dir "$mode")`

**Examples of required changes**:
```bash
# OLD:
git_sync "$source_repo"
REPO_DIR="$TEST_DIR/$SOURCE_REPO"
if [ "$manifest_file" = "$COMMIT_MANIFEST_FILE" ]; then

# NEW:
git_sync "${source_repo}" "${mode}"
REPO_DIR="${TEST_DIR}/${SOURCE_REPO}"
if [ "${manifest_file}" = "${COMMIT_MANIFEST_FILE}" ]; then
```

## Implementation Order

### Step 1: Core Infrastructure (Minimal Risk)
1. Add `get_repo_dir()` function
2. Add `get_repo_dir_for_manifest()` helper
3. Update `git_sync()` function signature

### Step 2: Update Core Functions (Medium Risk)
1. Update conflict resolution functions
2. Update list command
3. Update add/remove commands

### Step 3: Test Infrastructure (High Risk - Must Be Perfect)
1. Update `tests/common.sh` with function override
2. Test one test file at a time
3. Verify no production contamination
4. Update remaining test files

### Step 4: Documentation (Low Risk)
1. Update README.md
2. Update bash completion
3. Clean up debug scripts

## Testing Strategy

### Validation Steps
1. **Isolation Test**: Verify tests don't touch `~/.config/ai-rizz/repos`
2. **Multi-Project Test**: Verify different directories can use different repos
3. **Mode Separation Test**: Verify local and commit modes can use different repos
4. **Backward Compatibility**: Verify existing setups continue to work
5. **Production Safety**: Verify no test artifacts in production

### Test Sequence
1. Run tests before changes (baseline)
2. Implement Step 1, run tests
3. Implement Step 2, run tests  
4. Implement Step 3, run tests (critical - must pass)
5. Implement Step 4, run tests
6. Full integration test

## Risk Mitigation

### High-Risk Areas
1. **Test Infrastructure**: Breaking tests would be catastrophic
2. **Conflict Resolution**: Complex logic with multiple repo access
3. **Backward Compatibility**: Existing users shouldn't break

### Mitigation Strategies
1. **Incremental Implementation**: One step at a time with testing
2. **Function Overrides**: Use function overrides for test isolation
3. **Fallback Logic**: Graceful degradation if new directories don't exist
4. **Comprehensive Testing**: Test every change thoroughly

## Success Criteria

1. ✅ Tests run in complete isolation (no production contamination)
2. ✅ Multiple projects can use different source repositories
3. ✅ Local and commit modes can use different source repositories  
4. ✅ All existing functionality continues to work
5. ✅ No test artifacts appear in production `ai-rizz list`
6. ✅ All tests pass
7. ✅ Documentation accurately reflects new behavior

## Migration Notes

### For Existing Users
- Existing `~/.config/ai-rizz/repo` will be ignored
- First run in each project will clone fresh repositories
- No data loss (manifests and target directories unchanged)
- Slight performance impact on first run (re-cloning)

### For Developers
- Test isolation prevents production contamination
- Debug scripts need updating or removal
- New directory structure is more predictable and debuggable 