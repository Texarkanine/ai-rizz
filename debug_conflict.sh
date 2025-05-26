#!/bin/bash

# Debug script to isolate the failing test issue
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

# Initialize current directory as git repo for testing
git init . >/dev/null 2>&1
git config user.email "test@example.com" >/dev/null 2>&1
git config user.name "Test User" >/dev/null 2>&1
mkdir -p .git/info
touch .git/info/exclude

# Source ai-rizz
source /home/mobaxterm/Documents/git/ai-rizz/ai-rizz

# Override REPO_DIR after sourcing (this is critical!)
REPO_DIR="$TEST_REPO_DIR"

# Override git_sync function like the tests do
git_sync() {
  repo_url="$1"
  
  # Simulate failure for invalid URLs
  case "$repo_url" in
    invalid://*|*nonexistent*)
      warn "Failed to clone repository: $repo_url (repository unavailable or invalid URL)"
      return 1
      ;;
    *)
      # For valid URLs, just ensure the test repo directory exists
      if [ ! -d "$REPO_DIR" ]; then
        echo "ERROR: Test repo directory not found: $REPO_DIR" >&2
        return 1
      fi
      return 0
      ;;
  esac
}

# DON'T override git command - we need it for actual git operations!

# Reset ai-rizz state to ensure clean state
HAS_LOCAL_MODE=false
HAS_COMMIT_MODE=false
COMMIT_SOURCE_REPO=""
LOCAL_SOURCE_REPO=""
COMMIT_TARGET_DIR=""
LOCAL_TARGET_DIR=""

echo "=== Testing duplicate entries conflict resolution ==="
echo "REPO_DIR is: $REPO_DIR"

# Setup: Manually create duplicate entries (simulates user error)
cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
cmd_add_rule "rule1.mdc" --local
cmd_add_rule "rule1.mdc" --commit  # Should migrate, but manually add back to local

echo "After migration, local manifest contains:"
cat "$LOCAL_MANIFEST_FILE" || echo "Local manifest not found"
echo "After migration, commit manifest contains:"
cat "$COMMIT_MANIFEST_FILE" || echo "Commit manifest not found"

# Manually add duplicate entry to simulate user editing error
echo "rules/rule1.mdc" >> "$LOCAL_MANIFEST_FILE"

echo "After manual duplicate addition, local manifest contains:"
cat "$LOCAL_MANIFEST_FILE"

# Test: Sync should resolve conflict
echo "Running sync..."
cmd_sync

echo "After sync, local manifest contains:"
cat "$LOCAL_MANIFEST_FILE"
echo "After sync, commit manifest contains:"
cat "$COMMIT_MANIFEST_FILE"

# Check if duplicate was removed
local_content=$(cat "$LOCAL_MANIFEST_FILE")
if echo "$local_content" | grep -q "rule1.mdc"; then
    echo "ERROR: Duplicate should be removed from local"
    echo "Local manifest content:"
    cat "$LOCAL_MANIFEST_FILE"
    exit 1
else
    echo "SUCCESS: Duplicate was removed from local"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR" 