#!/bin/sh
#
# test_skill_list_display.test.sh - Skill list display test suite
#
# Tests that cmd_list() correctly discovers and displays skills from the
# standalone rules/<name> path only, shows installation status glyphs,
# renders skills/ as a magic subdir in the ruleset tree, and places
# "Available rulesets:" after "Available skills:".
#
# Test Coverage:
#   16. Skills from rules/<name> appear in "Available skills:" section with trailing "/"
#   17. Embedded-only skills (rulesets/<r>/skills/<name>) do NOT appear in
#       "Available skills:" — they are visible in the ruleset tree but cannot
#       be installed individually
#   18. Standalone skill shows correct installed status glyph
#   20. Deduplication: skill in both rules/ and a ruleset's skills/ shown once
#       (from the standalone path)
#   21. Ruleset tree rendering shows skills/ as magic subdir with expanded contents
#   23. Ruleset tree skills/ expansion only shows dirs that contain SKILL.md
#   24. "Available rulesets:" section appears after "Available skills:" in output
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
# BEHAVIOR 17: Embedded-only skills do NOT appear in "Available skills:"
# ============================================================================

test_embedded_skill_not_in_skills_section() {
	# A skill that only exists under rulesets/<r>/skills/<name> cannot be
	# installed individually (ai-rizz add rule <name> fails), so it must NOT
	# appear in the "Available skills:" section.  It is still visible in the
	# ruleset tree expansion.
	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill"
	echo "# Embedded" > "${REPO_DIR}/rulesets/my-ruleset/skills/embedded-skill/SKILL.md"

	cd "${REPO_DIR}" || fail "Failed to cd to REPO_DIR"
	git add . >/dev/null 2>&1
	git commit --no-gpg-sign -m "Add ruleset with embedded skill" >/dev/null 2>&1
	cd "${TEST_DIR}/app" || fail "Failed to cd to app dir"

	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	# Must NOT appear in "Available skills:" — the trailing "/" is the marker
	# used exclusively in the skills section (tree entries have no trailing /)
	echo "${output}" | grep -q "embedded-skill/" && \
		fail "Embedded-only skill must not appear in Available skills: ${output}" || true

	# Must still appear in the ruleset tree (skills/ subdir expansion)
	echo "${output}" | grep -q "embedded-skill" || \
		fail "Embedded skill should still appear in ruleset tree: ${output}"
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
# BEHAVIOR 20: Deduplication — skill in both rules/ and ruleset shown once
# ============================================================================

test_skill_deduplicated_when_in_both_paths() {
	# If a skill name exists in both rules/<name> and rulesets/<r>/skills/<name>,
	# it appears only once in "Available skills:" (from the standalone path).
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
	assertEquals "shared-skill/ should appear exactly once" "1" "${count}"
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

# ============================================================================
# BEHAVIOR 24: "Available rulesets:" section appears after "Available skills:"
# ============================================================================

test_rulesets_section_comes_after_skills_section() {
	# The output order must be:
	#   Available rules: → Available commands: → Available skills: → Available rulesets:
	# Rulesets are last because they are composite items that contain rules,
	# commands, and skills — listing them last keeps the atomic items first.
	# All four section headers are printed unconditionally (even when empty),
	# so no special repo content is required.
	cmd_init "${TEST_SOURCE_REPO}" -d "${TEST_TARGET_DIR}" --commit

	output=$(cmd_list)

	# Extract line numbers of each section header
	skills_line=$(echo "${output}" | grep -n "Available skills:" | cut -d: -f1)
	rulesets_line=$(echo "${output}" | grep -n "Available rulesets:" | cut -d: -f1)

	assertNotNull "Output should contain 'Available skills:'" "${skills_line}"
	assertNotNull "Output should contain 'Available rulesets:'" "${rulesets_line}"

	assertTrue "'Available skills:' should appear before 'Available rulesets:'" \
		"[ '${skills_line}' -lt '${rulesets_line}' ]"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
