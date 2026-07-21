#!/bin/sh
#
# test_bash_completion.test.sh - Bash completion listing test suite
#
# Tests _ai_rizz_list_rule_names() from completion.bash: the names offered after
# `ai-rizz add rule` / `remove rule`. Covers rules, commands, and standalone
# skills (rules/<name>/SKILL.md). Skills are installed via `add rule`, not a
# separate type — completion must include them in the rule-name list.
#
# Capability coverage (_ai_rizz_list_rule_names):
#   - Standalone skill directories under rules/ with SKILL.md are listed
#   - Plain directories under rules/ without SKILL.md are not listed as names
#   - Existing .mdc rules and lowercase .md commands remain listed
#   - Nested SKILL.md paths (rules/a/b/SKILL.md) are not listed
#
# Dependencies: shunit2, common test utilities, bash (completion.bash is bash)
# Usage: sh test_bash_completion.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Resolve completion.bash to an absolute path before setUp cds away.
_COMPLETION_BASH=""
if [ -n "${AI_RIZZ_PATH}" ] && [ -f "$(dirname "${AI_RIZZ_PATH}")/completion.bash" ]; then
	_COMPLETION_BASH="$(cd "$(dirname "${AI_RIZZ_PATH}")" && pwd)/completion.bash"
elif [ -f "./completion.bash" ]; then
	_COMPLETION_BASH="$(pwd)/completion.bash"
elif [ -f "$(dirname "$0")/../../completion.bash" ]; then
	_COMPLETION_BASH="$(cd "$(dirname "$0")/../.." && pwd)/completion.bash"
else
	echo "ERROR: Cannot find completion.bash" >&2
	exit 1
fi

# Invoke _ai_rizz_list_rule_names via bash (completion.bash is bash-specific).
#
# Arguments:
#   $1 - Repository directory path
#
# Outputs:
#   Stdout: completion names, one per line (sorted for stable asserts)
#
_list_rule_names() {
	bash -c '
		AI_RIZZ_COMPLETION_TEST=1
		# shellcheck disable=SC1090
		. "$1"
		_ai_rizz_list_rule_names "$2"
	' bash "${_COMPLETION_BASH}" "$1" | sort
}

# ============================================================================
# Standalone skill directories appear in rule-name completions
# ============================================================================

test_list_rule_names_includes_standalone_skill() {
	# rules/<name>/SKILL.md is installable via `add rule <name>` and must complete.
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "my-skill" || \
		fail "Standalone skill 'my-skill' should be listed: ${names}"
	return 0
}

# ============================================================================
# Plain directories under rules/ without SKILL.md are not listed
# ============================================================================

test_list_rule_names_excludes_non_skill_directory() {
	# A rules/<name> directory without SKILL.md is not a skill and must not
	# appear as a bare completion name (its .mdc children may still list).
	# Assert a known positive name too so an empty stub cannot pass this test.
	mkdir -p "${REPO_DIR}/rules/plain-dir"
	echo "nested rule" > "${REPO_DIR}/rules/plain-dir/nested.mdc"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "rule1" || \
		fail "Baseline rule 'rule1' should still be listed: ${names}"
	echo "${names}" | grep -qx "plain-dir" && \
		fail "Non-skill directory 'plain-dir' must not be listed: ${names}"
	return 0
}

# ============================================================================
# Existing .mdc rules and lowercase .md commands remain listed
# ============================================================================

test_list_rule_names_includes_rules_and_commands() {
	# Baseline fixtures from common setUp include rule1.mdc and command1.md.
	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "rule1" || \
		fail "Rule 'rule1' should be listed: ${names}"
	echo "${names}" | grep -qx "command1" || \
		fail "Command 'command1' should be listed: ${names}"
	return 0
}

# ============================================================================
# Nested SKILL.md paths are not listed (standalone skills are one level only)
# ============================================================================

test_list_rule_names_excludes_nested_skill_path() {
	# rules/outer/inner/SKILL.md is not a valid standalone skill path.
	# Assert a known positive name too so an empty stub cannot pass this test.
	mkdir -p "${REPO_DIR}/rules/outer/inner"
	echo "# Nested" > "${REPO_DIR}/rules/outer/inner/SKILL.md"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "rule1" || \
		fail "Baseline rule 'rule1' should still be listed: ${names}"
	echo "${names}" | grep -qx "inner" && \
		fail "Nested skill basename 'inner' must not be listed: ${names}"
	echo "${names}" | grep -qx "outer" && \
		fail "Parent dir 'outer' of nested skill must not be listed: ${names}"
	return 0
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
