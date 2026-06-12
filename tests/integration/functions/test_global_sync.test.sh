#!/bin/sh
#
# test_global_sync.test.sh - Global mode sync behavior test suite
#
# Tests that ai-rizz sync pulls the global repository cache and redeploys
# global manifest entries, including the --global flag for global-only sync.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_global_sync.test.sh

# shellcheck disable=SC1091
. "$(dirname "$0")/../../common.sh"

source_ai_rizz

# ============================================================================
# TEST SETUP
# ============================================================================

setup_global_test_environment() {
    TEST_HOME="${TEST_DIR}/test_home"
    mkdir -p "${TEST_HOME}/.cursor/rules"
    mkdir -p "${TEST_HOME}/.cursor/commands"

    ORIGINAL_HOME="${HOME}"
    HOME="${TEST_HOME}"
    export HOME

    init_global_paths
}

teardown_global_test_environment() {
    if [ -n "${ORIGINAL_HOME}" ]; then
        HOME="${ORIGINAL_HOME}"
        export HOME
        init_global_paths
    fi
}

# ============================================================================
# GLOBAL SYNC TESTS
# ============================================================================

test_sync_calls_sync_global_repo_when_global_mode_active() {
    setup_global_test_environment

    _SYNC_GLOBAL_REPO_CALLS=0
    sync_global_repo() {
        _SYNC_GLOBAL_REPO_CALLS=$((_SYNC_GLOBAL_REPO_CALLS + 1))
        return 0
    }

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule1.mdc" --global

    _SYNC_GLOBAL_REPO_CALLS=0
    cmd_sync

    assertEquals "cmd_sync should call sync_global_repo when global mode is active" \
        "1" "$_SYNC_GLOBAL_REPO_CALLS"

    teardown_global_test_environment
    return 0
}

test_sync_global_only_updates_global_not_local() {
    setup_global_test_environment

    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_add_rule "rule1.mdc" --local

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule3.mdc" --global

    rm -f "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    rm -f "${GLOBAL_RULES_DIR}/rule3.mdc"

    cmd_sync --global

    assert_file_not_exists "$TEST_TARGET_DIR/$TEST_LOCAL_DIR/rule1.mdc"
    assert_file_exists "${GLOBAL_RULES_DIR}/rule3.mdc"

    teardown_global_test_environment
    return 0
}

test_sync_global_ignores_local_commit_integrity_mismatch() {
    setup_global_test_environment

    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --commit

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule2.mdc" --global

    # Simulate local/commit metadata drift that should not block --global sync.
    printf "other-repo\t%s\n" "$TEST_TARGET_DIR" > "$LOCAL_MANIFEST_FILE"

    rm -f "${GLOBAL_RULES_DIR}/rule2.mdc"

    output=$(cmd_sync --global 2>&1 || echo "ERROR_OCCURRED")

    case "$output" in
        *ERROR_OCCURRED*)
            fail "sync --global should ignore local/commit integrity mismatch: $output"
            ;;
    esac

    assert_file_exists "${GLOBAL_RULES_DIR}/rule2.mdc"

    teardown_global_test_environment
    return 0
}

test_sync_global_redeploys_updated_repo_content() {
    setup_global_test_environment

    cmd_init "$TEST_SOURCE_REPO" -d ".cursor/rules" --global
    cmd_add_rule "rule1.mdc" --global

    echo "UPDATED RULE CONTENT" > "${GLOBAL_REPO_DIR}/${RULES_PATH}/rule1.mdc"

    cmd_sync

    content=$(cat "${GLOBAL_RULES_DIR}/rule1.mdc")
    echo "$content" | grep -q "UPDATED RULE CONTENT" || \
        fail "sync should redeploy updated content from global repo cache: got '$content'"

    teardown_global_test_environment
    return 0
}

test_sync_global_errors_when_global_not_initialized() {
    cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR" --local

    output=$(cmd_sync --global 2>&1 || echo "ERROR_OCCURRED")

    echo "$output" | grep -q "Global mode is not initialized\|ERROR_OCCURRED" || \
        fail "sync --global should error when global mode is not initialized: $output"

    return 0
}

# shellcheck disable=SC1090
. "$(dirname "$0")/../../../shunit2"
