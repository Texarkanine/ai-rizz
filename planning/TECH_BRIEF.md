# Technical Brief: Command Support for ai-rizz

**Document Version:** 2.0  
**Date:** 2025-11-21  
**Status:** Proposed  
**Approach:** Commit-Only Commands with Symlink Farm

---

## Executive Summary

This brief proposes adding support for [Cursor commands](https://cursor.com/docs/agent/chat/commands) to ai-rizz using a symlink-based approach that provides optimal UX while maintaining safe file management. Commands will be **commit-only** (no local mode), with actual files stored in `.cursor/shared-commands/` and symlinks in `.cursor/commands/` for Cursor to discover.

**Key Decisions**:
- Commands are commit-only (no `--local` flag supported)
- Personal commands use Cursor's global `~/.cursor/commands/` feature
- Symlinks enable flat namespace UX (`/eat-cake` not `/shared/eat-cake`)
- Safe cleanup via symlink detection (ignore non-symlink files)

**Estimated Effort**: 1.5-2 days of development + testing + documentation

---

## Problem Statement

### What Are Cursor Commands?

From the [Cursor documentation](https://cursor.com/docs/agent/chat/commands):
- Commands are plain Markdown files stored in `.cursor/commands/`
- Triggered with `/` prefix (e.g., `/review-code`, `/create-pr`)
- Serve as "reusable workflows" - templated prompts for common tasks
- Can be project-level (`.cursor/commands/`), global (`~/.cursor/commands/`), or team-level (server-enforced)

### Current Limitation

ai-rizz only manages "rules" which deploy to `.cursor/rules/`. Users who want to manage team commands must:
1. Manually create and maintain `.cursor/commands/` files
2. Miss out on ai-rizz's sync, versioning, and team-sharing capabilities
3. Maintain separate workflows for conceptually similar artifacts

### Critical Constraints

1. **Flat namespace required**: Cursor expects commands at `.cursor/commands/X.md`, not subdirectories
2. **Containment needed**: ai-rizz must own a directory to safely manage lifecycle without touching user files
3. **Git tracking**: Team commands must be committed, user commands must coexist
4. **No new dependencies**: No JSON, no jq - pure POSIX shell

---

## Proposed Solution: Symlink Farm with Commit-Only Mode

### Core Principle

Store actual command files in `.cursor/shared-commands/` (git-tracked), create symlinks in `.cursor/commands/` (also git-tracked) for Cursor to discover, and ignore any non-symlink files in `.cursor/commands/` (user's own commands).

### Architecture Overview

```
SOURCE REPOSITORY:
├── rules/              # Existing - individual rules
├── rulesets/           # Existing - rule collections
├── commands/           # NEW - individual commands
└── commandsets/        # NEW - command collections

PROJECT DEPLOYMENT:
.cursor/
├── commands/           # Symlink farm + user files
│   ├── eat-cake.md -> ../shared-commands/eat-cake.md   # ai-rizz managed (symlink)
│   └── their-cmd.md                                    # User's own (ignored by ai-rizz)
├── shared-commands/    # Actual command files (git-tracked, ai-rizz managed)
│   └── eat-cake.md     # Real file
└── rules/              # Existing structure unchanged
    ├── shared/         # Committed rules
    └── local/          # Local rules
```

### Key Design Decisions

1. **Commit-Only**: Commands only support commit mode (no `--local` flag)
   - **Rationale**: Personal commands belong in `~/.cursor/commands/` (Cursor's global commands feature)
   - Team commands belong in project (managed by ai-rizz)
   - Avoids complexity of local command mode

2. **Symlink Farm**: `.cursor/commands/` contains symlinks to `.cursor/shared-commands/`
   - **Rationale**: Provides flat namespace UX while maintaining containment
   - Git tracks both symlinks and targets
   - Safe cleanup: only remove symlinks pointing to `../shared-commands/`

3. **Coexistence**: Ignore non-symlink files in `.cursor/commands/`
   - **Rationale**: Users may have their own project commands
   - ai-rizz only manages symlinks, never touches real files in `.cursor/commands/`

4. **Manifest V2**: Same format as rules, but simpler deployment logic
   - Commands always deploy to `shared-commands/` (no mode-specific subdirectories)

---

## Detailed Design

### 1. Configuration Constants

Add to top of `ai-rizz` script:

```sh
# Configuration constants
COMMIT_MANIFEST_FILE="ai-rizz.skbd"
LOCAL_MANIFEST_FILE="ai-rizz.local.skbd"
SHARED_DIR="shared"
LOCAL_DIR="local"
SHARED_COMMANDS_DIR="shared-commands"              # NEW
CONFIG_DIR="$HOME/.config/ai-rizz"
DEFAULT_TARGET_DIR=".cursor/rules"
DEFAULT_RULES_PATH="rules"
DEFAULT_RULESETS_PATH="rulesets"
DEFAULT_COMMANDS_PATH="commands"                   # NEW
DEFAULT_COMMANDSETS_PATH="commandsets"             # NEW
```

### 2. Manifest Format

#### Version Detection (same as before)

```sh
# Count tabs to determine format version
tab_count=$(echo "${metadata}" | tr -cd '\t' | wc -c)

case ${tab_count} in
  1|3)  # V1 format
    rules_path=$(cut -f3 || echo "rules")
    rulesets_path=$(cut -f4 || echo "rulesets")
    cmd_path="${DEFAULT_COMMANDS_PATH}"
    cmdset_path="${DEFAULT_COMMANDSETS_PATH}"
    ;;
  5)    # V2 format
    rules_path=$(cut -f3)
    rulesets_path=$(cut -f4)
    cmd_path=$(cut -f5)
    cmdset_path=$(cut -f6)
    ;;
  *)
    error "Invalid manifest format"
    ;;
esac
```

#### Manifest V2 Format

```
# 6 fields: source, target, rules_path, rulesets_path, cmd_path, cmdset_path
https://github.com/user/rules.git[TAB].cursor/rules[TAB]rules[TAB]rulesets[TAB]commands[TAB]commandsets
rules/bash-style.mdc
rulesets/shell
commands/review-code.md
commandsets/workflows
```

**Note**: Command entries look identical to rule entries in manifest, but deploy differently.

### 3. Global Variables

```sh
# Existing
RULES_PATH=""                    # Path to rules in source repo
RULESETS_PATH=""                 # Path to rulesets in source repo
TARGET_DIR=""                    # Target for rules (.cursor/rules)

# New
COMMANDS_PATH=""                 # Path to commands in source repo
COMMANDSETS_PATH=""              # Path to commandsets in source repo
```

**Note**: No `CMD_TARGET_DIR` variable - commands always deploy to `.cursor/${SHARED_COMMANDS_DIR}` (fixed).

### 4. CLI Interface

#### New Commands

```bash
# Add commands (commit-only)
ai-rizz add cmd <command>...
ai-rizz add cmdset <commandset>...

# Remove commands
ai-rizz remove cmd <command>...
ai-rizz remove cmdset <commandset>...

# List with filtering
ai-rizz list              # Shows rules, then commands (with divider)
ai-rizz list rules        # Rules and rulesets only
ai-rizz list cmds         # Commands and commandsets only

# Init with command paths
ai-rizz init <source_repo> [options]
  --cmd-path <path>       # Path to commands in source repo (default: commands)
  --cmdset-path <path>    # Path to commandsets in source repo (default: commandsets)
```

#### What's NOT Supported

```bash
# These flags do NOT work for commands
ai-rizz add cmd review-code.md --local    # ERROR: Commands do not support --local mode
ai-rizz add cmd review-code.md --commit   # Redundant (commit is only mode), but allowed

# Alternative for personal commands
# User should use: ~/.cursor/commands/review-code.md (Cursor's global commands)
```

#### Help Text Updates

```
Available commands:
  init [<source_repo>]       Initialize the repository
  deinit                     Deinitialize the repository
  list [rules|cmds]          List available rules/commands and their status
  add rule <rule>...         Add rule(s) to the repository
  add cmd <cmd>...           Add command(s) to the repository (commit-only)
  add ruleset <ruleset>...   Add ruleset(s) to the repository
  add cmdset <cmdset>...     Add commandset(s) to the repository (commit-only)
  remove rule <rule>...      Remove rule(s) from the repository
  remove cmd <cmd>...        Remove command(s) from the repository
  remove ruleset <ruleset>... Remove ruleset(s) from the repository
  remove cmdset <cmdset>...  Remove commandset(s) from the repository
  sync                       Sync rules and commands
  help                       Show this help

General options:
  -f, --manifest <file>  Alias for --skibidi
  -s, --skibidi <file>   Use custom manifest filename

init options:
  -c, --commit           Use commit mode
  -d <target_dir>        Target directory (default: .cursor/rules)
  -l, --local            Use local mode (gitignore files)
  --rule-path <path>     Source repository rules path (default: rules)
  --ruleset-path <path>  Source repository rulesets path (default: rulesets)
  --cmd-path <path>      Source repository commands path (default: commands)
  --cmdset-path <path>   Source repository commandsets path (default: commandsets)

add & remove options (rules only):
  --commit, -c           Use commit mode
  --local, -l            Use local mode (gitignore files)

Note: Commands are always committed (no --local mode).
      For personal commands, use ~/.cursor/commands/ (Cursor's global commands feature).
```

### 5. Code Architecture

#### Sync Logic (Manifest-Driven)

Commands follow the same manifest-driven pattern as rules: modify manifest, then sync.

**Why Commands Don't Use `sync_manifest_to_directory()`:**

Commands require different sync logic than rules:
- **File extension**: Rules use `*.mdc`, commands use `*.md`
- **Deployment**: Rules copy to one location, commands copy + create symlink in two locations
- **Directory ownership**: Rules own `.cursor/rules/shared/` (can clear), commands share `.cursor/commands/` with user files (cannot clear)
- **Cleanup strategy**: Rules clear directory first, commands must check each symlink individually

Therefore, `sync_commands()` is a dedicated sync function parallel to rule sync, not a wrapper around `sync_manifest_to_directory()`.

```sh
# Sync commands from manifest to filesystem
# Called by sync_all_modes() - reads manifest and deploys all commands
sync_commands() {
  # Step 1: Cleanup stale commands (not in manifest)
  # This matches the behavior of sync_manifest_to_directory() for rules
  if [ -d ".cursor/commands" ]; then
    for sc_file in .cursor/commands/*.md; do
      [ -e "${sc_file}" ] || continue  # Skip if no .md files
      
      if [ -L "${sc_file}" ]; then
        sc_target=$(readlink "${sc_file}")
        sc_basename=$(basename "${sc_file}")
        
        # Only touch our symlinks (pointing to shared-commands/)
        if [ "${sc_target}" = "../${SHARED_COMMANDS_DIR}/${sc_basename}" ]; then
          # Check if in manifest
          if ! read_manifest_entries "${COMMIT_MANIFEST_FILE}" 2>/dev/null | grep -q "^${COMMANDS_PATH}/${sc_basename}$"; then
            # Stale command - remove it
            remove_command "${sc_basename}"
          fi
        fi
      fi
    done
  fi
  
  # Step 2: Deploy commands from manifest
  sc_entries=$(read_manifest_entries "${COMMIT_MANIFEST_FILE}" 2>/dev/null | grep "^${COMMANDS_PATH}/" || true)
  
  if [ -z "${sc_entries}" ]; then
    return 0  # No commands to sync
  fi
  
  # Deploy each command
  for sc_entry in ${sc_entries}; do
    sc_cmd_name=$(basename "${sc_entry}")
    
    # Deploy using utility function
    deploy_command "${sc_cmd_name}"
  done
}

# Update sync_all_modes() to handle commands
sync_all_modes() {
  # Sync local rules (existing)
  if [ "$(is_mode_active local)" = "true" ]; then
    sync_manifest_to_directory "${LOCAL_MANIFEST_FILE}" "${LOCAL_TARGET_DIR}"
  fi
  
  # Sync committed rules (existing)
  if [ "$(is_mode_active commit)" = "true" ]; then
    sync_manifest_to_directory "${COMMIT_MANIFEST_FILE}" "${COMMIT_TARGET_DIR}"
  fi
  
  # Sync commands (NEW - different deployment logic)
  if [ "$(is_mode_active commit)" = "true" ]; then
    sync_commands
  fi
}
```

**Sync Architecture:**
```
sync_all_modes()
├── Rules: sync_manifest_to_directory()
│   └── Clear *.mdc → Copy from repo → Done
└── Commands: sync_commands()
    ├── Remove stale symlinks (not in manifest)
    └── Deploy from manifest: deploy_command() → file + symlink
```

#### Deployment Utilities

Utility functions called by sync logic:

```sh
# Utility: Deploy single command to filesystem
# Called by sync_commands() - creates file + symlink
deploy_command() {
  dc_cmd_name="$1"
  dc_source_file="${REPO_DIR}/${COMMANDS_PATH}/${dc_cmd_name}"
  dc_target_file=".cursor/${SHARED_COMMANDS_DIR}/${dc_cmd_name}"
  dc_symlink=".cursor/commands/${dc_cmd_name}"
  
  # Validate source exists
  if [ ! -f "${dc_source_file}" ]; then
    warn "Command '${dc_cmd_name}' not found in source repository, skipping"
    return 1
  fi
  
  # Check for collision with user's files
  if [ -e "${dc_symlink}" ] && [ ! -L "${dc_symlink}" ]; then
    warn "Cannot deploy command '${dc_cmd_name}': file exists in .cursor/commands/ (not managed by ai-rizz)"
    return 1
  fi
  
  # If symlink exists, verify it's ours
  if [ -L "${dc_symlink}" ]; then
    dc_existing_target=$(readlink "${dc_symlink}")
    if [ "${dc_existing_target}" != "../${SHARED_COMMANDS_DIR}/${dc_cmd_name}" ]; then
      warn "Cannot deploy command '${dc_cmd_name}': symlink exists but not managed by ai-rizz"
      return 1
    fi
  fi
  
  # Create target directory
  mkdir -p ".cursor/${SHARED_COMMANDS_DIR}"
  
  # Copy actual file to shared-commands
  cp "${dc_source_file}" "${dc_target_file}"
  
  # Create symlink directory
  mkdir -p ".cursor/commands"
  
  # Create symlink (relative path for portability)
  ln -sf "../${SHARED_COMMANDS_DIR}/${dc_cmd_name}" "${dc_symlink}"
}

# Utility: Remove command from filesystem
# Called by sync or cleanup operations
remove_command() {
  rc_cmd_name="$1"
  rc_target_file=".cursor/${SHARED_COMMANDS_DIR}/${rc_cmd_name}"
  rc_symlink=".cursor/commands/${rc_cmd_name}"
  
  # Only remove if symlink exists and points to our file
  if [ -L "${rc_symlink}" ]; then
    rc_link_target=$(readlink "${rc_symlink}")
    if [ "${rc_link_target}" = "../${SHARED_COMMANDS_DIR}/${rc_cmd_name}" ]; then
      rm "${rc_symlink}"
    fi
  fi
  
  # Remove actual file
  if [ -f "${rc_target_file}" ]; then
    rm "${rc_target_file}"
  fi
}
```

**Key Design**: Just like rules, commands are deployed by reading the manifest and calling deployment functions. The manifest is the single source of truth.

#### Command Functions (Manifest-Driven)

Commands follow the same pattern as rules: modify manifest, then sync.

```sh
cmd_add_cmd() {
  cac_commands=""
  
  # Parse arguments (no mode flags supported)
  while [ $# -gt 0 ]; do
    case "$1" in
      --local|-l|--commit|-c)
        if [ "$1" = "--local" ] || [ "$1" = "-l" ]; then
          error "Commands do not support --local mode. Use ~/.cursor/commands/ for personal commands."
        fi
        # --commit is redundant but allowed
        shift
        ;;
      *)
        if [ -z "${cac_commands}" ]; then
          cac_commands="$1"
        else
          cac_commands="${cac_commands} $1"
        fi
        shift
        ;;
    esac
  done
  
  # Ensure initialized
  ensure_initialized_and_valid
  
  # Process each command
  for cac_cmd in ${cac_commands}; do
    # Add .md extension if not present
    case "${cac_cmd}" in
      *".md") 
        cac_item="${cac_cmd}"
        ;;  
      *) 
        cac_item="${cac_cmd}.md"
        ;;  
    esac
    
    cac_cmd_path="${COMMANDS_PATH}/${cac_item}"
    
    # Check if command exists in source repo
    if ! check_repository_item "${cac_cmd_path}" "Command"; then
      continue
    fi
    
    # Add to manifest (just like rules)
    add_manifest_entry_to_file "${COMMIT_MANIFEST_FILE}" "${cac_cmd_path}"
    
    echo "Added command: ${cac_cmd_path}"
  done
  
  # Sync to deploy files based on manifest (just like rules)
  sync_all_modes
  
  return 0
}

cmd_remove_cmd() {
  crc_commands=""
  
  # Parse arguments
  while [ $# -gt 0 ]; do
    if [ -z "${crc_commands}" ]; then
      crc_commands="$1"
    else
      crc_commands="${crc_commands} $1"
    fi
    shift
  done
  
  # Ensure initialized
  ensure_initialized_and_valid
  
  # Process each command
  for crc_cmd in ${crc_commands}; do
    # Add .md extension if not present
    case "${crc_cmd}" in
      *".md") 
        crc_item="${crc_cmd}"
        ;;  
      *) 
        crc_item="${crc_cmd}.md"
        ;;  
    esac
    
    crc_cmd_path="${COMMANDS_PATH}/${crc_item}"
    
    # Remove from manifest (just like rules)
    remove_manifest_entry_from_file "${COMMIT_MANIFEST_FILE}" "${crc_cmd_path}"
    
    # Clean up deployed files
    remove_command "${crc_item}"
    
    echo "Removed command: ${crc_cmd_path}"
  done
  
  return 0
}
```

**Key Pattern**: Same as rules - modify manifest, call sync. The `sync_all_modes()` function handles deployment.

#### Listing Commands

```sh
# Add to cmd_list() function
list_commands() {
  lc_source_repo="${SOURCE_REPO}"
  
  echo "Available commands:"
  lc_commands=$(find "${REPO_DIR}/${COMMANDS_PATH}" -name "*.md" | sort 2>/dev/null)
  
  if [ -z "${lc_commands}" ]; then
    echo "  No commands found"
  else
    for lc_cmd in ${lc_commands}; do
      lc_cmd_name=$(basename "${lc_cmd}")
      lc_cmd_path="${COMMANDS_PATH}/${lc_cmd_name}"
      
      # Check if installed (in commit manifest)
      if read_manifest_entries "${COMMIT_MANIFEST_FILE}" 2>/dev/null | grep -q "^${lc_cmd_path}$"; then
        printf "  %s %s\n" "${COMMITTED_GLYPH}" "${lc_cmd_name}"
      else
        printf "  %s %s\n" "${UNINSTALLED_GLYPH}" "${lc_cmd_name}"
      fi
    done
  fi
  echo ""
}

# Update cmd_list() to support filtering
cmd_list() {
  cl_filter="${1:-all}"  # all, rules, cmds
  
  # ... existing validation ...
  
  case "${cl_filter}" in
    rules)
      # Show rules only (existing logic)
      list_rules
      ;;
    cmds|commands)
      # Show commands only
      list_commands
      ;;
    all|*)
      # Show both
      list_rules
      list_commands
      ;;
  esac
}
```

#### Functions Requiring Updates

| Function | Change Required | Complexity |
|----------|----------------|------------|
| `parse_manifest_metadata()` | Add V2 format parsing (6 fields) | Low |
| `write_manifest_with_entries()` | Write V2 format (6 fields) | Low |
| `cmd_list()` | Add command listing + filtering | Medium |
| `sync_all_modes()` | Add command sync call after rule sync | Low |
| `deploy_command()` | Change error() to warn() for sync use | Low |
| `cmd_init()` | Accept `--cmd-path`, `--cmdset-path` | Low |
| `cmd_deinit()` | Clean up command directories | Low |
| `cmd_help()` | Update help text | Low |

#### New Functions Required

| Function | Purpose | Complexity |
|----------|---------|------------|
| `sync_commands()` | Sync commands from manifest (cleanup stale + deploy) | Medium |
| `deploy_command()` | Utility: Deploy single command + create symlink | Medium |
| `remove_command()` | Utility: Remove symlink + actual file | Low |
| `cmd_add_cmd()` | Add commands to manifest + sync | Low |
| `cmd_add_cmdset()` | Add command sets to manifest + sync | Low |
| `cmd_remove_cmd()` | Remove commands from manifest + cleanup | Low |
| `cmd_remove_cmdset()` | Remove command sets from manifest + cleanup | Low |
| `list_commands()` | List available commands | Low |

**Note**: Rules use `sync_manifest_to_directory()`, commands use `sync_commands()` - parallel sync paths due to different deployment requirements.

---

## Implementation Plan

### Phase 1: Core Infrastructure (TDD)

**Goal**: Manifest V2 support with auto-upgrade

1. **Stub Tests**: `test_manifest_format.test.sh`
   - Test V1 manifest reading (existing)
   - Test V2 manifest reading (new)
   - Test V2 manifest writing (new)
   - Test auto-upgrade on write (new)

2. **Stub Functions**:
   - Update `parse_manifest_metadata()` signature
   - Update `write_manifest_with_entries()` signature
   - Add constants: `SHARED_COMMANDS_DIR`, `DEFAULT_COMMANDS_PATH`, `DEFAULT_COMMANDSETS_PATH`
   - Add globals: `COMMANDS_PATH`, `COMMANDSETS_PATH`

3. **Implement Tests**: Write full test implementations

4. **Implement Code**: Make tests pass

**Deliverable**: Manifests can be read/written in both formats

### Phase 2: Command Deployment (TDD)

**Goal**: Deploy commands with symlink creation (manifest-driven)

**Part A: Deployment Utilities**

1. **Stub Tests**: `test_command_deployment.test.sh` (new file)
   - Test deploy command creates file in shared-commands/
   - Test deploy command creates symlink in commands/
   - Test symlink points to correct target
   - Test collision detection (non-symlink file exists)
   - Test collision detection (wrong symlink target)
   - Test remove command deletes both files
   - Test remove command ignores non-symlink files

2. **Stub Functions**:
   - `deploy_command()` - empty implementation
   - `remove_command()` - empty implementation

3. **Implement Tests**: Write full test implementations

4. **Implement Code**: Make tests pass

**Part B: Sync Integration**

1. **Stub Tests**: `test_command_sync.test.sh` (new file)
   - Test sync_commands reads manifest
   - Test sync_commands deploys all commands
   - Test sync_commands removes stale commands (not in manifest)
   - Test sync_commands skips missing commands
   - Test sync_all_modes calls sync_commands
   - Test sync handles command collisions gracefully

2. **Stub Functions**:
   - `sync_commands()` - empty implementation (includes stale cleanup)
   - Update `sync_all_modes()` - add command sync call

3. **Implement Tests**: Write full test implementations

4. **Implement Code**: Make tests pass

**Deliverable**: Commands deploy correctly with symlinks, manifest-driven via sync, with automatic stale cleanup

### Phase 3: Command Add/Remove (TDD)

**Goal**: CLI command operations work

1. **Stub Tests**: `test_command_management.test.sh` (new file)
   - Test add single command
   - Test add multiple commands
   - Test add command with .md extension
   - Test add command without .md extension
   - Test add commandset
   - Test remove command
   - Test remove commandset
   - Test --local flag rejection
   - Test --commit flag acceptance (noop)

2. **Stub Functions**:
   - `cmd_add_cmd()` - empty implementation
   - `cmd_add_cmdset()` - empty implementation
   - `cmd_remove_cmd()` - empty implementation
   - `cmd_remove_cmdset()` - empty implementation

3. **Implement Tests**: Write full test implementations

4. **Implement Code**: Implement command functions

**Deliverable**: Can add/remove commands via CLI

### Phase 4: Listing and Sync (TDD)

**Goal**: Commands visible and synchronized

1. **Stub Tests**:
   - `test_command_listing.test.sh` - list commands, filtering
   - Update `test_sync_operations.test.sh` - sync includes commands

2. **Stub Functions**:
   - `list_commands()` - empty implementation
   - Update `cmd_list()` to accept filter argument
   - Update `cmd_sync()` to handle commands

3. **Implement Tests**: Write full test implementations

4. **Implement Code**: Make tests pass

**Deliverable**: Commands appear in listings and sync properly

### Phase 5: Init and Deinit (TDD)

**Goal**: Full lifecycle support

1. **Stub Tests**:
   - Update `test_initialization.test.sh` - custom cmd paths
   - Update `test_deinit_modes.test.sh` - command cleanup

2. **Update Functions**:
   - `cmd_init()` - parse `--cmd-path`, `--cmdset-path`
   - `cmd_deinit()` - clean up command directories and symlinks

3. **Implement Tests**: Write full test implementations

4. **Implement Code**: Make tests pass

**Deliverable**: Complete command lifecycle management

### Phase 6: Integration and Polish

**Goal**: Production ready

1. **Update Main Command Dispatcher**:
   - Add `cmd` and `cmdset` cases to `add` and `remove` handlers
   - Update argument validation
   - Add mode flag validation (reject --local for commands)

2. **Update Help**:
   - Update `cmd_help()` with command documentation
   - Update README.md with command examples
   - Document commit-only nature of commands

3. **Integration Tests**:
   - `test_cli_add_remove.test.sh` - add command tests
   - `test_cli_list_sync.test.sh` - command listing/sync tests

4. **Run Full Test Suite**: `make test`

**Deliverable**: Fully tested, documented feature

### Phase 7: Source Repository Updates

**Goal**: Reference implementation available

1. **Add to .cursor-rules repo**:
   - Create `commands/` directory
   - Add example commands from Cursor docs:
     - `review-code.md`
     - `create-pr.md`
     - `run-tests-and-fix.md`
     - `security-audit.md`

2. **Create commandset**:
   - `commandsets/workflows/` with common commands
   - Include README explaining structure

3. **Update .cursor-rules README**:
   - Document commands support
   - Show example usage with ai-rizz
   - Explain commit-only nature

**Deliverable**: Users can pull real commands immediately

---

## Testing Strategy

### Unit Tests (New)

- `test_command_deployment.test.sh` - Symlink creation and cleanup
- `test_command_management.test.sh` - Command add/remove operations
- `test_command_listing.test.sh` - Command listing and filtering
- `test_commandset_management.test.sh` - Commandset operations

### Unit Tests (Updated)

- `test_manifest_format.test.sh` - V2 format support, auto-upgrade
- `test_initialization.test.sh` - Custom command paths
- `test_sync_operations.test.sh` - Command sync operations
- `test_deinit_modes.test.sh` - Command cleanup

### Integration Tests (Updated)

- `test_cli_add_remove.test.sh` - CLI command operations
- `test_cli_list_sync.test.sh` - Command listing and sync
- `test_cli_init.test.sh` - Init with command paths

### Test Coverage Goals

- Symlink creation and cleanup work correctly
- Collision detection prevents overwriting user files
- Non-symlink files in `.cursor/commands/` are never touched
- Commands sync correctly from source repository
- Backwards compatibility: V1 manifests still work
- Auto-upgrade: V1 → V2 transparent to users
- Error handling: Missing commands/, friendly messages
- Mode flag rejection: --local flag properly rejected

### Edge Cases to Test

1. **User file collision**: Real file exists at `.cursor/commands/cmd.md`
2. **Wrong symlink**: Symlink exists but points elsewhere
3. **Broken symlink**: Symlink target doesn't exist
4. **Empty directories**: `.cursor/commands/` exists but empty
5. **Missing shared-commands**: Target directory doesn't exist
6. **Git tracking**: Symlinks committed correctly
7. **Commandset with symlinks**: Commandsets work like rulesets

---

## Migration Path

### For ai-rizz Users

**No action required** - seamless upgrade:

1. Update ai-rizz to new version
2. Next operation auto-upgrades manifest to V2
3. If source repo has `commands/`, they become available
4. If source repo lacks `commands/`, nothing breaks
5. Existing rules continue to work identically

### For Source Repository Maintainers

**Optional adoption** - gradual enhancement:

1. Add `commands/` directory to source repo
2. Add `commandsets/` directory if desired
3. Populate with `.md` files following Cursor's format
4. Users automatically see commands in `ai-rizz list cmds`

### Example Migration Timeline

| Week | Action | Impact |
|------|--------|--------|
| W1 | Release ai-rizz v2.0 | Users can upgrade |
| W2 | Users run first command | Manifest auto-upgrades to V2 |
| W3 | Add `commands/` to .cursor-rules repo | Commands available to users |
| W4 | Users `ai-rizz sync` | Pull new commands |
| W5+ | Users `ai-rizz add cmd review-code.md` | Commands deployed |

---

## Backwards Compatibility

### Guarantees

1. **Manifest V1 Reading**: All existing manifests continue to work
2. **Source Repo Compatibility**: Repos without `commands/` work fine
3. **CLI Compatibility**: All existing rule commands unchanged
4. **Deployment Compatibility**: Rules still deploy to same locations
5. **Git Tracking**: Rules git tracking unchanged

### Breaking Changes

**None for users** - all changes are additive.

**For developers/contributors**:
- Internal function signatures change (manifest parsing)
- New test files required
- Documentation reflects new capabilities

---

## Risks and Mitigations

### Risk 1: Symlink Support on Windows

**Likelihood**: Medium  
**Impact**: High (commands won't work on Windows without symlink support)

**Mitigation**:
- WSL, Git Bash, and modern Windows (Developer Mode) support symlinks
- Document symlink requirement clearly
- Git for Windows automatically handles symlinks on clone/pull
- Most developers use environments with symlink support
- Alternative: Users can manually copy files (not recommended)

**Note**: This is acceptable because:
- Target audience (developers) typically have symlink support
- Git handles symlinks transparently on clone/pull
- Cursor itself is a developer tool with similar assumptions

### Risk 2: User Accidentally Commits Local Commands

**Likelihood**: Low  
**Impact**: Low (commands are meant to be shared anyway)

**Mitigation**:
- Commands are commit-only by design
- Documentation explains personal commands → `~/.cursor/commands/`
- No `.gitignore` confusion (everything in shared-commands/ is tracked)

### Risk 3: Source Repos Without Commands/

**Likelihood**: High (initially)  
**Impact**: Low (users just don't see commands)

**Mitigation**:
- Graceful handling: Check if `commands/` exists before listing
- Clear messaging: "No commands available in source repository"
- Example source repo (.cursor-rules) demonstrates structure
- Documentation shows how to add commands to source repos

### Risk 4: Collision with User's Own Commands

**Likelihood**: Medium  
**Impact**: Medium (user must rename file)

**Mitigation**:
- Clear error message with resolution steps
- Check before creating symlink, fail early
- Documentation explains how to avoid collisions
- Users can rename their own commands

### Risk 5: Git Tracking Confusion

**Likelihood**: Low  
**Impact**: Low (user confusion, not data loss)

**Mitigation**:
- Documentation explains what gets committed
- Both symlinks and targets are tracked (natural git behavior)
- `git status` will show both files
- README includes "what gets committed" section

---

## Success Criteria

### Must Have (MVP)

- [ ] Manifest V2 reads/writes correctly
- [ ] V1 manifests auto-upgrade transparently
- [ ] `ai-rizz add cmd` works and creates symlinks
- [ ] `ai-rizz list` shows both rules and commands
- [ ] `ai-rizz list cmds` shows only commands
- [ ] Commands deploy to `.cursor/shared-commands/`
- [ ] Symlinks created in `.cursor/commands/`
- [ ] Collision detection works (non-symlink files)
- [ ] `--local` flag rejected for commands
- [ ] All existing tests still pass
- [ ] New command tests achieve >80% coverage
- [ ] Documentation updated (README, help text)

### Should Have (V2.1)

- [ ] Commandset support (parallel to rulesets)
- [ ] `ai-rizz remove cmd` cleans up properly
- [ ] `ai-rizz sync` updates commands
- [ ] .cursor-rules repo has example commands
- [ ] Migration guide for source repo maintainers

### Nice to Have (Future)

- [ ] Command validation (check markdown format)
- [ ] Statistics: "X rules, Y commands installed"
- [ ] Warning when command name matches rule name
- [ ] `--force` flag to override collision detection

---

## Design Rationale

### Why Commit-Only?

1. **Cursor provides global commands**: `~/.cursor/commands/` for personal use
2. **Project commands are team commands**: If it's in the project, it should be shared
3. **Simplifies implementation**: No mode conflicts, no migration logic
4. **Clearer mental model**: Personal → global, team → project
5. **Code reuse**: Can still reuse most rule management logic

### Why Symlinks?

1. **Flat namespace UX**: Users type `/eat-cake` not `/shared/eat-cake`
2. **Safe cleanup**: Can detect and only remove our symlinks
3. **Coexistence**: User files (non-symlinks) are never touched
4. **Git native**: Git tracks symlinks naturally, clones/pulls work
5. **Standard POSIX**: No new dependencies, widely supported

### Why Not JSON Metadata?

1. **No dependencies**: Shell can't parse JSON natively (would need jq)
2. **ai-rizz has no dependency management**: Can't add new dependencies
3. **Symlinks are self-documenting**: `readlink` tells us what's ours
4. **POSIX compliance**: Stays true to shell-script simplicity

### Why Separate Directory?

1. **Containment**: ai-rizz owns `.cursor/shared-commands/`, never touches user files
2. **Clear ownership**: Everything in `shared-commands/` is managed by ai-rizz
3. **Consistent pattern**: Mirrors `.cursor/rules/shared/` structure
4. **Safe lifecycle**: Can add/remove/sync without risk

---

## Environment Variables

### New Variables

```bash
AI_RIZZ_CMD_PATH         # Fallback for --cmd-path
AI_RIZZ_CMDSET_PATH      # Fallback for --cmdset-path
```

### Existing Variables (Unchanged)

```bash
AI_RIZZ_MANIFEST         # Fallback for --manifest/--skibidi
AI_RIZZ_SOURCE_REPO      # Fallback for <source_repo>
AI_RIZZ_TARGET_DIR       # Fallback for -d <target_dir>
AI_RIZZ_RULE_PATH        # Fallback for --rule-path
AI_RIZZ_RULESET_PATH     # Fallback for --ruleset-path
AI_RIZZ_MODE             # Fallback for --local/--commit (rules only)
```

---

## Related Documents

- [Cursor Commands Documentation](https://cursor.com/docs/agent/chat/commands)
- [ai-rizz README](./README.md)
- [.cursor-rules Source Repository](https://github.com/texarkanine/.cursor-rules)

---

## Appendix A: Example Usage

### Adding Commands

```bash
# Initialize with command support (manifest auto-upgrades)
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --commit

# Add individual command
ai-rizz add cmd review-code.md

# Result:
# - File created: .cursor/shared-commands/review-code.md
# - Symlink created: .cursor/commands/review-code.md -> ../shared-commands/review-code.md
# - User types: /review-code (flat namespace)

# Add commandset
ai-rizz add cmdset workflows

# List everything
ai-rizz list
# Output:
# Available rules:
#   ● bash-style.mdc
#   ◐ personal-style.mdc
#
# Available commands:
#   ● review-code.md
#   ○ security-audit.md

# List only commands
ai-rizz list cmds
# Output:
# Available commands:
#   ● review-code.md
#   ○ security-audit.md

# Try to add local command (error)
ai-rizz add cmd personal.md --local
# Error: Commands do not support --local mode. Use ~/.cursor/commands/ for personal commands.
```

### Collision Handling

```bash
# User has their own command
ls .cursor/commands/
# my-command.md (real file, not symlink)

# Try to add command with same name
ai-rizz add cmd my-command.md
# Error: Cannot add command 'my-command.md': file exists in .cursor/commands/ (not managed by ai-rizz)
# Please rename existing file or choose different command name.

# User renames their file
mv .cursor/commands/my-command.md .cursor/commands/my-old-command.md

# Now it works
ai-rizz add cmd my-command.md
# Deployed command: my-command.md
# Added command: commands/my-command.md
```

### Personal Commands (Global)

```bash
# For personal commands, use Cursor's global feature
mkdir -p ~/.cursor/commands
cat > ~/.cursor/commands/my-personal-cmd.md << 'EOF'
# My Personal Command

Quick scratch work command for testing ideas.
EOF

# Now available globally in all projects: /my-personal-cmd
```

---

## Appendix B: Source Repository Structure

### Before (Rules Only)

```
.cursor-rules/
├── rules/
│   ├── bash-style.mdc
│   ├── shell-tdd.mdc
│   └── github-pr.mdc
└── rulesets/
    └── shell/
        ├── bash-style.mdc -> ../../rules/bash-style.mdc
        └── shell-tdd.mdc -> ../../rules/shell-tdd.mdc
```

### After (Rules + Commands)

```
.cursor-rules/
├── rules/
│   ├── bash-style.mdc
│   ├── shell-tdd.mdc
│   └── github-pr.mdc
├── rulesets/
│   └── shell/
│       ├── bash-style.mdc -> ../../rules/bash-style.mdc
│       └── shell-tdd.mdc -> ../../rules/shell-tdd.mdc
├── commands/                      # NEW
│   ├── review-code.md
│   ├── create-pr.md
│   ├── run-tests-and-fix.md
│   └── security-audit.md
└── commandsets/                   # NEW
    └── workflows/
        ├── review-code.md -> ../../commands/review-code.md
        └── create-pr.md -> ../../commands/create-pr.md
```

---

## Appendix C: Filesystem Layout

### After Deployment

```
project-root/
├── .cursor/
│   ├── commands/                          # Mixed: symlinks + user files
│   │   ├── review-code.md -> ../shared-commands/review-code.md  # ai-rizz managed
│   │   ├── create-pr.md -> ../shared-commands/create-pr.md      # ai-rizz managed
│   │   └── my-local-cmd.md                                       # User's own (ignored)
│   ├── shared-commands/                   # ai-rizz owned (git-tracked)
│   │   ├── review-code.md                 # Real file
│   │   └── create-pr.md                   # Real file
│   └── rules/                             # Existing structure
│       ├── shared/
│       │   └── bash-style.mdc
│       └── local/
│           └── personal-rule.mdc
├── ai-rizz.skbd                           # Commit manifest (V2 format)
└── ai-rizz.local.skbd                     # Local manifest (V2 format)
```

### Git Tracking

**Tracked (committed)**:
- `.cursor/shared-commands/` (directory and all contents)
- `.cursor/commands/*.md` (symlinks only)
- `.cursor/rules/shared/` (directory and all contents)
- `ai-rizz.skbd`

**Ignored (via .git/info/exclude)**:
- `.cursor/rules/local/`
- `ai-rizz.local.skbd`

**Coexist (user managed)**:
- `.cursor/commands/my-local-cmd.md` (real file) - user decides to track or ignore

---

## Appendix D: Manifest Evolution

### V1 Format (Current)

```
# 4 fields: source, target, rules_path, rulesets_path
https://github.com/user/rules.git[TAB].cursor/rules[TAB]rules[TAB]rulesets
rules/bash-style.mdc
rulesets/shell
```

### V2 Format (Proposed)

```
# 6 fields: source, target, rules_path, rulesets_path, cmd_path, cmdset_path
https://github.com/user/rules.git[TAB].cursor/rules[TAB]rules[TAB]rulesets[TAB]commands[TAB]commandsets
rules/bash-style.mdc
rulesets/shell
commands/review-code.md
commandsets/workflows
```

**Note**: Command entries use same format as rule entries. Differentiation happens at deployment:
- Entries starting with `${RULES_PATH}/` deploy to `.cursor/rules/{shared,local}/`
- Entries starting with `${COMMANDS_PATH}/` deploy to `.cursor/shared-commands/` + create symlinks

### Auto-Upgrade Logic

```sh
# Read existing manifest
metadata=$(head -n1 ai-rizz.skbd)

# Parse based on tab count
tab_count=$(echo "$metadata" | tr -cd '\t' | wc -c)

if [ "$tab_count" -lt 5 ]; then
  # V1 format - add defaults
  cmd_path="commands"
  cmdset_path="commandsets"
  
  # On next write, save as V2
  write_manifest_v2 "$metadata" "$cmd_path" "$cmdset_path"
fi
```

---

**End of Technical Brief**
