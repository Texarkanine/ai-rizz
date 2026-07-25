#!/bin/sh
#
# test_resolve_standalone_entry.test.sh - Standalone entry resolve helper tests
#
# Tests resolve_standalone_entry(): exact-path hits, slug-preserving remaps
# across rule/command/skill forms, priority (skill → .mdc → .md), and misses.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_resolve_standalone_entry.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# Exact path wins
# ============================================================================

test_resolve_exact_mdc_when_present() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	echo "rule" > "${REPO_DIR}/rules/foo.mdc"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.mdc")
	assertEquals "Exact .mdc path should be returned" "rules/foo.mdc" "${result}"
}

test_resolve_exact_md_when_present() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	echo "cmd" > "${REPO_DIR}/rules/foo.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.md")
	assertEquals "Exact .md path should be returned" "rules/foo.md" "${result}"
}

test_resolve_exact_skill_when_present() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	mkdir -p "${REPO_DIR}/rules/foo"
	echo "# Skill" > "${REPO_DIR}/rules/foo/SKILL.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo")
	assertEquals "Exact skill path should be returned" "rules/foo" "${result}"
}

test_resolve_exact_mdc_wins_over_coexisting_skill() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	echo "rule" > "${REPO_DIR}/rules/foo.mdc"
	mkdir -p "${REPO_DIR}/rules/foo"
	echo "# Skill" > "${REPO_DIR}/rules/foo/SKILL.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.mdc")
	assertEquals "Exact .mdc must win when both exist" "rules/foo.mdc" "${result}"
}

# ============================================================================
# Slug-preserving remaps
# ============================================================================

test_resolve_mdc_to_skill_when_mdc_missing() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	mkdir -p "${REPO_DIR}/rules/foo"
	echo "# Skill" > "${REPO_DIR}/rules/foo/SKILL.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.mdc")
	assertEquals "Missing .mdc should remap to skill" "rules/foo" "${result}"
}

test_resolve_md_to_skill_when_md_missing() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	mkdir -p "${REPO_DIR}/rules/foo"
	echo "# Skill" > "${REPO_DIR}/rules/foo/SKILL.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.md")
	assertEquals "Missing .md should remap to skill" "rules/foo" "${result}"
}

test_resolve_skill_to_mdc_when_skill_missing() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	echo "rule" > "${REPO_DIR}/rules/foo.mdc"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo")
	assertEquals "Missing skill should remap to .mdc" "rules/foo.mdc" "${result}"
}

test_resolve_skill_to_md_when_skill_missing() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	echo "cmd" > "${REPO_DIR}/rules/foo.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo")
	assertEquals "Missing skill should remap to .md" "rules/foo.md" "${result}"
}

test_resolve_mdc_to_md_when_mdc_missing() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	echo "cmd" > "${REPO_DIR}/rules/foo.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.mdc")
	assertEquals "Missing .mdc should remap to .md" "rules/foo.md" "${result}"
}

# ============================================================================
# Priority and misses
# ============================================================================

test_resolve_prefers_skill_over_md_when_mdc_missing() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	mkdir -p "${REPO_DIR}/rules/foo"
	echo "# Skill" > "${REPO_DIR}/rules/foo/SKILL.md"
	echo "cmd" > "${REPO_DIR}/rules/foo.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/foo.mdc")
	assertEquals "Skill should beat .md when remapping" "rules/foo" "${result}"
}

test_resolve_missing_slug_returns_empty() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rules/gone.mdc")
	assertEquals "Truly missing slug should return empty" "" "${result}"
}

test_resolve_ruleset_entry_not_remapped() {
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"
	# A same-named skill must not satisfy a missing ruleset entry
	mkdir -p "${REPO_DIR}/rules/myset"
	echo "# Skill" > "${REPO_DIR}/rules/myset/SKILL.md"

	result=$(resolve_standalone_entry "${REPO_DIR}" "rulesets/myset")
	assertEquals "Ruleset entries must not be slug-remapped" "" "${result}"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
