#!/bin/sh
#
# test_skill_detection.test.sh - Skill detection test suite
#
# Tests the is_skill() function that identifies whether a repository entry is
# a skill directory (containing SKILL.md). Covers both valid skill paths and
# all the invalid / edge-case paths that must return "false".
#
# Test Coverage (behaviors 1-7 from the skill-support plan):
#   1. rules/<name> with SKILL.md → "true"  (standalone skill)
#   2. rules/<name> without SKILL.md → "false"  (plain dir, not a skill)
#   3. rules/<a>/<b> (nested) → "false"  (nesting not allowed)
#   4. rulesets/<r>/skills/<name> with SKILL.md → "true"  (embedded skill)
#   5. rulesets/<r>/skills/<name> without SKILL.md → "false"
#   6. rulesets/<r>/skills/<a>/<b> (nested) → "false"
#   7. Non-matching paths → "false"  (e.g. rulesets/skills/<name>, bare rulesets/<name>)
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
# BEHAVIOR 1: rules/<name> with SKILL.md → "true"
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
# BEHAVIOR 2: rules/<name> without SKILL.md → "false"
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
# BEHAVIOR 3: rules/<a>/<b> (nested path) → "false"
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
# BEHAVIOR 4: rulesets/<r>/skills/<name> with SKILL.md → "true"
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
# BEHAVIOR 5: rulesets/<r>/skills/<name> without SKILL.md → "false"
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
# BEHAVIOR 6: rulesets/<r>/skills/<a>/<b> (nested) → "false"
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
# BEHAVIOR 7: Non-matching paths → "false"
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
