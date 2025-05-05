# ai-rizz Implementation Plan

## Phase 1: Core Infrastructure

1. **Project Setup**
   - Create basic project structure
   - Set up version control
   - Create README with installation and usage instructions
   - Create test environment
   - Document dependencies (git, core POSIX utilities)

2. **Core Utilities Implementation**

   These utilities are created to:
   - Reduce code duplication
   - Centralize error handling
   - Provide consistent behavior across commands
   - Make the main command implementations cleaner and more readable

   ### File Operations
   
   ```sh
   # Create directory if it doesn't exist, with parent directories
   # Returns 0 on success, 1 on error
   mkdir_p() {
     # $1: directory path
   }
   ```
   *Why*: POSIX `mkdir -p` exists but we want consistent error handling and logging
   
   ```sh
   # Safely remove a file or directory
   # Returns 0 on success, 1 on error
   safe_rm() {
     # $1: path to remove
     # $2: (optional) force flag
   }
   ```
   *Why*: Centralizes safe deletion with proper error handling and logging
   
   ```sh
   # Copy a file, creating parent directories if needed
   # Returns 0 on success, 1 on error
   safe_cp() {
     # $1: source path
     # $2: destination path
   }
   ```
   *Why*: Combines mkdir_p and cp with proper error handling
   
   ### Git Operations
   
   ```sh
   # Clone or update a git repository
   # Returns 0 on success, 1 on error
   git_sync() {
     # $1: repository URL
     # $2: target directory
   }
   ```
   *Why*: Handles both initial clone and subsequent updates in one operation
   
   ### Manifest Operations
   
   ```sh
   # Read and validate manifest file
   # Returns 0 on success, 1 on error
   read_manifest() {
     # $1: manifest path
     # Sets global variables:
     #   - SOURCE_REPO
     #   - TARGET_DIR
     #   - MANIFEST_ENTRIES (array)
   }
   ```
   *Why*: Centralizes manifest parsing and validation
   
   ```sh
   # Write manifest file
   # Returns 0 on success, 1 on error
   write_manifest() {
     # $1: manifest path
     # Uses global variables:
     #   - SOURCE_REPO
     #   - TARGET_DIR
     #   - MANIFEST_ENTRIES (array)
   }
   ```
   *Why*: Ensures consistent manifest formatting
   
   ```sh
   # Add entry to manifest
   # Returns 0 on success, 1 on error
   add_manifest_entry() {
     # $1: entry to add
   }
   ```
   *Why*: Prevents duplicate entries and maintains manifest format
   
   ```sh
   # Remove entry from manifest
   # Returns 0 on success, 1 on error
   remove_manifest_entry() {
     # $1: entry to remove
   }
   ```
   *Why*: Centralizes entry removal with proper array manipulation
   
   ### Mode Detection
   
   ```sh
   # Detect if we're in local mode
   # Returns 0 if local mode, 1 if commit mode
   is_local_mode() {
     # $1: target directory
   }
   ```
   *Why*: Centralizes mode detection logic
   
   ```sh
   # Update .git/info/exclude
   # Returns 0 on success, 1 on error
   update_git_exclude() {
     # $1: path to add/remove
     # $2: "add" or "remove"
   }
   ```
   *Why*: Handles both adding and removing entries with proper error checking

   ### Error Handling
   
   ```sh
   # Log an error message and exit
   die() {
     # $1: error message
     # $2: (optional) exit code
   }
   ```
   *Why*: Centralizes error handling and exit behavior
   
   ```sh
   # Log a warning message
   warn() {
     # $1: warning message
   }
   ```
   *Why*: Ensures consistent warning format

3. **Configuration Management**
   - Implement `$HOME/.config/ai-rizz/` directory handling
   - Create configuration file structure
   - Implement source repository management
   - Add configuration validation
   - Implement manifest handling in local mode (add to .git/info/exclude)

## Phase 2: Command Implementation

4. **Init Command**
   - Implement source repository validation
   - Create manifest file handling
   - Implement local vs commit mode detection
   - Add `.git/info/exclude` management
   - Create user prompts and input validation
   - Ensure manifest is ignored in local mode

5. **Deinit Command**
   - Implement cleanup procedures
   - Add confirmation prompts
   - Create safe deletion mechanisms
   - Handle both local and commit modes
   - Remove manifest from .git/info/exclude in local mode

6. **List Command**
   - Implement source repository updating
   - Create ruleset and rule listing
   - Add manifest comparison
   - Implement pretty-printing of results
   - Add warning system for invalid manifest entries

7. **Add/Remove Commands**
   - Implement rule addition/removal to/from target_directory/shared
   - Create ruleset addition/removal
   - Add manifest updates
   - Implement file operations
   - Handle symlink creation for rulesets

8. **Sync Command**
   - Create source repository updating
   - Implement manifest validation
   - Add file synchronization to target_directory/shared
   - Create error recovery
   - Handle invalid manifest entries

## Phase 3: Testing and Documentation

9. **Testing**
   - Create test suite for each command
   - Implement integration tests
   - Add error case testing
   - Test idempotency of operations
   - Test manifest validation and cleanup
   - Test local vs commit mode behaviors

10. **Documentation**
    - Create man pages
    - Add help text for each command
    - Document error messages
    - Create troubleshooting guide
    - Document directory structure and manifest format
    - Document dependencies and requirements

## Phase 4: Polish and Release

11. **Performance Optimization**
    - Profile and optimize file operations
    - Improve error handling
    - Add caching where appropriate
    - Ensure idempotency of all operations

12. **Release Preparation**
    - Create installation scripts
    - Add version management
    - Create release documentation
    - Set up CI/CD pipeline
    - Document POSIX compliance

## Implementation Details

### Directory Structure
- Manifest (`airizz.inf`) lives in repository root
- All source files copied to `target_directory/shared`
- Source repository cloned to `$HOME/.config/ai-rizz/`

### Error Handling
- Idempotent operations
- Fast failure on invalid manifest
- Warning and cleanup for invalid manifest entries
- Trust git operations (user can retry)
- Assume sufficient permissions

### Dependencies
- git
- Core POSIX utilities
- Additional dependencies to be documented during implementation

## Next Steps

1. Begin Phase 1 implementation
2. Create detailed technical specifications for each component
3. Set up development environment
4. Document all dependencies as they are identified 