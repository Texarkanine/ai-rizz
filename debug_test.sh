#!/bin/bash

# Debug script to trace the exact test failure
set -e

# Create a temporary test directory
TEST_DIR="$(mktemp -d)"
cd "$TEST_DIR" || exit 1

echo "Working in: $TEST_DIR"

# Set up test environment like the tests do
SOURCE_REPO="test_repo"
TARGET_DIR="test_target"
COMMIT_MANIFEST_FILE="ai-rizz.inf"
LOCAL_MANIFEST_FILE="ai-rizz.local.inf"
LOCAL_DIR="local"
SHARED_DIR="shared"

# Set REPO_DIR to point to the test repo
TEST_REPO_DIR="$TEST_DIR/$SOURCE_REPO"

# Create repo directory structure
mkdir -p "$TEST_REPO_DIR/rules"
echo "Rule 1 content" > "$TEST_REPO_DIR/rules/rule1.mdc"

# Initialize test_repo as a git repository
cd "$TEST_REPO_DIR" || exit 1
git init . >/dev/null 2>&1
git add . >/dev/null 2>&1
git commit -m "Initial commit" >/dev/null 2>&1
cd "$TEST_DIR" || exit 1

# Initialize current directory as git repo
git init . >/dev/null 2>&1

# Source ai-rizz
source /home/mobaxterm/Documents/git/ai-rizz/ai-rizz

# Override REPO_DIR after sourcing
REPO_DIR="$TEST_REPO_DIR"

# Override git_sync function like the tests do
git_sync() {
  repo_url="$1"
  case "$repo_url" in
    invalid://*|*nonexistent*)
      warn "Failed to clone repository: $repo_url (repository unavailable or invalid URL)"
      return 1
      ;;
    *)
      if [ ! -d "$REPO_DIR" ]; then
        echo "ERROR: Test repo directory not found: $REPO_DIR" >&2
        return 1
      fi
      return 0
      ;;
  esac
}

echo "=== Reproducing the exact failing test ==="

# Setup: Manually create duplicate entries (simulates user error)
echo "Step 1: cmd_init"
cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
echo "✓ Init completed"

echo "Step 2: cmd_add_rule rule1.mdc --local"
cmd_add_rule "rule1.mdc" --local
echo "✓ Added rule to local"

echo "Step 3: cmd_add_rule rule1.mdc --commit (should migrate)"
cmd_add_rule "rule1.mdc" --commit
echo "✓ Added rule to commit (migrated)"

echo "Step 4: Manually add duplicate entry"
echo "rules/rule1.mdc" >> "$LOCAL_MANIFEST_FILE"
echo "✓ Added duplicate entry"

echo "Step 5: Check manifests before sync"
echo "Local manifest:"
cat "$LOCAL_MANIFEST_FILE"
echo "Commit manifest:"
cat "$COMMIT_MANIFEST_FILE"

echo "Step 6: cmd_sync"
cmd_sync
echo "✓ Sync completed"

echo "Step 7: Check file existence"
if [ -f "$TARGET_DIR/$SHARED_DIR/rule1.mdc" ]; then
    echo "✓ assert_file_exists $TARGET_DIR/$SHARED_DIR/rule1.mdc - PASS"
else
    echo "✗ assert_file_exists $TARGET_DIR/$SHARED_DIR/rule1.mdc - FAIL"
    exit 1
fi

if [ ! -f "$TARGET_DIR/$LOCAL_DIR/rule1.mdc" ]; then
    echo "✓ assert_file_not_exists $TARGET_DIR/$LOCAL_DIR/rule1.mdc - PASS"
else
    echo "✗ assert_file_not_exists $TARGET_DIR/$LOCAL_DIR/rule1.mdc - FAIL"
    exit 1
fi

echo "Step 8: Check manifest content"
local_content=$(cat "$LOCAL_MANIFEST_FILE")
echo "Local manifest content: '$local_content'"

echo "Step 9: Test the grep condition"
if echo "$local_content" | grep -q "rule1.mdc"; then
    echo "✗ Found rule1.mdc in local manifest - this should cause test failure"
    echo "This means the duplicate was NOT removed as expected"
    exit 1
else
    echo "✓ rule1.mdc not found in local manifest - duplicate correctly removed"
fi

echo "All checks passed - test should succeed"

# Cleanup
cd /
rm -rf "$TEST_DIR" 