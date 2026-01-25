#!/bin/sh
# Test cache isolation for global mode
#
# Tests the Phase 7 bug fixes:
# - GLOBAL_REPO_DIR is set correctly and separately from REPO_DIR
# - get_global_source_repo() extracts repo from global manifest
# - get_repo_dir_for_mode() returns correct directory for each mode

# Source the test utilities
. "$(dirname "$0")/../common.sh"

# Set up test environment with HOME isolation
setUp() {
	# Save original HOME
	_ORIGINAL_HOME="${HOME}"
	
	# Create isolated test directory
	TEST_DIR="$(mktemp -d)"
	HOME="${TEST_DIR}"
	export HOME
	
	# Set up source repo with test rules (at HOME level)
	REPO_DIR="${TEST_DIR}/test_repo"
	mkdir -p "${REPO_DIR}/rules"
	mkdir -p "${REPO_DIR}/rulesets"
	echo "Rule 1 content" > "${REPO_DIR}/rules/rule1.mdc"
	
	# Create app directory separate from HOME (so COMMIT_MANIFEST != GLOBAL_MANIFEST)
	APP_DIR="${TEST_DIR}/app"
	mkdir -p "${APP_DIR}"
	cd "${APP_DIR}" || fail "Failed to cd to app dir"
	
	# Create git repo for tests
	git init . >/dev/null 2>&1
	git config user.email "test@test.com" >/dev/null 2>&1
	git config user.name "Test" >/dev/null 2>&1
	mkdir -p .git/info && touch .git/info/exclude
	echo "test" > README.md
	git add README.md >/dev/null 2>&1
	git commit --no-gpg-sign -m "init" >/dev/null 2>&1
	
	# Source ai-rizz AFTER HOME is set so GLOBAL_MANIFEST_FILE is correct
	source_ai_rizz
}

tearDown() {
	# Restore original HOME
	HOME="${_ORIGINAL_HOME}"
	export HOME
	
	cd / && rm -rf "${TEST_DIR}"
}

# ============================================================================
# Test GLOBAL_REPO_DIR tracking
# ============================================================================

# Test that GLOBAL_REPO_DIR is set when global mode is active
test_global_repo_dir_set_when_global_active() {
	# Set up a mock global manifest
	mkdir -p "$(dirname "${GLOBAL_MANIFEST_FILE}")"
	echo "${REPO_DIR}	.cursor/rules	rules	rulesets" > "${GLOBAL_MANIFEST_FILE}"
	
	# Cache metadata should set GLOBAL_REPO_DIR
	cache_manifest_metadata
	
	# GLOBAL_REPO_DIR should be set (in tests, it uses REPO_DIR)
	assertNotNull "GLOBAL_REPO_DIR should be set when global mode active" \
		"${GLOBAL_REPO_DIR}"
	
	# Cleanup
	rm -f "${GLOBAL_MANIFEST_FILE}"
}

# ============================================================================
# Test get_global_source_repo
# ============================================================================

# Test get_global_source_repo extracts correct repo from global manifest
test_get_global_source_repo_extracts_url() {
	mkdir -p "$(dirname "${GLOBAL_MANIFEST_FILE}")"
	echo "https://github.com/company/shared-rules	.cursor/rules	rules	rulesets" > "${GLOBAL_MANIFEST_FILE}"
	
	ggsr_result=$(get_global_source_repo)
	
	assertEquals "Should extract global source repo" \
		"https://github.com/company/shared-rules" "${ggsr_result}"
	
	# Cleanup
	rm -f "${GLOBAL_MANIFEST_FILE}"
}

# Test get_global_source_repo returns empty when no global manifest
test_get_global_source_repo_empty_when_no_manifest() {
	# Ensure no global manifest
	rm -f "${GLOBAL_MANIFEST_FILE}"
	
	ggsr_result=$(get_global_source_repo)
	
	assertEquals "Should return empty when no global manifest" "" "${ggsr_result}"
}

# ============================================================================
# Test get_repo_dir_for_mode
# ============================================================================

# Test get_repo_dir_for_mode returns correct dir for local mode
test_get_repo_dir_for_mode_local() {
	grdm_result=$(get_repo_dir_for_mode "local")
	assertEquals "Should return REPO_DIR for local mode" "${REPO_DIR}" "${grdm_result}"
}

# Test get_repo_dir_for_mode returns correct dir for commit mode
test_get_repo_dir_for_mode_commit() {
	grdm_result=$(get_repo_dir_for_mode "commit")
	assertEquals "Should return REPO_DIR for commit mode" "${REPO_DIR}" "${grdm_result}"
}

# Test get_repo_dir_for_mode returns correct dir for global mode
test_get_repo_dir_for_mode_global() {
	grdm_result=$(get_repo_dir_for_mode "global")
	assertEquals "Should return GLOBAL_REPO_DIR for global mode" "${GLOBAL_REPO_DIR}" "${grdm_result}"
}

# ============================================================================
# Test integration: Add rule uses correct repo for mode
# ============================================================================

# Test add rule in commit mode uses REPO_DIR
test_add_rule_commit_uses_repo_dir() {
	# Set up commit mode
	mkdir -p ".cursor/rules/shared"
	echo "${REPO_DIR}	.cursor/rules	rules	rulesets" > "${COMMIT_MANIFEST_FILE}"
	
	# Cache metadata
	cache_manifest_metadata
	
	# Add a rule - should work because rule exists in REPO_DIR
	car_output=$(cmd_add_rule --commit rule1 2>&1)
	car_status=$?
	
	assertEquals "add --commit should succeed" 0 ${car_status}
	echo "${car_output}" | grep -q "Added rule" || \
		fail "Should report added rule, got: ${car_output}"
}

# Test add rule in global mode uses GLOBAL_REPO_DIR
test_add_rule_global_uses_global_repo_dir() {
	# Set up global mode
	mkdir -p "$(dirname "${GLOBAL_MANIFEST_FILE}")"
	mkdir -p "${GLOBAL_RULES_DIR}"
	echo "${REPO_DIR}	.cursor/rules	rules	rulesets" > "${GLOBAL_MANIFEST_FILE}"
	
	# Cache metadata
	cache_manifest_metadata
	
	# Add a rule - should work because GLOBAL_REPO_DIR has same content as REPO_DIR in tests
	car_output=$(cmd_add_rule --global rule1 2>&1)
	car_status=$?
	
	assertEquals "add --global should succeed" 0 ${car_status}
	echo "${car_output}" | grep -q "Added rule" || \
		fail "Should report added rule, got: ${car_output}"
}

# ============================================================================
# Test copy_ruleset_commands uses repo_dir parameter
# ============================================================================

# Test copy_ruleset_commands uses provided repo_dir, not global REPO_DIR
test_copy_ruleset_commands_uses_repo_dir_parameter() {
	# Create a separate "different repo" with commands to prove repo_dir param is used
	crc_different_repo="${TEST_DIR}/different_repo"
	mkdir -p "${crc_different_repo}/rulesets/test-ruleset/commands"
	echo "# Different repo command" > "${crc_different_repo}/rulesets/test-ruleset/commands/cmd.md"
	
	# Set REPO_DIR to original test repo (which has NO commands)
	# This proves if copy_ruleset_commands uses the passed repo_dir, it will find commands
	# But if it uses global REPO_DIR, it won't find any commands
	
	# Create target directory
	crc_target_dir="${TEST_DIR}/target_commands"
	mkdir -p "${crc_target_dir}"
	
	# Call copy_ruleset_commands with explicit repo_dir parameter
	copy_ruleset_commands "rulesets/test-ruleset" "${crc_target_dir}" "${crc_different_repo}"
	
	# Verify command was copied - this proves the repo_dir parameter was used
	assertTrue "Command should be copied from provided repo_dir" \
		"[ -f '${crc_target_dir}/cmd.md' ]"
}

# Test remove_ruleset_commands uses provided repo_dir, not global REPO_DIR
test_remove_ruleset_commands_uses_repo_dir_parameter() {
	# Create a separate "different repo" that defines which commands exist
	rrc_different_repo="${TEST_DIR}/different_repo"
	mkdir -p "${rrc_different_repo}/rulesets/test-ruleset/commands"
	echo "# Different repo command" > "${rrc_different_repo}/rulesets/test-ruleset/commands/remove-me.md"
	
	# Create target directory with the command file pre-installed
	rrc_target_dir="${TEST_DIR}/target_commands"
	mkdir -p "${rrc_target_dir}"
	echo "# Command to remove" > "${rrc_target_dir}/remove-me.md"
	
	# Verify file exists before removal
	assertTrue "Target command should exist before removal" \
		"[ -f '${rrc_target_dir}/remove-me.md' ]"
	
	# Call remove_ruleset_commands with explicit repo_dir parameter
	remove_ruleset_commands "rulesets/test-ruleset" "${rrc_target_dir}" "${rrc_different_repo}"
	
	# Verify command was removed - this proves the repo_dir parameter was used
	assertFalse "Command should be removed using provided repo_dir" \
		"[ -f '${rrc_target_dir}/remove-me.md' ]"
}

# ============================================================================
# Load shunit2
# ============================================================================

# Load and run shunit2
# shellcheck disable=SC1091
. "$(dirname "$0")/../../shunit2"
