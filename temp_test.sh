#!/bin/sh
. "./tests/common.sh"
source_ai_rizz
cmd_init "test_repo" -d "test_target" --local
cmd_add_rule "rule1.mdc" --commit
echo "About to run deinit test..."
output=$(echo "" | cmd_deinit 2>&1 || echo "ERROR_OCCURRED")
echo "After deinit test, output: $output"
