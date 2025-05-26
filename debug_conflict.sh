#!/bin/sh

# Debug script for conflict resolution
set -e

# Source ai-rizz
. ./ai-rizz

# Setup test environment
rm -rf test_target ai-rizz.inf ai-rizz.local.inf .git/info/exclude
mkdir -p .git/info
touch .git/info/exclude

# Initialize test repo
mkdir -p ~/.config/ai-rizz/repo/rules
echo "test rule content" > ~/.config/ai-rizz/repo/rules/rule1.mdc

# Initialize ai-rizz state
initialize_ai_rizz

echo "=== Step 1: Initialize local mode ==="
cmd_init "test_repo" -d "test_target" --local
echo "HAS_LOCAL_MODE: $HAS_LOCAL_MODE"
echo "HAS_COMMIT_MODE: $HAS_COMMIT_MODE"

echo "=== Step 2: Add rule to local mode ==="
cmd_add_rule "rule1.mdc" --local
echo "Local manifest content:"
cat ai-rizz.local.inf
echo "Files in local dir:"
ls -la test_target/local/ || echo "No local dir"

echo "=== Step 3: Add rule to commit mode (should migrate) ==="
cmd_add_rule "rule1.mdc" --commit
echo "HAS_LOCAL_MODE: $HAS_LOCAL_MODE"
echo "HAS_COMMIT_MODE: $HAS_COMMIT_MODE"
echo "Local manifest content:"
cat ai-rizz.local.inf
echo "Commit manifest content:"
cat ai-rizz.inf
echo "Files in local dir:"
ls -la test_target/local/ || echo "No local dir"
echo "Files in shared dir:"
ls -la test_target/shared/ || echo "No shared dir"

echo "=== Step 4: Manually add duplicate entry ==="
echo "rules/rule1.mdc" >> ai-rizz.local.inf
echo "Local manifest content after manual addition:"
cat ai-rizz.local.inf

echo "=== Step 5: Run sync ==="
cmd_sync
echo "Local manifest content after sync:"
cat ai-rizz.local.inf
echo "Files in local dir:"
ls -la test_target/local/ || echo "No local dir"
echo "Files in shared dir:"
ls -la test_target/shared/ || echo "No shared dir"

echo "=== Step 6: Check for duplicates ==="
if grep -q "rules/rule1.mdc" ai-rizz.local.inf; then
    echo "ERROR: Duplicate still exists in local manifest"
    exit 1
else
    echo "SUCCESS: Duplicate removed from local manifest"
fi 