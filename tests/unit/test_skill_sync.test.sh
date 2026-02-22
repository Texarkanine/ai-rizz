#!/bin/sh
#
# test_skill_sync.test.sh - Skill sync/deployment test suite
#
# Tests that skills are correctly deployed to .cursor/skills/<mode>/ during
# add/sync operations for both standalone skills (manifest entries) and
# embedded skills (inside rulesets' skills/ subdir).
#
# Test Coverage (behaviors 8-15, 22-27 from the skill-support plan):
#   8.  Standalone skill (rules/<name> in manifest) copied to .cursor/skills/<mode>/<name>/
#   9.  Standalone skill contents preserved (SKILL.md + other files all copied)
#   10. Ruleset with skills/<name>/SKILL.md → skill copied to .cursor/skills/<mode>/<name>/
#   11. Ruleset with skills/<name>/SKILL.md + other files → all contents copied
#   12. Ruleset with no skills/ subdir → no change in behavior (regression)
#   13. Ruleset with skills/<name> but no SKILL.md → NOT copied as skill
#   14. Ruleset with both .mdc rules and skills/ → both deployed correctly
#   15. Ruleset with .mdc rules, .md commands, and skills/ → all three types deployed
#   22. Skills directory cleared and rebuilt on sync (standalone skills re-deployed)
#   23. Embedded skills re-deployed when parent ruleset is synced
#   24. Deinit --local removes .cursor/skills/local/
#   25. Deinit --commit removes .cursor/skills/shared/
#   26. Deinit --global removes GLOBAL_SKILLS_DIR
#   27. Standalone skill with symlink pointing outside repo is NOT deployed (security)
#   28. Embedded skill with symlink pointing outside repo is NOT deployed (security)
#   29. Skills cleanup removes stale plain files, not just stale directories
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_skill_sync.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# BEHAVIOR 8: Standalone skill copied to .cursor/skills/<mode>/<name>/
# ============================================================================

test_standalone_skill_deployed_to_skills_dir() {
	# Adding a standalone skill (rules/<name>/ with SKILL.md) via:
	#   cmd_add_rule my-skill --commit
	# should deploy the skill dir to .cursor/skills/shared/my-skill/.
	# Note: cmd_add_rule detects the directory has SKILL.md and adds
	# "rules/my-skill" to the manifest (no extension).
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add standalone skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	# Add the skill by name only (cmd_add_rule handles skills in rules/)
	cmd_add_rule "my-skill" --commit
	assertTrue "cmd_add_rule should succeed for skill dir" $?

	# Skill dir should be deployed under .cursor/skills/shared/
	assertTrue "skills/shared/my-skill/ should be created" \
		"[ -d '.cursor/skills/shared/my-skill' ]"
	assertTrue "SKILL.md should be deployed" \
		"[ -f '.cursor/skills/shared/my-skill/SKILL.md' ]"
}

# ============================================================================
# BEHAVIOR 9: Standalone skill contents preserved
# ============================================================================

test_standalone_skill_contents_preserved() {
	# When a standalone skill is deployed, all its files (SKILL.md + extras)
	# are copied intact to the skills target directory.
	mkdir -p "${REPO_DIR}/rules/rich-skill"
	echo "# Rich Skill" > "${REPO_DIR}/rules/rich-skill/SKILL.md"
	echo "extra content" > "${REPO_DIR}/rules/rich-skill/extra.md"
	echo "helper content" > "${REPO_DIR}/rules/rich-skill/helper.sh"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add rich skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "rich-skill" --commit
	assertTrue "cmd_add_rule should succeed" $?

	assertTrue "SKILL.md should be present" \
		"[ -f '.cursor/skills/shared/rich-skill/SKILL.md' ]"
	assertTrue "extra.md should be present" \
		"[ -f '.cursor/skills/shared/rich-skill/extra.md' ]"
	assertTrue "helper.sh should be present" \
		"[ -f '.cursor/skills/shared/rich-skill/helper.sh' ]"
}

# ============================================================================
# BEHAVIOR 10: Embedded skill copied from ruleset skills/ subdir
# ============================================================================

test_embedded_skill_deployed_when_ruleset_added() {
	# When a ruleset containing skills/<name>/SKILL.md is added, the skill dir
	# is deployed to .cursor/skills/<mode>/<name>/.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill"
	echo "# Embedded" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill/SKILL.md"
	echo "rule content" > "${REPO_DIR}/rulesets/my-ruleset/rule.mdc"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "my-ruleset" --commit
	assertTrue "cmd_add_ruleset should succeed" $?

	assertTrue "skills/shared/embedded-skill/ should be created" \
		"[ -d '.cursor/skills/shared/embedded-skill' ]"
	assertTrue "SKILL.md should be deployed" \
		"[ -f '.cursor/skills/shared/embedded-skill/SKILL.md' ]"
}

# ============================================================================
# BEHAVIOR 11: Embedded skill contents preserved
# ============================================================================

test_embedded_skill_contents_all_copied() {
	# All files inside an embedded skill dir are deployed, not just SKILL.md.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-rich"
	echo "# Rich" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-rich/SKILL.md"
	echo "helper" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-rich/helper.sh"
	echo "extra" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-rich/notes.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with rich embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "my-ruleset" --commit
	assertTrue "cmd_add_ruleset should succeed" $?

	assertTrue "SKILL.md present" \
		"[ -f '.cursor/skills/shared/embedded-rich/SKILL.md' ]"
	assertTrue "helper.sh present" \
		"[ -f '.cursor/skills/shared/embedded-rich/helper.sh' ]"
	assertTrue "notes.md present" \
		"[ -f '.cursor/skills/shared/embedded-rich/notes.md' ]"
}

# ============================================================================
# BEHAVIOR 12: Ruleset without skills/ subdir — no regression
# ============================================================================

test_ruleset_without_skills_subdir_unchanged() {
	# A ruleset with no skills/ still deploys its rules correctly, and does NOT
	# create any skills target directory.
	mkdir -p "${REPO_DIR}/rulesets/plain-ruleset"
	echo "rule content" > "${REPO_DIR}/rulesets/plain-ruleset/rule.mdc"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add plain ruleset" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "plain-ruleset" --commit
	assertTrue "cmd_add_ruleset should succeed" $?

	# Rule is deployed
	assertTrue "rule.mdc should be deployed" \
		"[ -f '${TEST_TARGET_DIR}/shared/rule.mdc' ]"
	# No skills dir created
	assertFalse "skills/shared/ should NOT be created for plain ruleset" \
		"[ -d '.cursor/skills/shared' ]"
}

# ============================================================================
# BEHAVIOR 13: Ruleset with skills/<name> but no SKILL.md — not copied
# ============================================================================

test_skills_subdir_without_skill_md_not_deployed() {
	# A skills/<name> dir lacking SKILL.md is NOT deployed as a skill.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/not-a-skill"
	echo "no skill marker" > "${REPO_DIR}/rulesets/my-ruleset/skills/not-a-skill/readme.txt"
	echo "rule content" > "${REPO_DIR}/rulesets/my-ruleset/rule.mdc"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with non-skill skills dir" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "my-ruleset" --commit
	assertTrue "cmd_add_ruleset should succeed" $?

	assertFalse "not-a-skill/ should NOT be deployed (no SKILL.md)" \
		"[ -d '.cursor/skills/shared/not-a-skill' ]"
}

# ============================================================================
# BEHAVIOR 14: Ruleset with .mdc rules AND skills/ — both deployed
# ============================================================================

test_ruleset_with_rules_and_skills_deploys_both() {
	# A ruleset with both .mdc rules and a skills/ subdir deploys both to their
	# respective target dirs.
	mkdir -p "${REPO_DIR}/rulesets/combo-ruleset/skills/my-skill"
	echo "# Skill" > "${REPO_DIR}/rulesets/combo-ruleset/skills/my-skill/SKILL.md"
	echo "rule content" > "${REPO_DIR}/rulesets/combo-ruleset/rule.mdc"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add combo ruleset" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "combo-ruleset" --commit
	assertTrue "cmd_add_ruleset should succeed" $?

	assertTrue "rule.mdc should be deployed to rules dir" \
		"[ -f '${TEST_TARGET_DIR}/shared/rule.mdc' ]"
	assertTrue "skill should be deployed to skills dir" \
		"[ -d '.cursor/skills/shared/my-skill' ]"
	assertTrue "SKILL.md should be present" \
		"[ -f '.cursor/skills/shared/my-skill/SKILL.md' ]"
}

# ============================================================================
# BEHAVIOR 15: Ruleset with .mdc, .md commands, AND skills/ — all three deployed
# ============================================================================

test_ruleset_with_rules_commands_and_skills_deploys_all() {
	# A ruleset with all three types deploys each to its correct target dir.
	mkdir -p "${REPO_DIR}/rulesets/triple-ruleset/skills/my-skill"
	echo "# Skill" > "${REPO_DIR}/rulesets/triple-ruleset/skills/my-skill/SKILL.md"
	echo "rule content" > "${REPO_DIR}/rulesets/triple-ruleset/rule.mdc"
	echo "command content" > "${REPO_DIR}/rulesets/triple-ruleset/my-command.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add triple-type ruleset" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "triple-ruleset" --commit
	assertTrue "cmd_add_ruleset should succeed" $?

	assertTrue "rule.mdc deployed to rules dir" \
		"[ -f '${TEST_TARGET_DIR}/shared/rule.mdc' ]"
	assertTrue "my-command.md deployed to commands dir" \
		"[ -f '.cursor/commands/shared/my-command.md' ]"
	assertTrue "skill deployed to skills dir" \
		"[ -d '.cursor/skills/shared/my-skill' ]"
	assertTrue "SKILL.md present in skills dir" \
		"[ -f '.cursor/skills/shared/my-skill/SKILL.md' ]"
}

# ============================================================================
# BEHAVIOR 22: Skills directory cleared and rebuilt on sync
# ============================================================================

test_skills_dir_cleared_on_sync() {
	# When sync runs, the skills target dir is cleared first so stale skills
	# (from a previous sync that are no longer in the manifest) are removed.
	# Test strategy: add a real skill, sync it, then plant a "stale" skill dir
	# in .cursor/skills/shared/ that is NOT in the manifest, re-sync, and
	# verify the stale dir is gone while the real skill persists.
	mkdir -p "${REPO_DIR}/rules/real-skill"
	echo "# Real" > "${REPO_DIR}/rules/real-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add real skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "real-skill" --commit

	assertTrue "real-skill deployed initially" \
		"[ -d '.cursor/skills/shared/real-skill' ]"

	# Plant a stale skill dir that is NOT in the manifest
	mkdir -p ".cursor/skills/shared/stale-skill"
	echo "# Stale" > ".cursor/skills/shared/stale-skill/SKILL.md"
	assertTrue "stale-skill should exist before sync" \
		"[ -d '.cursor/skills/shared/stale-skill' ]"

	# Re-sync — should clear and rebuild skills dir
	cmd_sync

	assertTrue "real-skill should still be present after sync" \
		"[ -d '.cursor/skills/shared/real-skill' ]"
	assertFalse "stale-skill should be gone after sync (cleared)" \
		"[ -d '.cursor/skills/shared/stale-skill' ]"
}

# ============================================================================
# BEHAVIOR 23: Embedded skills re-deployed when parent ruleset is synced
# ============================================================================

test_embedded_skills_redeployed_on_sync() {
	# Embedded skills are re-deployed as part of their parent ruleset's sync.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill"
	echo "# Embedded" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "my-ruleset" --commit

	assertTrue "embedded skill deployed initially" \
		"[ -d '.cursor/skills/shared/embedded-skill' ]"

	# Remove the skill dir on disk (simulating a manual cleanup) then re-sync
	rm -rf ".cursor/skills/shared/embedded-skill"
	assertFalse "skill should be absent before re-sync" \
		"[ -d '.cursor/skills/shared/embedded-skill' ]"

	cmd_sync

	assertTrue "embedded skill should be re-deployed after sync" \
		"[ -d '.cursor/skills/shared/embedded-skill' ]"
	assertTrue "SKILL.md present after re-sync" \
		"[ -f '.cursor/skills/shared/embedded-skill/SKILL.md' ]"
}

# ============================================================================
# BEHAVIOR 24: Deinit local mode removes .cursor/skills/local/
# ============================================================================

test_deinit_local_removes_skills_dir() {
	# When deinit --local runs, the skills dir for local mode
	# (.cursor/skills/local/) must be removed alongside the rules and commands dirs.
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --local
	cmd_add_rule "my-skill" --local
	assertTrue "skill should be deployed before deinit" \
		"[ -d '.cursor/skills/local/my-skill' ]"

	cmd_deinit --local -y

	assertFalse ".cursor/skills/local/ should be removed after local deinit" \
		"[ -d '.cursor/skills/local' ]"
}

# ============================================================================
# BEHAVIOR 25: Deinit commit mode removes .cursor/skills/shared/
# ============================================================================

test_deinit_commit_removes_skills_dir() {
	# When deinit --commit runs, the skills dir for commit mode
	# (.cursor/skills/shared/) must be removed alongside the rules and commands dirs.
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "my-skill" --commit
	assertTrue "skill should be deployed before deinit" \
		"[ -d '.cursor/skills/shared/my-skill' ]"

	cmd_deinit --commit -y

	assertFalse ".cursor/skills/shared/ should be removed after commit deinit" \
		"[ -d '.cursor/skills/shared' ]"
}

# ============================================================================
# BEHAVIOR 26: Deinit global mode removes GLOBAL_SKILLS_DIR
# ============================================================================

test_deinit_global_removes_skills_dir() {
	# When deinit --global runs, the global skills dir (${GLOBAL_SKILLS_DIR})
	# must be removed alongside GLOBAL_RULES_DIR and GLOBAL_COMMANDS_DIR.
	# Uses cmd_add_rule --global to exercise the real deploy path (consistent
	# with local/commit counterparts), rather than manually planting the dir.
	# HOME is overridden by the test framework so this is safe to run.
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d ".cursor/rules" --global
	init_global_paths
	cmd_add_rule "my-skill" --global
	assertTrue "global skill should be deployed before deinit" \
		"[ -d '${GLOBAL_SKILLS_DIR}/my-skill' ]"

	cmd_deinit --global -y

	assertFalse "GLOBAL_SKILLS_DIR should be removed after global deinit" \
		"[ -d '${GLOBAL_SKILLS_DIR}' ]"
}

# ============================================================================
# BEHAVIOR 27: Standalone skill with symlink pointing outside repo is NOT deployed
# ============================================================================

test_standalone_skill_with_external_symlink_not_deployed() {
	# A standalone skill (rules/<name>/ with SKILL.md) that contains a symlink
	# pointing outside the repository root must NOT be deployed to .cursor/skills/.
	# copy_entry_to_target() validates symlinks for ruleset .mdc files; the same
	# security check must apply to skill directories before cp -rL.
	outside_dir="${TEST_DIR}/outside"
	mkdir -p "${outside_dir}"
	echo "sensitive data" > "${outside_dir}/secret.txt"

	mkdir -p "${REPO_DIR}/rules/malicious-skill"
	echo "# Malicious Skill" > "${REPO_DIR}/rules/malicious-skill/SKILL.md"
	# Symlink inside the skill dir that points outside the repo
	ln -s "${outside_dir}/secret.txt" "${REPO_DIR}/rules/malicious-skill/secret.txt"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add skill with external symlink" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	cmd_add_rule "malicious-skill" --commit

	assertFalse "Skill with external symlink must NOT be deployed" \
		"[ -d '.cursor/skills/shared/malicious-skill' ]"
}

# ============================================================================
# BEHAVIOR 27b: Standalone skill whose top-level directory IS a symlink pointing
#               outside the repo is NOT deployed
# ============================================================================

test_standalone_skill_toplevel_external_symlink_not_deployed() {
	# copy_entry_to_target() must guard against the case where the skill
	# directory itself (cett_source_path) is a symlink pointing outside the
	# repository, not just symlinks inside the directory.  cp -rL would follow
	# the top-level symlink and copy arbitrary host-filesystem content.
	outside_dir="${TEST_DIR}/outside_toplevel"
	mkdir -p "${outside_dir}"
	echo "# Real Skill" > "${outside_dir}/SKILL.md"
	echo "sensitive data" > "${outside_dir}/secret.txt"

	# Create rules/evil-skill as a symlink to an external directory
	ln -s "${outside_dir}" "${REPO_DIR}/rules/evil-skill"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add skill whose top-level dir is an external symlink" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	cmd_add_rule "evil-skill" --commit

	assertFalse "Skill whose top-level dir is an external symlink must NOT be deployed" \
		"[ -d '.cursor/skills/shared/evil-skill' ]"
}

# ============================================================================
# BEHAVIOR 28: Embedded skill with symlink pointing outside repo is NOT deployed
# ============================================================================

test_embedded_skill_with_external_symlink_not_deployed() {
	# An embedded skill inside a ruleset's skills/<name>/ directory that contains
	# a symlink pointing outside the repository root must NOT be deployed to
	# .cursor/skills/. This mirrors the standalone-skill symlink check and ensures
	# the same security validation is applied to the embedded-skill copy path in
	# copy_entry_to_target(). The malicious symlink is:
	#   ${REPO_DIR}/rulesets/malicious-ruleset/skills/malicious-skill/secret.txt
	#   -> outside file
	outside_dir="${TEST_DIR}/outside"
	mkdir -p "${outside_dir}"
	echo "sensitive data" > "${outside_dir}/secret.txt"

	mkdir -p "${REPO_DIR}/rulesets/malicious-ruleset/skills/malicious-skill"
	echo "# Malicious Embedded Skill" > \
		"${REPO_DIR}/rulesets/malicious-ruleset/skills/malicious-skill/SKILL.md"
	# Symlink inside the embedded skill dir that points outside the repo
	ln -s "${outside_dir}/secret.txt" \
		"${REPO_DIR}/rulesets/malicious-ruleset/skills/malicious-skill/secret.txt"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with embedded skill containing external symlink" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "malicious-ruleset" --commit

	assertFalse "Embedded skill with external symlink must NOT be deployed" \
		"[ -d '.cursor/skills/shared/malicious-skill' ]"
}

# ============================================================================
# BEHAVIOR 28b: Embedded skill NOT deployed when ruleset skills/ subdir is an
#               external symlink
# ============================================================================

test_embedded_skills_subdir_external_symlink_not_deployed() {
	# copy_entry_to_target() must guard against the case where the skills/
	# subdirectory inside a ruleset is itself a symlink pointing outside the
	# repository.  Without the guard, find is called on the external target and
	# cp -rL would copy arbitrary host-filesystem content.
	outside_skills="${TEST_DIR}/outside_skills"
	mkdir -p "${outside_skills}/real-skill"
	echo "# Real Skill" > "${outside_skills}/real-skill/SKILL.md"
	echo "sensitive data" > "${outside_skills}/real-skill/secret.txt"

	mkdir -p "${REPO_DIR}/rulesets/evil-ruleset"
	echo "# Evil ruleset rule" > "${REPO_DIR}/rulesets/evil-ruleset/rule.mdc"
	# skills/ subdir is a symlink to an external directory
	ln -s "${outside_skills}" "${REPO_DIR}/rulesets/evil-ruleset/skills"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with external skills/ symlink" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "evil-ruleset" --commit

	assertFalse "Skill in external skills/ symlink must NOT be deployed" \
		"[ -d '.cursor/skills/shared/real-skill' ]"
}

# ============================================================================
# BEHAVIOR 29: Skills cleanup removes stale files, not just stale directories
# ============================================================================

test_skills_cleanup_removes_stale_files_not_just_dirs() {
	# The sync pre-pass clears the skills target directory before rebuilding.
	# If the cleanup uses "-type d" it only removes subdirectories and leaves
	# behind any stale plain files or symlinks.  This test plants a plain file
	# directly inside .cursor/skills/shared/ (simulating a leftover artefact)
	# and asserts it is gone after a sync.
	mkdir -p "${REPO_DIR}/rules/real-skill"
	echo "# Real" > "${REPO_DIR}/rules/real-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git config user.email "test@example.com" >/dev/null 2>&1
	git config user.name "Test User" >/dev/null 2>&1
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add real skill for stale-file test" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "real-skill" --commit

	# Plant a stale plain file directly in the skills target dir (not a subdir)
	mkdir -p ".cursor/skills/shared"
	echo "stale" > ".cursor/skills/shared/stale-file.txt"
	assertTrue "stale-file.txt should exist before sync" \
		"[ -f '.cursor/skills/shared/stale-file.txt' ]"

	# Re-sync — cleanup must remove the stale file too
	cmd_sync

	assertFalse "stale-file.txt should be removed by skills cleanup" \
		"[ -f '.cursor/skills/shared/stale-file.txt' ]"
	assertTrue "real-skill dir should still be present after sync" \
		"[ -d '.cursor/skills/shared/real-skill' ]"
}


# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
