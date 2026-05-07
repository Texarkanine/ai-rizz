#!/bin/sh
#
# test_skill_detection.test.sh - Skill detection test suite
#
# Tests the is_skill() function that identifies whether a repository entry is
# a skill directory (containing SKILL.md). Covers both valid skill paths and
# all the invalid / edge-case paths that must return "false".
#
# Capability coverage (is_skill):
#   - Standalone paths under rules/ — valid skill, directory without SKILL.md, disallowed nesting
#   - Embedded paths under rulesets/<r>/skills/<name>/ — valid skill, directory without SKILL.md, disallowed nesting
#   - Invalid layout — rulesets/skills/ without ruleset level, bare rulesets/<name>, empty or unrecognized paths
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_skill_detection.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# TEST HELPERS
#
# Each test sets RULES_PATH and RULESETS_PATH (normally set by cmd_init reading
# the manifest) and creates the directory structure it needs under REPO_DIR.
# ============================================================================

# ============================================================================
# Standalone: valid skill (rules/<name> with SKILL.md)
# ============================================================================

test_standalone_skill_with_skill_md_returns_true() {
	# A rules/<name> directory containing SKILL.md is detected as a skill.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	result=$(is_skill "${REPO_DIR}" "rules/my-skill")
	assertEquals "rules/<name> with SKILL.md should be a skill" "true" "${result}"
}

# ============================================================================
# Standalone: directory without SKILL.md is not a skill
# ============================================================================

test_standalone_dir_without_skill_md_returns_false() {
	# A rules/<name> directory WITHOUT SKILL.md is a plain dir, not a skill.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rules/plain-dir"
	echo "some rule" > "${REPO_DIR}/rules/plain-dir/rule.mdc"

	result=$(is_skill "${REPO_DIR}" "rules/plain-dir")
	assertEquals "rules/<name> without SKILL.md should not be a skill" "false" "${result}"
}

# ============================================================================
# Standalone: nested path under rules/ is rejected
# ============================================================================

test_nested_rules_path_returns_false() {
	# rules/a/b — nesting inside rules/ is not a valid skill location.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rules/outer/inner"
	echo "# Nested" > "${REPO_DIR}/rules/outer/inner/SKILL.md"

	result=$(is_skill "${REPO_DIR}" "rules/outer/inner")
	assertEquals "rules/<a>/<b> should not be a skill (nesting not allowed)" "false" "${result}"
}

# ============================================================================
# Embedded: valid skill (rulesets/<r>/skills/<name> with SKILL.md)
# ============================================================================

test_embedded_skill_with_skill_md_returns_true() {
	# rulesets/<r>/skills/<name> directory with SKILL.md is an embedded skill.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/level1-workflow"
	echo "# Level1" > "${REPO_DIR}/rulesets/my-ruleset/skills/level1-workflow/SKILL.md"

	result=$(is_skill "${REPO_DIR}" "rulesets/my-ruleset/skills/level1-workflow")
	assertEquals "rulesets/<r>/skills/<name> with SKILL.md should be a skill" "true" "${result}"
}

# ============================================================================
# Embedded: directory without SKILL.md is not a skill
# ============================================================================

test_embedded_dir_without_skill_md_returns_false() {
	# rulesets/<r>/skills/<name> directory WITHOUT SKILL.md is NOT a skill.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/not-a-skill"
	echo "just a file" > "${REPO_DIR}/rulesets/my-ruleset/skills/not-a-skill/readme.txt"

	result=$(is_skill "${REPO_DIR}" "rulesets/my-ruleset/skills/not-a-skill")
	assertEquals "rulesets/<r>/skills/<name> without SKILL.md should not be a skill" "false" "${result}"
}

# ============================================================================
# Embedded: nested path under skills/ is rejected
# ============================================================================

test_nested_embedded_skill_path_returns_false() {
	# rulesets/<r>/skills/a/b — nesting inside skills/ is not valid.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rulesets/my-ruleset/skills/parent/child"
	echo "# Child" > "${REPO_DIR}/rulesets/my-ruleset/skills/parent/child/SKILL.md"

	result=$(is_skill "${REPO_DIR}" "rulesets/my-ruleset/skills/parent/child")
	assertEquals "rulesets/<r>/skills/<a>/<b> should not be a skill (nesting not allowed)" "false" "${result}"
}

# ============================================================================
# Invalid paths and unrecognized entries
# ============================================================================

test_rulesets_skills_top_level_returns_false() {
	# rulesets/skills/<name> (no ruleset wrapper between rulesets/ and skills/) is NOT valid.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rulesets/skills/my-skill"
	echo "# Skill" > "${REPO_DIR}/rulesets/skills/my-skill/SKILL.md"

	result=$(is_skill "${REPO_DIR}" "rulesets/skills/my-skill")
	assertEquals "rulesets/skills/<name> (no ruleset level) should not be a skill" "false" "${result}"
}

test_bare_rulesets_entry_returns_false() {
	# rulesets/<name> (top-level ruleset dir, not inside skills/) is NOT a skill.
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	mkdir -p "${REPO_DIR}/rulesets/my-ruleset"
	echo "# Skill" > "${REPO_DIR}/rulesets/my-ruleset/SKILL.md"

	result=$(is_skill "${REPO_DIR}" "rulesets/my-ruleset")
	assertEquals "rulesets/<name> (top-level ruleset) should not be a skill" "false" "${result}"
}

test_empty_entry_returns_false() {
	# Empty or nonsense entry returns "false".
	RULES_PATH="rules"
	RULESETS_PATH="rulesets"

	result=$(is_skill "${REPO_DIR}" "")
	assertEquals "Empty entry should not be a skill" "false" "${result}"

	result=$(is_skill "${REPO_DIR}" "something/completely/different")
	assertEquals "Unrecognized path should not be a skill" "false" "${result}"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
