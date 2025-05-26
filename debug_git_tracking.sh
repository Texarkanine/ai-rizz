#!/bin/bash

# Debug script to test git tracking migration
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

# DON'T override git command - we need it for git check-ignore!

# Reset ai-rizz state to ensure clean state
HAS_LOCAL_MODE=false
HAS_COMMIT_MODE=false
COMMIT_SOURCE_REPO=""
LOCAL_SOURCE_REPO=""
COMMIT_TARGET_DIR=""
LOCAL_TARGET_DIR=""

echo "=== Testing git tracking migration ==="

# Setup: Rule in local mode (git-ignored)
cmd_init "$SOURCE_REPO" -d "$TARGET_DIR" --local
cmd_add_rule "rule1.mdc" --local

# Initialize git tracking to verify changes
echo "Adding .git/info/exclude to git..."
git add .git/info/exclude >/dev/null 2>&1
echo "Checking git status..."
git status --porcelain
echo "Committing initial setup..."
git commit -m "Initial local setup" >/dev/null 2>&1 || echo "No changes to commit"
echo "Git setup complete"

echo "Before migration, git exclude contains:"
cat .git/info/exclude

echo "Before migration, checking if file is git-ignored:"
if git check-ignore "$TARGET_DIR/$SHARED_DIR/rule1.mdc" 2>/dev/null; then
    echo "File is git-ignored (expected for local mode)"
else
    echo "File is NOT git-ignored"
fi

# Test: Migrate to commit mode
cmd_add_rule "rule1.mdc" --commit

echo "After migration, git exclude contains:"
cat .git/info/exclude

echo "After migration, checking if file is git-ignored:"
if git check-ignore "$TARGET_DIR/$SHARED_DIR/rule1.mdc" 2>/dev/null; then
    echo "ERROR: File should NOT be git-ignored after migration"
    exit 1
else
    echo "SUCCESS: File is not git-ignored after migration"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR" 