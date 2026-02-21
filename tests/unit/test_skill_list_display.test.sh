#!/bin/sh
#
# test_skill_list_display.test.sh - Skill list display test suite
#
# Tests that cmd_list() correctly discovers and displays skills from both
# valid skill paths (rules/<name> and rulesets/<r>/skills/<name>), shows
# installation status glyphs, deduplicates, and renders skills/ as a magic
# subdir in the ruleset tree.
#
# Test Coverage (behaviors 16-21 from the skill-support plan):
#   16. Skills from rules/<name> appear in "Available skills:" section with trailing "/"
#   17. Skills from rulesets/<r>/skills/<name> appear in "Available skills:" section
#   18. Standalone skill shows correct installed status glyph
#   19. Embedded skill shows installed when parent ruleset is installed
#   20. Deduplication: skill in both paths shown only once
#   21. Ruleset tree rendering shows skills/ as magic subdir with expanded contents
#   22. Ruleset tree skills/ expansion only shows dirs that contain SKILL.md (not plain dirs)
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_skill_list_display.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# BEHAVIOR 16: Standalone skills appear in "Available skills:" with trailing "/"
# ============================================================================

test_standalone_skill_appears_in_skills_section() {
	# A rules/<name> directory with SKILL.md appears in the "Available skills:"
	# section with a trailing "/" on the name.
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add standalone skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	echo "${output}" | grep -q "Available skills:" || \
		fail "Output should have 'Available skills:' section"
	echo "${output}" | grep -q "my-skill/" || \
		fail "Standalone skill should appear with trailing / in skills section"
}

# ============================================================================
# BEHAVIOR 17: Embedded skills appear in "Available skills:" section
# ============================================================================

test_embedded_skill_appears_in_skills_section() {
	# A rulesets/<r>/skills/<name> directory with SKILL.md appears in the
	# "Available skills:" section of cmd_list output.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill"
	echo "# Embedded" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	echo "${output}" | grep -q "Available skills:" || \
		fail "Output should have 'Available skills:' section"
	echo "${output}" | grep -q "embedded-skill/" || \
		fail "Embedded skill should appear in skills section"
}

# ============================================================================
# BEHAVIOR 18: Standalone skill shows correct installed status glyph
# ============================================================================

test_standalone_skill_installed_glyph() {
	# An installed standalone skill shows ● (committed) and an uninstalled one
	# shows ○ (uninstalled).
	mkdir -p "${REPO_DIR}/rules/installed-skill"
	echo "# Installed" > "${REPO_DIR}/rules/installed-skill/SKILL.md"
	mkdir -p "${REPO_DIR}/rules/uninstalled-skill"
	echo "# Uninstalled" > "${REPO_DIR}/rules/uninstalled-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add two skills" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_rule "installed-skill" --commit

	output=$(cmd_list)

	# installed-skill should show committed glyph (●)
	echo "${output}" | grep -q "● installed-skill/" || \
		fail "Installed skill should show committed glyph (●): ${output}"
	# uninstalled-skill should show uninstalled glyph (○)
	echo "${output}" | grep -q "○ uninstalled-skill/" || \
		fail "Uninstalled skill should show uninstalled glyph (○): ${output}"
}

# ============================================================================
# BEHAVIOR 19: Embedded skill shows installed when parent ruleset is installed
# ============================================================================

test_embedded_skill_installed_when_ruleset_installed() {
	# An embedded skill inside an installed ruleset shows as installed in the
	# "Available skills:" section.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill"
	echo "# Embedded" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit
	cmd_add_ruleset "my-ruleset" --commit

	output=$(cmd_list)

	# embedded-skill should show as installed (committed glyph ●) because
	# its parent ruleset is installed
	echo "${output}" | grep -q "● embedded-skill/" || \
		fail "Embedded skill with installed parent ruleset should show committed glyph (●): ${output}"
}

# ============================================================================
# BEHAVIOR 20: Deduplication — same skill name in both paths shown once
# ============================================================================

test_skill_deduplicated_when_in_both_paths() {
	# If a skill name exists in both rules/<name> and rulesets/<r>/skills/<name>,
	# it appears only once in "Available skills:".
	mkdir -p "${REPO_DIR}/rules/shared-skill"
	echo "# Shared standalone" > "${REPO_DIR}/rules/shared-skill/SKILL.md"
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/shared-skill"
	echo "# Shared embedded" > "${REPO_DIR}/rulesets/my-ruleset/skills/shared-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add shared-skill in both paths" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	# Count occurrences of "shared-skill/" in the output — should be exactly 1
	count=$(echo "${output}" | grep -c "shared-skill/")
	assertEquals "shared-skill/ should appear exactly once (deduplicated)" "1" "${count}"
}

# ============================================================================
# BEHAVIOR 21: Ruleset tree shows skills/ as magic subdir with expanded contents
# ============================================================================

test_ruleset_tree_expands_skills_subdir() {
	# When a ruleset has a skills/ subdir, cmd_list shows it in the ruleset tree
	# with its contents expanded one level (mirroring commands/ treatment).
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/skill-one"
	echo "# Skill One" > "${REPO_DIR}/rulesets/my-ruleset/skills/skill-one/SKILL.md"
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/skill-two"
	echo "# Skill Two" > "${REPO_DIR}/rulesets/my-ruleset/skills/skill-two/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with skills subdir" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	# The ruleset tree should show the skills/ directory as a tree entry
	# (filter "Available skills:" header so we only match the tree line)
	echo "${output}" | grep -v "Available skills:" | grep -q "skills" || \
		fail "Ruleset tree should show 'skills' as a tree entry: ${output}"
	# The skills/ directory contents should be expanded in the tree.
	# Tree entries show the bare name (no trailing "/"); the skills section
	# shows "○ skill-one/" so filtering out lines with "/" isolates tree entries.
	echo "${output}" | grep "skill-one" | grep -qv "/" || \
		fail "skill-one should appear expanded in ruleset tree (without trailing /): ${output}"
	echo "${output}" | grep "skill-two" | grep -qv "/" || \
		fail "skill-two should appear expanded in ruleset tree (without trailing /): ${output}"
}

# ============================================================================
# BEHAVIOR 22: Strongest install status wins when skill appears in multiple rulesets
# ============================================================================

test_embedded_skill_shows_strongest_status_across_rulesets() {
	# When the same embedded skill exists in two rulesets installed at different
	# modes (one "local", one "committed"), the skill must display the committed
	# glyph (●) — the strongest status — not the weaker local glyph (◐).
	# The rulesets are named so the "local" one sorts alphabetically first,
	# ensuring this covers the bug where the loop stopped at the first match.
	mkdir -p "${REPO_DIR}/rulesets/aaa-local-ruleset/skills/shared-skill"
	echo "# Shared skill" > "${REPO_DIR}/rulesets/aaa-local-ruleset/skills/shared-skill/SKILL.md"
	mkdir -p "${REPO_DIR}/rulesets/zzz-commit-ruleset/skills/shared-skill"
	echo "# Shared skill" > "${REPO_DIR}/rulesets/zzz-commit-ruleset/skills/shared-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add two rulesets with shared embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	# Init local mode first; commit mode is lazily initialised by cmd_add_ruleset
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --local
	cmd_add_ruleset "aaa-local-ruleset" --local
	cmd_add_ruleset "zzz-commit-ruleset" --commit

	output=$(cmd_list)

	# committed (●) must win over local (◐) regardless of iteration order
	echo "${output}" | grep -q "● shared-skill/" || \
		fail "shared-skill should show committed glyph (●) — strongest status wins: ${output}"
}

# ============================================================================
# BEHAVIOR 23: Ruleset tree skills/ expansion filters to valid skills only
# ============================================================================

test_ruleset_tree_skills_subdir_shows_only_valid_skills() {
	# When a ruleset's skills/ directory contains a mix of valid skill dirs
	# (containing SKILL.md) and plain directories (no SKILL.md), only the valid
	# skill dirs should appear in the tree expansion.  Plain dirs must be
	# silently excluded.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/real-skill"
	echo "# Real" > "${REPO_DIR}/rulesets/my-ruleset/skills/real-skill/SKILL.md"
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/not-a-skill"
	echo "some file" > "${REPO_DIR}/rulesets/my-ruleset/skills/not-a-skill/README.txt"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with mixed skills dir" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	# real-skill (has SKILL.md) should appear in the tree
	echo "${output}" | grep "real-skill" | grep -qv "/" || \
		fail "real-skill should appear in ruleset tree (without trailing /): ${output}"

	# not-a-skill (no SKILL.md) must NOT appear in the tree expansion
	assertFalse "not-a-skill (no SKILL.md) must not appear in tree expansion" \
		"echo '${output}' | grep -q 'not-a-skill'"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
