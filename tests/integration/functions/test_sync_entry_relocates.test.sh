#!/bin/sh
#
# test_sync_entry_relocates.test.sh - Sync remaps for slug-preserving relocates
#
# When a standalone manifest entry's exact path disappears but the same
# name-slug exists as another form (rule/command/skill), sync must deploy the
# new form, rewrite the manifest, and avoid "Entry not found" for that slug.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_sync_entry_relocates.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# Commit current REPO_DIR state (tests mutate source between add and sync).
_commit_source_repo() {
	csr_msg="${1:-Update source}"
	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add -A >/dev/null 2>&1
	git commit --no-gpg-sign -m "${csr_msg}" >/dev/null 2>&1 || true
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"
}

# ============================================================================
# Relocate directions
# ============================================================================

test_sync_remaps_rule_to_skill() {
	# Manifest has rules/relocate-me.mdc; upstream becomes rules/relocate-me/SKILL.md
	echo "# Rule" > "${REPO_DIR}/rules/relocate-me.mdc"
	_commit_source_repo "Add rule"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "relocate-me.mdc" --commit
	assertTrue "rule should be installed initially" \
		"[ -f '${TEST_TARGET_DIR}/${TEST_SHARED_DIR}/relocate-me.mdc' ]"

	rm -f "${REPO_DIR}/rules/relocate-me.mdc"
	mkdir -p "${REPO_DIR}/rules/relocate-me"
	echo "# Skill" > "${REPO_DIR}/rules/relocate-me/SKILL.md"
	_commit_source_repo "Rule to skill"

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	sync_rc=$?
	output=$(cat "${_tser_out}")
	rm -f "${_tser_out}"
	assertEquals "sync should succeed" 0 "${sync_rc}"
	echo "${output}" | grep -q "Entry not found in repository: rules/relocate-me.mdc" && \
		fail "Should not warn missing for remapped rule: ${output}"

	assertTrue "skill should be deployed" \
		"[ -f '.cursor/skills/shared/relocate-me/SKILL.md' ]"
	assertFalse "old rule file should be gone after sync clear" \
		"[ -f '${TEST_TARGET_DIR}/${TEST_SHARED_DIR}/relocate-me.mdc' ]"
	grep -qx "rules/relocate-me" "${COMMIT_MANIFEST_FILE}" || \
		fail "manifest should rewrite to rules/relocate-me"
	if grep -qx "rules/relocate-me.mdc" "${COMMIT_MANIFEST_FILE}"; then
		fail "old manifest path should be removed"
	fi
}

test_sync_remaps_command_to_skill() {
	echo "# Cmd" > "${REPO_DIR}/rules/relocate-cmd.md"
	_commit_source_repo "Add command"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "relocate-cmd.md" --commit
	assertTrue "command should be installed initially" \
		"[ -f '.cursor/commands/shared/relocate-cmd.md' ]"

	rm -f "${REPO_DIR}/rules/relocate-cmd.md"
	mkdir -p "${REPO_DIR}/rules/relocate-cmd"
	echo "# Skill" > "${REPO_DIR}/rules/relocate-cmd/SKILL.md"
	_commit_source_repo "Command to skill"

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	output=$(cat "${_tser_out}")
	rm -f "${_tser_out}"
	echo "${output}" | grep -q "Entry not found in repository: rules/relocate-cmd.md" && \
		fail "Should not warn missing for remapped command: ${output}"

	assertTrue "skill should be deployed" \
		"[ -f '.cursor/skills/shared/relocate-cmd/SKILL.md' ]"
	grep -qx "rules/relocate-cmd" "${COMMIT_MANIFEST_FILE}" || \
		fail "manifest should rewrite to rules/relocate-cmd"
}

test_sync_remaps_skill_to_rule() {
	mkdir -p "${REPO_DIR}/rules/relocate-sk"
	echo "# Skill" > "${REPO_DIR}/rules/relocate-sk/SKILL.md"
	_commit_source_repo "Add skill"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "relocate-sk" --commit
	assertTrue "skill should be installed initially" \
		"[ -f '.cursor/skills/shared/relocate-sk/SKILL.md' ]"

	rm -rf "${REPO_DIR}/rules/relocate-sk"
	echo "# Rule" > "${REPO_DIR}/rules/relocate-sk.mdc"
	_commit_source_repo "Skill to rule"

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	output=$(cat "${_tser_out}")
	rm -f "${_tser_out}"
	echo "${output}" | grep -q "Entry not found in repository: rules/relocate-sk" && \
		fail "Should not warn missing for remapped skill: ${output}"

	assertTrue "rule should be deployed" \
		"[ -f '${TEST_TARGET_DIR}/${TEST_SHARED_DIR}/relocate-sk.mdc' ]"
	assertFalse "skill dir should be cleared" \
		"[ -d '.cursor/skills/shared/relocate-sk' ]"
	grep -qx "rules/relocate-sk.mdc" "${COMMIT_MANIFEST_FILE}" || \
		fail "manifest should rewrite to rules/relocate-sk.mdc"
}

test_sync_remaps_skill_to_command() {
	mkdir -p "${REPO_DIR}/rules/relocate-skc"
	echo "# Skill" > "${REPO_DIR}/rules/relocate-skc/SKILL.md"
	_commit_source_repo "Add skill"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "relocate-skc" --commit

	rm -rf "${REPO_DIR}/rules/relocate-skc"
	echo "# Cmd" > "${REPO_DIR}/rules/relocate-skc.md"
	_commit_source_repo "Skill to command"

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	output=$(cat "${_tser_out}")
	rm -f "${_tser_out}"
	echo "${output}" | grep -q "Entry not found in repository: rules/relocate-skc" && \
		fail "Should not warn missing for remapped skill→command: ${output}"

	assertTrue "command should be deployed" \
		"[ -f '.cursor/commands/shared/relocate-skc.md' ]"
	grep -qx "rules/relocate-skc.md" "${COMMIT_MANIFEST_FILE}" || \
		fail "manifest should rewrite to rules/relocate-skc.md"
}

test_sync_remaps_rule_to_command() {
	echo "# Rule" > "${REPO_DIR}/rules/relocate-rc.mdc"
	_commit_source_repo "Add rule"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "relocate-rc.mdc" --commit

	rm -f "${REPO_DIR}/rules/relocate-rc.mdc"
	echo "# Cmd" > "${REPO_DIR}/rules/relocate-rc.md"
	_commit_source_repo "Rule to command"

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	output=$(cat "${_tser_out}")
	rm -f "${_tser_out}"
	echo "${output}" | grep -q "Entry not found in repository: rules/relocate-rc.mdc" && \
		fail "Should not warn missing for remapped rule→command: ${output}"

	assertTrue "command should be deployed" \
		"[ -f '.cursor/commands/shared/relocate-rc.md' ]"
	grep -qx "rules/relocate-rc.md" "${COMMIT_MANIFEST_FILE}" || \
		fail "manifest should rewrite to rules/relocate-rc.md"
}

# ============================================================================
# Negative / stability
# ============================================================================

test_sync_truly_missing_entry_still_warns() {
	echo "# Rule" > "${REPO_DIR}/rules/will-vanish.mdc"
	_commit_source_repo "Add vanishing rule"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "will-vanish.mdc" --commit

	rm -f "${REPO_DIR}/rules/will-vanish.mdc"
	_commit_source_repo "Remove rule entirely"

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	output=$(cat "${_tser_out}")
	rm -f "${_tser_out}"
	echo "${output}" | grep -q "Entry not found in repository: rules/will-vanish.mdc" || \
		fail "Truly missing entry should still warn: ${output}"
	grep -qx "rules/will-vanish.mdc" "${COMMIT_MANIFEST_FILE}" || \
		fail "truly missing entry should remain in manifest"
}

test_sync_exact_path_not_remapped_when_present() {
	# Both forms exist; manifest points at .mdc — must keep deploying the rule
	echo "# Rule" > "${REPO_DIR}/rules/both-forms.mdc"
	mkdir -p "${REPO_DIR}/rules/both-forms"
	echo "# Skill" > "${REPO_DIR}/rules/both-forms/SKILL.md"
	_commit_source_repo "Add both forms"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "both-forms.mdc" --commit

	_tser_out=$(mktemp)
	cmd_sync >"${_tser_out}" 2>&1
	rm -f "${_tser_out}"

	assertTrue "rule should still deploy" \
		"[ -f '${TEST_TARGET_DIR}/${TEST_SHARED_DIR}/both-forms.mdc' ]"
	grep -qx "rules/both-forms.mdc" "${COMMIT_MANIFEST_FILE}" || \
		fail "manifest must keep exact .mdc path when present"
	assertFalse "must not silently switch manifest to skill" \
		"grep -qx 'rules/both-forms' '${COMMIT_MANIFEST_FILE}'"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../../shunit2"
