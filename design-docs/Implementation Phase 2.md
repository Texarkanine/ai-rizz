# Implementation Phase 2: Core Infrastructure 

## Overview

This document provides a detailed step-by-step plan for implementing the core infrastructure for ai-rizz progressive initialization. Phase 2 focuses on the foundational systems that enable mode detection, manifest handling, and lazy initialization without changing command interfaces.

**Phase 2 Goals**:
- Implement mode detection utilities 
- Add progressive manifest handling
- Build lazy initialization infrastructure
- Update sync command behavior
- Implement legacy repository migration
- Enable 2-3 out of 8 tests to pass (measurable progress)

**Key Principles**: 
- Replace existing functions entirely. The script will be temporarily broken until all phases complete.
- **Clean Architecture**: Functions return data via stdout/return codes, not global state pollution
- **Read-only Globals**: Global variables set once during initialization, read-only afterward
- **No Test Helpers**: Remove functions that exist only for test assertions

## Implementation Strategy

Phase 2 is divided into 4 focused sub-phases, each with clear validation points:

1. **Phase 2.1**: Mode detection & global variable system → Fix `test_mode_detection.test.sh`
2. **Phase 2.2**: Progressive manifest handling → Fix manifest-related assertions  
3. **Phase 2.3**: Git exclude management → Fix git exclude assertions
4. **Phase 2.4**: Lazy initialization & migration → Fix lazy init and migration tests

After each sub-phase, run `make test` to measure concrete progress.

## Current State Analysis

### Existing Functions to Replace
- `read_manifest()` → `read_manifest_metadata()` / `read_manifest_entries()`
- `is_local_mode()` → Direct check of `$HAS_LOCAL_MODE`
- Sync logic → Multi-mode sync behavior
- Init setup → Progressive initialization

### Test Compatibility 
✅ **No test modifications needed**. Tests already expect new behavior patterns.

## Phase 2.1: Mode Detection & Global Variable System

### Global Variable Updates

Replace the existing global variables section with the new progressive system:

**File**: `ai-rizz` (lines ~10-15, replace existing globals)

```bash
#!/bin/sh
# ai-rizz - A CLI tool to manage rules and rulesets  
# POSIX compliant shell script

set -e  # Exit on error

# Configuration constants
COMMIT_MANIFEST_FILE="ai-rizz.inf"
LOCAL_MANIFEST_FILE="ai-rizz.local.inf"
SHARED_DIR="shared"
LOCAL_DIR="local" 
CONFIG_DIR="$HOME/.config/ai-rizz"
REPO_DIR="$CONFIG_DIR/repo"
DEFAULT_TARGET_DIR=".cursor/rules"

# Mode state (set once during initialization, read-only afterward)
HAS_COMMIT_MODE=false
HAS_LOCAL_MODE=false

# Cached manifest metadata (set during initialization for efficiency)
COMMIT_SOURCE_REPO=""
LOCAL_SOURCE_REPO=""
COMMIT_TARGET_DIR=""
LOCAL_TARGET_DIR=""

# Display formatting variables  
COMMITTED_GLYPH="●"
UNINSTALLED_GLYPH="○"
LOCAL_GLYPH="◐"       # For Phase 3 (list command)
```

### Startup Initialization

Add automatic initialization inside the execution gate to avoid running during test sourcing:

**File**: `ai-rizz` (inside execution gate, before command parsing)

```bash
# Initialize ai-rizz state at startup (two-phase to avoid circular dependencies)
initialize_ai_rizz() {
    # Phase 1: Minimal detection and migration (file-based only)
    detect_manifest_files_only
    migrate_legacy_repository_if_needed
    
    # Phase 2: Full initialization with directory checking  
    detect_initialized_modes
    cache_manifest_metadata
}

# Only run main code if script is executed, not sourced
if [ "${0##*/}" = "ai-rizz" ]; then
    # Initialize only when executed, not when sourced for testing
    initialize_ai_rizz
    
    # Parse command
    if [ $# -eq 0 ]; then
        cmd_help
        exit 0
    fi
    # ... rest of existing command parsing logic
fi
```

### Mode Detection Utilities

**File**: `ai-rizz` (add after utilities section)

```bash
# Mode Detection Utilities
# ========================

# Phase 1: Minimal manifest file detection (no directory dependency)
detect_manifest_files_only() {
    # Quick check - just look for files, don't validate directories yet
    if [ -f "$LOCAL_MANIFEST_FILE" ]; then
        HAS_LOCAL_MODE=true
    else
        HAS_LOCAL_MODE=false
    fi
    
    if [ -f "$COMMIT_MANIFEST_FILE" ]; then
        HAS_COMMIT_MODE=true
    else
        HAS_COMMIT_MODE=false
    fi
}

# Phase 2: Full mode detection including directory validation
detect_initialized_modes() {
    HAS_LOCAL_MODE=false
    HAS_COMMIT_MODE=false
    
    # Get target directory or error if none available
    target_base=$(get_target_directory)
    
    # Check for local mode (manifest + directory)
    if [ -f "$LOCAL_MANIFEST_FILE" ] && [ -d "$target_base/$LOCAL_DIR" ]; then
        HAS_LOCAL_MODE=true
    fi
    
    # Check for commit mode (manifest + directory)  
    if [ -f "$COMMIT_MANIFEST_FILE" ] && [ -d "$target_base/$SHARED_DIR" ]; then
        HAS_COMMIT_MODE=true
    fi
}

# Get target directory from available manifests (returns via stdout)
get_target_directory() {
    # Try commit manifest first
    if [ -f "$COMMIT_MANIFEST_FILE" ]; then
        metadata=$(read_manifest_metadata "$COMMIT_MANIFEST_FILE") || {
            error "Failed to read commit manifest metadata"
        }
        echo "$metadata" | cut -f2
        return 0
    fi
    
    # Try local manifest
    if [ -f "$LOCAL_MANIFEST_FILE" ]; then
        metadata=$(read_manifest_metadata "$LOCAL_MANIFEST_FILE") || {
            error "Failed to read local manifest metadata"
        }
        echo "$metadata" | cut -f2
        return 0
    fi
    
    # No manifests available - use default only during initialization
    echo "$DEFAULT_TARGET_DIR"
}

# Cache manifest metadata in globals for efficiency
cache_manifest_metadata() {
    # Cache commit manifest metadata
    if [ -f "$COMMIT_MANIFEST_FILE" ]; then
        metadata=$(read_manifest_metadata "$COMMIT_MANIFEST_FILE") || {
            error "Failed to read commit manifest metadata"
        }
        COMMIT_SOURCE_REPO=$(echo "$metadata" | cut -f1)
        COMMIT_TARGET_DIR=$(echo "$metadata" | cut -f2)
    fi
    
    # Cache local manifest metadata
    if [ -f "$LOCAL_MANIFEST_FILE" ]; then
        metadata=$(read_manifest_metadata "$LOCAL_MANIFEST_FILE") || {
            error "Failed to read local manifest metadata"
        }
        LOCAL_SOURCE_REPO=$(echo "$metadata" | cut -f1)
        LOCAL_TARGET_DIR=$(echo "$metadata" | cut -f2)
    fi
}
```

### Legacy Migration Detection

**File**: `ai-rizz` (add after mode detection utilities)

```bash
# Legacy Migration Utilities
# ==========================

# Detect if repository needs migration from single-mode to progressive format
needs_migration() {
    # Legacy local mode: ai-rizz.inf exists but is in .git/info/exclude
    if [ -f "$COMMIT_MANIFEST_FILE" ] && [ -f ".git/info/exclude" ]; then
        if grep -q "^$COMMIT_MANIFEST_FILE$" ".git/info/exclude"; then
            return 0  # true, needs migration from legacy local
        fi
    fi
    
    return 1  # false, no migration needed
}

# Migrate legacy repository to progressive format  
migrate_legacy_repository_if_needed() {
    if ! needs_migration; then
        return 0  # No migration needed
    fi
    
    # Get target directory from existing manifest
    if [ -f "$COMMIT_MANIFEST_FILE" ]; then
        metadata=$(read_manifest_metadata "$COMMIT_MANIFEST_FILE") || {
            error "Failed to read legacy manifest metadata"
        }
        legacy_target_dir=$(echo "$metadata" | cut -f2)
        
        # Migrate legacy local mode to new format
        migrate_legacy_local_mode "$legacy_target_dir"
    fi
}

# Migrate from legacy local mode (ai-rizz.inf in git exclude) to new format
migrate_legacy_local_mode() {
    legacy_target_dir="$1"
    
    # 1. Rename manifest file
    mv "$COMMIT_MANIFEST_FILE" "$LOCAL_MANIFEST_FILE"
    
    # 2. Move rules from shared to local directory
    if [ -d "$legacy_target_dir/$SHARED_DIR" ]; then
        mkdir -p "$legacy_target_dir/$LOCAL_DIR"
        if [ "$(ls -A "$legacy_target_dir/$SHARED_DIR" 2>/dev/null)" ]; then
            mv "$legacy_target_dir/$SHARED_DIR"/* "$legacy_target_dir/$LOCAL_DIR/"
        fi
        rmdir "$legacy_target_dir/$SHARED_DIR"
    fi
    
    # 3. Update .git/info/exclude entries
    update_git_exclude "$COMMIT_MANIFEST_FILE" "remove"
    update_git_exclude "$legacy_target_dir/$SHARED_DIR" "remove"  
    update_git_exclude "$LOCAL_MANIFEST_FILE" "add"
    update_git_exclude "$legacy_target_dir/$LOCAL_DIR" "add"
}
```

**Validation Point**: After implementing Phase 2.1, run `make test`. Expected result: `test_mode_detection.test.sh` should start passing or showing different failure patterns. Migration tests should now be able to control when migration occurs (initialization only runs when script is executed, not when sourced for testing).

## Phase 2.2: Progressive Manifest Handling

### Manifest Reading Utilities

Replace the existing `read_manifest()` function entirely:

**File**: `ai-rizz` (replace existing read_manifest function)

```bash
# Progressive Manifest Utilities  
# ==============================

# Read manifest metadata line (returns "source_repo\ttarget_dir" via stdout)
read_manifest_metadata() {
    manifest_file="$1"
    
    if [ ! -f "$manifest_file" ]; then
        return 1
    fi
    
    # Read first line
    read -r first_line < "$manifest_file"
    
    # Validate format
    if ! echo "$first_line" | grep -q "	"; then
        error "Invalid manifest format in $manifest_file: First line must be 'source_repo<tab>target_dir'"
    fi
    
    echo "$first_line"
}

# Read manifest entries (returns entries via stdout, one per line)
read_manifest_entries() {
    manifest_file="$1"
    
    if [ ! -f "$manifest_file" ]; then
        return 1
    fi
    
    # Skip first line (metadata), return rest
    tail -n +2 "$manifest_file" | grep -v '^$'
}

# Write manifest with metadata and entries from stdin
write_manifest_with_entries() {
    manifest_file="$1"
    source_repo="$2"
    target_dir="$3"
    
    # Write header
    echo "$source_repo	$target_dir" > "$manifest_file"
    
    # Append entries from stdin (if any)
    cat >> "$manifest_file"
}

# Add entry to manifest file
add_manifest_entry() {
    manifest_file="$1"
    entry="$2"
    
    # Check if entry already exists
    if [ -f "$manifest_file" ]; then
        if read_manifest_entries "$manifest_file" | grep -q "^$entry$"; then
            return 0  # Already exists
        fi
    fi
    
    # Add the entry
    echo "$entry" >> "$manifest_file"
}

# Remove entry from manifest file
remove_manifest_entry() {
    manifest_file="$1"
    entry="$2"
    
    if [ ! -f "$manifest_file" ]; then
        return 0  # Nothing to remove
    fi
    
    # Get metadata
    metadata=$(read_manifest_metadata "$manifest_file") || {
        error "Failed to read manifest metadata from $manifest_file"
    }
    
    # Get entries excluding the one to remove
    entries=$(read_manifest_entries "$manifest_file" | grep -v "^$entry$")
    
    # Rewrite manifest
    source_repo=$(echo "$metadata" | cut -f1)
    target_dir=$(echo "$metadata" | cut -f2)
    
    echo "$entries" | write_manifest_with_entries "$manifest_file" "$source_repo" "$target_dir"
}

# Get any available manifest metadata (for lazy initialization)
get_any_manifest_metadata() {
    # Try commit manifest first
    if [ -f "$COMMIT_MANIFEST_FILE" ]; then
        read_manifest_metadata "$COMMIT_MANIFEST_FILE"
        return $?
    fi
    
    # Try local manifest
    if [ -f "$LOCAL_MANIFEST_FILE" ]; then
        read_manifest_metadata "$LOCAL_MANIFEST_FILE"
        return $?
    fi
    
    # No manifests available
    return 1
}
```

**Validation Point**: After implementing Phase 2.2, run `make test`. Expected result: Tests that read manifest contents should start showing different behavior.

## Phase 2.3: Git Exclude Management

### Enhanced Git Exclude Utilities

Update the existing `update_git_exclude` function to handle multiple modes:

**File**: `ai-rizz` (replace existing update_git_exclude function)

```bash
# Git Exclude Management  
# ======================

# Update .git/info/exclude for specific paths
update_git_exclude() {
    path="$1"
    action="$2"  # "add" or "remove"
    
    # Create .git/info directory if it doesn't exist
    mkdir -p ".git/info"
    
    # Create exclude file if it doesn't exist  
    touch ".git/info/exclude"
    
    case "$action" in
        add)
            if ! grep -q "^$path$" ".git/info/exclude"; then
                echo "$path" >> ".git/info/exclude"
            fi
            ;;
        remove)
            # Create a temporary file
            tmp_file=$(mktemp)
            # Filter out the path
            grep -v "^$path$" ".git/info/exclude" > "$tmp_file"
            # Replace the original file
            cat "$tmp_file" > ".git/info/exclude"
            # Remove the temporary file
            rm -f "$tmp_file"
            ;;
        *)
            error "Invalid action: $action. Must be 'add' or 'remove'"
            ;;
    esac
}

# Setup git excludes for local mode
setup_local_mode_excludes() {
    target_dir="$1"
    
    update_git_exclude "$LOCAL_MANIFEST_FILE" "add"
    update_git_exclude "$target_dir/$LOCAL_DIR" "add"
}

# Remove all local mode excludes
remove_local_mode_excludes() {
    target_dir="$1"
    
    update_git_exclude "$LOCAL_MANIFEST_FILE" "remove"
    update_git_exclude "$target_dir/$LOCAL_DIR" "remove"
}

# Validate git exclude state matches mode configuration
validate_git_exclude_state() {
    target_dir="$1"
    
    if [ "$HAS_LOCAL_MODE" = "true" ]; then
        # Local mode should be excluded
        if [ ! -f ".git/info/exclude" ] || ! grep -q "^$LOCAL_MANIFEST_FILE$" ".git/info/exclude"; then
            warn "Local manifest file not in git exclude (should be git-ignored)"
        fi
        if [ ! -f ".git/info/exclude" ] || ! grep -q "^$target_dir/$LOCAL_DIR$" ".git/info/exclude"; then
            warn "Local directory not in git exclude (should be git-ignored)"
        fi
    fi
    
    if [ "$HAS_COMMIT_MODE" = "true" ]; then
        # Commit mode should NOT be excluded
        if [ -f ".git/info/exclude" ] && grep -q "^$COMMIT_MANIFEST_FILE$" ".git/info/exclude"; then
            warn "Commit manifest file in git exclude (should be git-tracked)"
        fi
        if [ -f ".git/info/exclude" ] && grep -q "^$target_dir/$SHARED_DIR$" ".git/info/exclude"; then
            warn "Shared directory in git exclude (should be git-tracked)"
        fi
    fi
}
```

**Validation Point**: After implementing Phase 2.3, run `make test`. Expected result: Tests checking git exclude state should start passing.

## Phase 2.4: Lazy Initialization & Multi-Mode Sync

### Lazy Initialization Infrastructure

**File**: `ai-rizz` (add after git exclude utilities)

```bash
# Lazy Initialization Utilities
# =============================

# Initialize a mode that doesn't exist yet, copying metadata from existing mode
lazy_init_mode() {
    target_mode="$1"  # "local" or "commit"
    
    # Get metadata from any existing manifest
    metadata=$(get_any_manifest_metadata) || {
        error "No manifest available to copy metadata from for lazy initialization"
    }
    
    source_repo=$(echo "$metadata" | cut -f1)
    target_dir=$(echo "$metadata" | cut -f2)
    
    case "$target_mode" in
        local)
            # Create local mode structure
            mkdir -p "$target_dir/$LOCAL_DIR"
            
            # Write empty manifest with metadata
            echo "" | write_manifest_with_entries "$LOCAL_MANIFEST_FILE" "$source_repo" "$target_dir"
            
            # Update git excludes
            setup_local_mode_excludes "$target_dir"
            
            # Update mode state and cache
            HAS_LOCAL_MODE=true
            LOCAL_SOURCE_REPO="$source_repo"
            LOCAL_TARGET_DIR="$target_dir"
            ;;
            
        commit)
            # Create commit mode structure  
            mkdir -p "$target_dir/$SHARED_DIR"
            
            # Write empty manifest with metadata
            echo "" | write_manifest_with_entries "$COMMIT_MANIFEST_FILE" "$source_repo" "$target_dir"
            
            # Update mode state and cache
            HAS_COMMIT_MODE=true
            COMMIT_SOURCE_REPO="$source_repo"
            COMMIT_TARGET_DIR="$target_dir"
            ;;
            
        *)
            error "Invalid target mode: $target_mode. Must be 'local' or 'commit'"
            ;;
    esac
}

# Check if lazy initialization is needed for a mode (returns 0 if needed)
needs_lazy_init() {
    target_mode="$1"
    
    case "$target_mode" in
        local)
            [ "$HAS_LOCAL_MODE" = "false" ] && [ "$HAS_COMMIT_MODE" = "true" ]
            ;;
        commit)
            [ "$HAS_COMMIT_MODE" = "false" ] && [ "$HAS_LOCAL_MODE" = "true" ]
            ;;
        *)
            return 1
            ;;
    esac
}
```

### Multi-Mode Sync Behavior

Replace the existing sync command behavior (keep the command interface unchanged):

**File**: `ai-rizz` (find and replace cmd_sync function)

```bash
# Sync command - multi-mode behavior
cmd_sync() {
    # Ensure git repository context
    if [ ! -d ".git" ]; then
        error "Not in a git repository"
    fi
    
    # Get source repo from any available manifest
    source_repo=""
    if [ -n "$COMMIT_SOURCE_REPO" ]; then
        source_repo="$COMMIT_SOURCE_REPO"
    elif [ -n "$LOCAL_SOURCE_REPO" ]; then
        source_repo="$LOCAL_SOURCE_REPO"
    fi
    
    # Sync repository first
    if [ -n "$source_repo" ]; then
        git_sync "$source_repo"
    fi
    
    # Sync all initialized modes
    sync_all_modes
}

# Sync all available manifests to their target directories
sync_all_modes() {
    sync_success=true
    
    # Sync commit mode if initialized
    if [ "$HAS_COMMIT_MODE" = "true" ]; then
        sync_manifest_to_directory "$COMMIT_MANIFEST_FILE" "$COMMIT_TARGET_DIR/$SHARED_DIR" || sync_success=false
    fi
    
    # Sync local mode if initialized  
    if [ "$HAS_LOCAL_MODE" = "true" ]; then
        sync_manifest_to_directory "$LOCAL_MANIFEST_FILE" "$LOCAL_TARGET_DIR/$LOCAL_DIR" || sync_success=false
    fi
    
    # Handle any cleanup needed
    if [ "$sync_success" = "false" ]; then
        handle_sync_cleanup
    fi
}

# Sync a single manifest to its target directory
sync_manifest_to_directory() {
    manifest_file="$1"
    target_directory="$2"
    
    if [ ! -f "$manifest_file" ]; then
        return 0  # No manifest to sync
    fi
    
    # Create target directory if needed
    mkdir -p "$target_directory"
    
    # Get entries from manifest
    entries=$(read_manifest_entries "$manifest_file") || {
        warn "Failed to read entries from $manifest_file"
        return 1
    }
    
    # Copy each entry
    if [ -n "$entries" ]; then
        echo "$entries" | while IFS= read -r entry; do
            if [ -n "$entry" ]; then
                copy_entry_to_target "$entry" "$target_directory" || return 1
            fi
        done
    fi
}

# Copy a single entry (rule or ruleset) to target directory
copy_entry_to_target() {
    entry="$1"
    target_directory="$2"
    
    source_path="$REPO_DIR/$entry"
    
    if [ -f "$source_path" ]; then
        # Single file (rule)
        cp "$source_path" "$target_directory/"
    elif [ -d "$source_path" ]; then
        # Directory (ruleset) - copy recursively
        cp -r "$source_path" "$target_directory/"
    else
        warn "Entry not found in repository: $entry"
        return 1
    fi
}

# Handle cleanup after sync issues
handle_sync_cleanup() {
    # Re-cache manifest metadata to ensure consistency
    cache_manifest_metadata
    
    # Validate git exclude state
    target_dir=$(get_target_directory)
    validate_git_exclude_state "$target_dir"
}
```

**Validation Point**: After implementing Phase 2.4, run `make test`. Expected result: 2-3 tests should now pass, showing measurable progress.

## Phase 2 Validation & Testing

### Validation Criteria

After completing all sub-phases, expect:

1. **Test Progress**: 2-3 out of 8 tests passing (specific targets: `test_mode_detection.test.sh`, parts of migration tests)
2. **Timeout vs Assertion Changes**: 
   - Timeouts remain (command interface unchanged) 
   - Assertion failures become passes (infrastructure works)
3. **No Script Syntax Errors**: All new functions should be syntactically correct
4. **Clean Architecture**: No global state pollution in function returns

### Testing Each Sub-Phase

Run after each sub-phase:
```bash
make test
```

**Expected progression**:
- Phase 2.1: Mode detection tests show different failure patterns
- Phase 2.2: Manifest reading assertions start passing  
- Phase 2.3: Git exclude assertions start passing
- Phase 2.4: Full infrastructure tests pass, lazy init starts working

### Validation Commands

Test the infrastructure manually:
```bash
# Test mode detection
ai-rizz list  # Should not crash, may timeout on input prompts

# Test sync behavior  
ai-rizz sync  # Should handle multiple modes gracefully
```

## Success Metrics & Next Phase Preparation

### Phase 2 Success Criteria

1. **Measurable Progress**: 2-3/8 tests passing (up from 0/8)
2. **Infrastructure Complete**: All utility functions implemented and working
3. **Clean Architecture**: Functions return via stdout/return codes, not global pollution
4. **No Regressions**: Existing functionality not broken worse than expected
5. **Clean Foundation**: Phase 3 can focus purely on command interface updates

### Transition to Phase 3

Phase 2 provides the foundation for Phase 3 command interface updates:
- Mode detection: ✅ Available via `$HAS_LOCAL_MODE` / `$HAS_COMMIT_MODE` checks
- Lazy initialization: ✅ Available via `lazy_init_mode()` function  
- Multi-mode sync: ✅ Available via `sync_all_modes()` function
- Migration: ✅ Available via automatic startup migration

Phase 3 will update command parsing and interfaces to use this infrastructure, converting timeouts to passes and completing the progressive initialization system.

## Implementation Notes

### File Modification Strategy

1. **Global Variables**: Replace entire section (~lines 10-15)
2. **Initialization Function**: Add `initialize_ai_rizz()` function in utilities section
3. **Initialization Call**: Add inside execution gate, before command parsing
4. **Utilities**: Replace existing functions entirely where noted
5. **New Functions**: Add in the sections specified

### Migration Timing Strategy

- **Phase 1 Detection**: Uses only file existence (no TARGET_DIR dependency)
- **Migration Trigger**: Happens after minimal detection, before full mode detection
- **Test Compatibility**: Tests can setup legacy state and control when migration occurs
- **Circular Dependency Avoided**: Migration completes before directory-based mode detection
- **Execution Gate**: Initialization only runs when script is executed, not when sourced for testing

### Error Handling

All new functions include proper error handling:
- Invalid modes return clear error messages
- Missing files are handled gracefully  
- Git operations are validated
- Temporary files are cleaned up properly

### Performance Considerations

- Manifest metadata cached in globals for efficiency
- Minimal file I/O operations
- Efficient string processing using cut/grep
- Proper cleanup of temporary resources

---

**Next Steps**: 
1. Implement Phase 2.1 (mode detection)
2. Validate with `make test`
3. Proceed through sub-phases with validation at each step
4. Achieve 2-3/8 tests passing before proceeding to Phase 3 