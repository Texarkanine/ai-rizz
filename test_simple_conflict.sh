#!/bin/sh

# Simple test for conflict resolution
set -e

# Source ai-rizz
. ./ai-rizz

# Create test environment
rm -rf test_env
mkdir test_env
cd test_env

# Initialize git repo
git init . >/dev/null 2>&1
git config user.email "test@example.com" >/dev/null 2>&1
git config user.name "Test User" >/dev/null 2>&1
mkdir -p .git/info
touch .git/info/exclude

# Create test repo structure
mkdir -p test_repo/rules
echo "test content" > test_repo/rules/rule1.mdc

# Set REPO_DIR for testing
REPO_DIR="$(pwd)/test_repo"

# Initialize ai-rizz state
initialize_ai_rizz

echo "=== Simple Conflict Resolution Test ==="

# Step 1: Create manifests manually
echo "test_repo	test_target" > ai-rizz.inf
echo "rules/rule1.mdc" >> ai-rizz.inf

echo "test_repo	test_target" > ai-rizz.local.inf
echo "rules/rule1.mdc" >> ai-rizz.local.inf

echo "Before conflict resolution:"
echo "Commit manifest:"
cat ai-rizz.inf
echo "Local manifest:"
cat ai-rizz.local.inf

# Step 2: Set mode flags
HAS_COMMIT_MODE=true
HAS_LOCAL_MODE=true

# Step 3: Test resolve_conflicts function
echo "Running resolve_conflicts..."
resolve_conflicts

echo "After conflict resolution:"
echo "Commit manifest:"
cat ai-rizz.inf
echo "Local manifest:"
cat ai-rizz.local.inf

# Step 4: Check if conflict was resolved
local_content=$(cat ai-rizz.local.inf)
if echo "$local_content" | grep -q "rules/rule1.mdc"; then
    echo "FAIL: Conflict not resolved - rule still in local manifest"
    exit 1
else
    echo "SUCCESS: Conflict resolved - rule removed from local manifest"
fi

# Cleanup
cd ..
rm -rf test_env 