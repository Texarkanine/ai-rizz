#!/bin/sh

# Detailed debug script to understand the test failure
set -e

# Load common test utilities
. tests/common.sh

# Source the actual implementation from ai-rizz
. ./ai-rizz

# Set up test environment (mimics setUp)
TEST_DIR="$(mktemp -d)"
cd "$TEST_DIR" || exit 1

# Set REPO_DIR to point to the test repo
REPO_DIR="$TEST_DIR/$SOURCE_REPO"

# Create repo directory structure
mkdir -p "$REPO_DIR/rules"
mkdir -p "$REPO_DIR/rulesets/ruleset1"
mkdir -p "$REPO_DIR/rulesets/ruleset2"

# Create rule files
echo "Rule 1 content" > "$REPO_DIR/rules/rule1.mdc"
echo "Rule 2 content" > "$REPO_DIR/rules/rule2.mdc"
echo "Rule 3 content" > "$REPO_DIR/rules/rule3.mdc"

# Create ruleset symlinks
ln -sf "$REPO_DIR/rules/rule1.mdc" "$REPO_DIR/rulesets/ruleset1/rule1.mdc"
ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/ruleset1/rule2.mdc"
ln -sf "$REPO_DIR/rules/rule2.mdc" "$REPO_DIR/rulesets/ruleset2/rule2.mdc"
ln -sf "$REPO_DIR/rules/rule3.mdc" "$REPO_DIR/rulesets/ruleset2/rule3.mdc"

# Initialize test_repo as a git repository
cd "$REPO_DIR" || exit 1
git init . >/dev/null 2>&1
git add . >/dev/null 2>&1
git commit -m "Initial commit" >/dev/null 2>&1
cd "$TEST_DIR" || exit 1

# Create target directory
mkdir -p "$TARGET_DIR/$SHARED_DIR"

# Initialize current directory as git repo for testing
git init . >/dev/null 2>&1
git config user.email "test@example.com" >/dev/null 2>&1
git config user.name "Test User" >/dev/null 2>&1

# Create initial git structure
mkdir -p .git/info
touch .git/info/exclude

# Initialize ai-rizz state
initialize_ai_rizz

echo "=== Detailed Debug: test_resolve_duplicate_entries_commit_wins ==="

echo "Step 1: Initialize local mode"
cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
echo "After init - HAS_LOCAL_MODE: $HAS_LOCAL_MODE, HAS_COMMIT_MODE: $HAS_COMMIT_MODE"

echo "Step 2: Add rule to local mode"
cmd_add_rule "rule1.mdc" --local
echo "After add local - Local manifest:"
cat "$LOCAL_MANIFEST_FILE"
echo "Local dir contents:"
ls -la "$TARGET_DIR/$LOCAL_DIR/" 2>/dev/null || echo "No local dir"

echo "Step 3: Add rule to commit mode (should migrate)"
cmd_add_rule "rule1.mdc" --commit
echo "After add commit - HAS_LOCAL_MODE: $HAS_LOCAL_MODE, HAS_COMMIT_MODE: $HAS_COMMIT_MODE"
echo "Local manifest after migration:"
cat "$LOCAL_MANIFEST_FILE"
echo "Commit manifest after migration:"
cat "$COMMIT_MANIFEST_FILE"

echo "Step 4: Manually add duplicate entry to simulate user editing error"
echo "rules/rule1.mdc" >> "$LOCAL_MANIFEST_FILE"
echo "Local manifest after manual duplicate addition:"
cat "$LOCAL_MANIFEST_FILE"

echo "Step 5: Test resolve_conflicts function directly"
echo "Before resolve_conflicts:"
echo "  Local manifest entries: $(read_manifest_entries "$LOCAL_MANIFEST_FILE" | tr '\n' ' ')"
echo "  Commit manifest entries: $(read_manifest_entries "$COMMIT_MANIFEST_FILE" | tr '\n' ' ')"

resolve_conflicts

echo "After resolve_conflicts:"
echo "  Local manifest entries: $(read_manifest_entries "$LOCAL_MANIFEST_FILE" | tr '\n' ' ')"
echo "  Commit manifest entries: $(read_manifest_entries "$COMMIT_MANIFEST_FILE" | tr '\n' ' ')"

echo "Step 6: Run full sync"
cmd_sync

echo "Step 7: Final state check"
echo "Final local manifest:"
cat "$LOCAL_MANIFEST_FILE"
echo "Final commit manifest:"
cat "$COMMIT_MANIFEST_FILE"

echo "Files in local dir:"
ls -la "$TARGET_DIR/$LOCAL_DIR/" 2>/dev/null || echo "No local dir"
echo "Files in shared dir:"
ls -la "$TARGET_DIR/$SHARED_DIR/" 2>/dev/null || echo "No shared dir"

echo "Step 8: Test the exact assertion that's failing"
local_content=$(cat "$LOCAL_MANIFEST_FILE")
if echo "$local_content" | grep -q "rule1.mdc"; then
    echo "FAIL: Duplicate still exists in local manifest"
    echo "Local manifest content:"
    echo "$local_content"
    echo "Grep result:"
    echo "$local_content" | grep "rule1.mdc" || echo "No matches"
    exit 1
else
    echo "PASS: Duplicate removed from local manifest"
fi

echo "SUCCESS: All checks passed"

# Cleanup
cd /
rm -rf "$TEST_DIR" 