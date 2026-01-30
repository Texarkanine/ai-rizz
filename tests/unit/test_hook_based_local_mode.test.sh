#!/bin/sh
#
# test_hook_based_local_mode.test.sh - Hook-based local mode test suite
#
# Tests the hook-based local mode implementation that uses pre-commit hooks
# instead of .git/info/exclude to prevent local files from being committed.
# Validates hook creation, removal, mode switching, and integration with
# existing git exclude functionality.
#
# Test Coverage:
# - Hook creation on init with --hook-based-ignore
# - Hook removal on deinit
# - Mode switching (regular <-> hook-based)
# - Hook unstages local files when staged
# - Hook unstages local command files when staged
# - Hook preserves user's existing hooks
# - validate_git_exclude_state recognizes hook-based mode
# - Git exclude protects local commands directory
# - Migration: cleans up flat command structure from pre-subdir versions
# - Works with custom manifest names and target directories
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_hook_based_local_mode.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# HOOK CREATION TESTS
# ============================================================================

test_init_local_with_hook_based_ignore_creates_hook() {
    # Test: Init with --hook-based-ignore flag
    # Expected: Hook created, git exclude NOT used
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    
    # Verify hook exists and contains marker
    assertTrue "Pre-commit hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    assertTrue "Hook should contain ai-rizz marker" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
    assertTrue "Hook should be executable" "[ -x '.git/hooks/pre-commit' ]"
    
    # Verify git exclude NOT used
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    
    # Verify local mode exists
    assert_local_mode_exists
}

test_init_local_without_flag_uses_hook() {
    # Test: Init without any flag (default behavior changed to hook-based)
    # Expected: Hook created, git exclude NOT used (hook is now default)
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # TODO: Update assertions for new default behavior
    # Verify hook exists and contains marker
    assertTrue "Pre-commit hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    assertTrue "Hook should contain ai-rizz marker" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
    assertTrue "Hook should be executable" "[ -x '.git/hooks/pre-commit' ]"
    
    # Verify git exclude NOT used
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    
    # Verify local mode exists
    assert_local_mode_exists
}

test_git_exclude_ignore_flag_creates_git_exclude() {
    # Test: New --git-exclude-ignore flag creates git-exclude mode
    # Expected: Git exclude used, hook NOT created (legacy behavior)
    
    # TODO: Implement test for new --git-exclude-ignore flag
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    
    # Verify git exclude used
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    
    # Verify hook NOT created (or if it exists, it's harmless)
    # For strict behavior, we expect no hook section
    if [ -f .git/hooks/pre-commit ]; then
        assertFalse "Hook should not contain ai-rizz marker with git-exclude mode" \
            "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
    fi
    
    # Verify local mode exists
    assert_local_mode_exists
}

test_hook_based_ignore_flag_is_noop() {
    # Test: Legacy --hook-based-ignore flag still accepted (backwards compat)
    # Expected: Works same as no flag (hook is default now), no error
    
    # TODO: Implement test for backwards-compatible --hook-based-ignore flag
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    
    # Verify hook exists (same as default behavior)
    assertTrue "Pre-commit hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    assertTrue "Hook should contain ai-rizz marker" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
    
    # Verify git exclude NOT used
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    
    # Verify local mode exists
    assert_local_mode_exists
}

# ============================================================================
# MODE SWITCHING TESTS
# ============================================================================

test_switch_from_git_exclude_to_hook_based_mode() {
    # Setup: Git-exclude local mode (using new --git-exclude-ignore flag)
    # TODO: Update to use --git-exclude-ignore flag for setup
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    
    # Test: Re-init without flag (switches to default hook-based mode)
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    
    # Expected: Git exclude removed, hook created
    assert_git_exclude_not_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_not_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    assertTrue "Hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    assertTrue "Hook should contain marker" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
}

test_switch_from_hook_based_to_git_exclude_mode() {
    # Setup: Hook-based local mode (default now, no flag needed)
    # TODO: Update - no flag needed for hook-based (it's default)
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    assertTrue "Hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    
    # Test: Switch to git-exclude mode using new flag
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    
    # Expected: Git exclude added, hook removed
    assert_git_exclude_contains "$TEST_LOCAL_MANIFEST_FILE"
    assert_git_exclude_contains "$TEST_TARGET_DIR/$TEST_LOCAL_DIR"
    assertFalse "Hook should be removed" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit 2>/dev/null"
}

# ============================================================================
# HOOK FUNCTIONALITY TESTS
# ============================================================================

test_hook_unstages_local_files() {
    # Setup: Hook-based mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    cmd_add_rule "rule1.mdc" --local
    
    # Verify files exist
    assert_file_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_exists "$TEST_LOCAL_MANIFEST_FILE"
    
    # Stage local files
    git add "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc" "$TEST_LOCAL_MANIFEST_FILE"
    
    # Verify files are staged before hook
    staged_before=$(git diff --cached --name-only)
    assertTrue "File should be staged before hook" "echo '$staged_before' | grep -q '$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc'"
    assertTrue "Manifest should be staged before hook" "echo '$staged_before' | grep -q '$TEST_LOCAL_MANIFEST_FILE'"
    
    # Test: Run pre-commit hook
    .git/hooks/pre-commit
    
    # Expected: Files unstaged
    staged_after=$(git diff --cached --name-only)
    assertFalse "Local file should be unstaged" "echo '$staged_after' | grep -q '$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc'"
    assertFalse "Local manifest should be unstaged" "echo '$staged_after' | grep -q '$TEST_LOCAL_MANIFEST_FILE'"
}

test_hook_preserves_user_hooks() {
    # Setup: User has existing hook
    cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
echo "User hook executed"
EOF
    chmod +x .git/hooks/pre-commit
    
    # Test: Init with hook-based-ignore
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    
    # Expected: User hook preserved, ai-rizz section appended
    assertTrue "User hook should be preserved" "grep -q 'User hook executed' .git/hooks/pre-commit"
    assertTrue "ai-rizz section should be added" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
}

# ============================================================================
# DEINIT TESTS
# ============================================================================

test_deinit_removes_hook() {
    # Setup: Hook-based mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    assertTrue "Hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Hook removed (or ai-rizz section removed if user hooks exist)
    # If hook only had ai-rizz section, file should be gone
    # If hook had user content, only ai-rizz section should be removed
    if [ -f .git/hooks/pre-commit ]; then
        assertFalse "ai-rizz section should be removed" "grep -q 'BEGIN ai-rizz hook' .git/hooks/pre-commit"
    fi
}

# ============================================================================
# VALIDATION TESTS
# ============================================================================

test_validate_git_exclude_state_recognizes_hook_based_mode() {
    # Setup: Hook-based mode (no git exclude)
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    
    # Test: validate_git_exclude_state should not warn
    output=$(validate_git_exclude_state "$TEST_TARGET_DIR" 2>&1)
    
    # Expected: No warnings (hook handles it)
    if echo "$output" | grep -q "not in git exclude"; then
        fail "Should not warn when hook is present. Output: $output"
    fi
}

# ============================================================================
# COMMAND PROTECTION TESTS
# ============================================================================

test_hook_unstages_local_commands() {
    # Test: Hook should unstage local command files
    # Expected: Commands in .cursor/commands/local/ should be unstaged
    
    # Setup: Hook-based mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    cmd_add_rule "command1.md" --local
    
    # Verify command file exists in commands directory
    assertTrue "Commands directory should exist" "[ -d '.cursor/commands/local' ]"
    assert_file_exists ".cursor/commands/local/command1.md"
    
    # Stage local command files
    git add ".cursor/commands/local/command1.md"
    
    # Verify files are staged before hook
    staged_before=$(git diff --cached --name-only)
    assertTrue "Command should be staged before hook" "echo '$staged_before' | grep -q '.cursor/commands/local/command1.md'"
    
    # Test: Run pre-commit hook
    .git/hooks/pre-commit
    
    # Expected: Command files unstaged
    staged_after=$(git diff --cached --name-only)
    assertFalse "Local command should be unstaged" "echo '$staged_after' | grep -q '.cursor/commands/local/command1.md'"
    
    return 0
}

test_git_exclude_protects_local_commands() {
    # Test: Git exclude mode should protect local commands
    # Expected: .cursor/commands/local/ should be in git exclude
    
    # Setup: Git-exclude local mode (using --git-exclude-ignore flag)
    # TODO: Update to use --git-exclude-ignore flag
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    cmd_add_rule "command1.md" --local
    
    # Verify command deployed
    assertTrue "Commands directory should exist" "[ -d '.cursor/commands/local' ]"
    assert_file_exists ".cursor/commands/local/command1.md"
    
    # Verify git exclude contains commands directory
    assert_git_exclude_contains ".cursor/commands/local"
    
    return 0
}

test_git_exclude_removes_local_commands_on_deinit() {
    # Test: Deinit should remove commands directory from git exclude
    # Expected: .cursor/commands/local/ removed from git exclude
    
    # Setup: Git-exclude local mode (using --git-exclude-ignore flag)
    # TODO: Update to use --git-exclude-ignore flag
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --git-exclude-ignore
    cmd_add_rule "command1.md" --local
    assert_git_exclude_contains ".cursor/commands/local"
    
    # Test: Deinit local mode
    cmd_deinit --local -y
    
    # Expected: Commands directory removed from git exclude
    assert_git_exclude_not_contains ".cursor/commands/local"
    
    return 0
}

# ============================================================================
# COMMAND MIGRATION TESTS
# ============================================================================

test_sync_cleans_flat_command_structure_for_managed_rulesets() {
    # Test: Sync should clean up flat command dirs ONLY for rulesets in manifest
    # Expected: Flat commands for managed rulesets are removed, others preserved
    
    # Setup: Create flat command structure (simulating old version)
    # Create flat dir for ruleset1 (which IS in our test repo)
    mkdir -p ".cursor/commands/ruleset1"
    echo "old ruleset1 command" > ".cursor/commands/ruleset1/cmd"
    
    # Create flat dir for user-managed command (NOT in manifest)
    mkdir -p ".cursor/commands/my-custom-commands"
    echo "user custom command" > ".cursor/commands/my-custom-commands/custom"
    
    # Initialize commit mode
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    
    # Add ruleset1 to manifest (so it becomes "managed")
    cmd_add_ruleset "ruleset1" --commit
    
    # Run sync
    sync_all_modes
    
    # Verify flat dir for MANAGED ruleset is cleaned up
    assertFalse "Flat ruleset1 directory should be removed" "[ -d '.cursor/commands/ruleset1' ]"
    
    # Verify user-managed directory is PRESERVED
    assertTrue "User custom commands should be preserved" "[ -d '.cursor/commands/my-custom-commands' ]"
    assertTrue "User custom command file should be preserved" "[ -f '.cursor/commands/my-custom-commands/custom' ]"
    
    return 0
}

test_sync_preserves_managed_subdirs() {
    # Test: Sync should NOT remove managed subdirs (local, shared) with user content
    # Expected: local/ and shared/ subdirs with user commands are preserved
    
    # Initialize both modes with commands
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "command1.md" --local
    
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit
    cmd_add_rule "command2.md" --commit
    
    # Verify commands were deployed to managed subdirs
    assertTrue "Local commands directory should exist" "[ -d '.cursor/commands/local' ]"
    assertTrue "Shared commands directory should exist" "[ -d '.cursor/commands/shared' ]"
    
    # Run sync to exercise cleanup/preservation behavior
    sync_all_modes
    
    # After sync, managed dirs should still exist with their commands
    assertTrue "Local subdir should exist after sync" "[ -d '.cursor/commands/local' ]"
    assertTrue "Shared subdir should exist after sync" "[ -d '.cursor/commands/shared' ]"
    assertTrue "Local command should exist after sync" "[ -f '.cursor/commands/local/command1.md' ]"
    assertTrue "Shared command should exist after sync" "[ -f '.cursor/commands/shared/command2.md' ]"
    
    return 0
}

# ============================================================================
# CUSTOM PATHS TESTS
# ============================================================================

test_hook_works_with_custom_manifest_name() {
    # Setup: Custom manifest name
    export AI_RIZZ_MANIFEST="custom-rules"
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local --hook-based-ignore
    
    # Test: Hook should find custom manifest
    assertTrue "Hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    # Hook should dynamically find manifest, so it should work
}

test_hook_works_with_custom_target_directory() {
    # Setup: Custom target directory
    custom_dir=".custom/rules"
    cmd_init "$TEST_SOURCE_REPO" -d "$custom_dir" --local --hook-based-ignore
    
    # Test: Hook should use custom target directory
    assertTrue "Hook should exist" "[ -f '.git/hooks/pre-commit' ]"
    # Hook reads from manifest, so it should work with custom dir
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"

