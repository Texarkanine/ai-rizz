#!/bin/bash

echo "=== Testing Migration Functionality ==="
cd /home/mobaxterm/Documents/git/ai-rizz

echo "Running migration tests only..."
bash tests/run_tests.sh tests/unit/test_migration.test.sh 2>&1 | head -30

echo -e "\n=== Summary ==="
echo "If you see timeouts, migration tests still have prompt issues."
echo "If you see test names running without timeouts, migration logic is working!" 