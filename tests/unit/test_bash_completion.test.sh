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
#   - Symlinked SKILL.md is listed (parity with cmd_list's `[ -f …/SKILL.md ]`)
#   - Plain directories under rules/ without SKILL.md are not listed as names
#   - Existing .mdc rules and lowercase .md commands remain listed
#   - Nested SKILL.md paths (rules/a/b/SKILL.md) are not listed
#
# Capability coverage (_get_repo_dir — mirrors cmd_list repo selection):
#   - Outside a git repo → global cache (_ai-rizz.global), not basename(PWD)
#   - Git repo with project manifest(s) → project cache (repos/<basename>/repo)
#   - Git repo without project manifests → global cache (global-only context)
#
# Capability coverage (_ai_rizz_completion — list flags):
#   - prev=list, empty cur → COMPREPLY contains -a and --all
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

# Invoke _get_repo_dir via bash with an isolated HOME and cwd.
#
# Arguments:
#   $1 - Directory to cd into before calling _get_repo_dir
#   $2 - HOME directory to export (completion resolves caches under $HOME/.config/ai-rizz)
#
# Outputs:
#   Stdout: path returned by _get_repo_dir
#
_call_get_repo_dir() {
	bash -c '
		AI_RIZZ_COMPLETION_TEST=1
		HOME="$2"
		export HOME
		cd "$3" || exit 1
		# shellcheck disable=SC1090
		. "$1"
		_get_repo_dir
	' bash "${_COMPLETION_BASH}" "$2" "$1"
}

# Invoke _ai_rizz_completion with stubbed _init_completion.
#
# _ai_rizz_completion declares `local cur prev`. Bash dynamic scope means a
# stub that assigns those names (without its own local) fills the caller's
# locals. Do not declare local cur/prev in the stub.
#
# Arguments:
#   $1 - prev word (e.g. list)
#   $2 - cur word (may be empty)
#
# Outputs:
#   Stdout: COMPREPLY entries, one per line
#
_complete_with_prev() {
	COMP_TEST_PREV="$1" COMP_TEST_CUR="$2" bash -c '
		AI_RIZZ_COMPLETION_TEST=1
		# shellcheck disable=SC1090
		. "$1"
		_init_completion() {
			prev="${COMP_TEST_PREV}"
			cur="${COMP_TEST_CUR}"
			return 0
		}
		_ai_rizz_completion
		printf "%s\n" "${COMPREPLY[@]}"
	' bash "${_COMPLETION_BASH}"
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
# Symlinked SKILL.md is listed (cmd_list uses [ -f ], which follows symlinks)
# ============================================================================

test_list_rule_names_includes_symlinked_skill_md() {
	# A regular skill dir whose SKILL.md is a symlink to a real file must complete,
	# matching cmd_list / is_skill which test with [ -f …/SKILL.md ].
	mkdir -p "${REPO_DIR}/rules/link-skill" "${REPO_DIR}/skill-targets"
	echo "# Linked Skill" > "${REPO_DIR}/skill-targets/SKILL.md"
	ln -s "../../skill-targets/SKILL.md" "${REPO_DIR}/rules/link-skill/SKILL.md"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "link-skill" || \
		fail "Skill with symlinked SKILL.md should be listed: ${names}"
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

test_list_rule_names_excludes_nested_md_reference() {
	# Skill-local markdown under rules/<skill>/... must not complete as add rule names.
	mkdir -p "${REPO_DIR}/rules/prompt-authoring/references"
	echo "# Skill" > "${REPO_DIR}/rules/prompt-authoring/SKILL.md"
	echo "# Reference" > "${REPO_DIR}/rules/prompt-authoring/references/personality-prompts.md"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "prompt-authoring" || \
		fail "Standalone skill 'prompt-authoring' should be listed: ${names}"
	echo "${names}" | grep -qx "personality-prompts" && \
		fail "Nested reference markdown must not be listed: ${names}"
	return 0
}

# ============================================================================
# _get_repo_dir: outside git → global cache (not basename(pwd))
# ============================================================================

test_get_repo_dir_outside_git_uses_global_cache() {
	# Outside a git repo, completion must use _ai-rizz.global — same as
	# cmd_list's global-only context — not repos/$(basename "$PWD")/repo.
	non_git_dir="${TEST_DIR}/not-a-git-repo"
	mkdir -p "${non_git_dir}"
	fake_home="${TEST_DIR}/fake-home-global"
	mkdir -p "${fake_home}"

	got="$(_call_get_repo_dir "${non_git_dir}" "${fake_home}")"
	expected="${fake_home}/.config/ai-rizz/repos/_ai-rizz.global/repo"
	assertEquals "Outside git should resolve to global cache" "${expected}" "${got}"
}

# ============================================================================
# _get_repo_dir: git repo with project manifest → project cache
# ============================================================================

test_get_repo_dir_with_project_manifest_uses_project_cache() {
	# APP_DIR from common setUp is a git repo. A commit manifest means
	# local/commit mode is active → project cache repos/<basename>/repo
	# when that cache has a rules/ directory.
	printf 'file://dummy\t.cursor/rules\trules\trulesets\n' > "${APP_DIR}/ai-rizz.skbd"
	fake_home="${TEST_DIR}/fake-home-project"
	project_name="$(basename "${APP_DIR}")"
	mkdir -p "${fake_home}/.config/ai-rizz/repos/${project_name}/repo/rules"

	got="$(_call_get_repo_dir "${APP_DIR}" "${fake_home}")"
	expected="${fake_home}/.config/ai-rizz/repos/${project_name}/repo"
	assertEquals "Project manifest should resolve to project cache" "${expected}" "${got}"
}

test_get_repo_dir_falls_back_to_global_when_project_cache_missing() {
	printf 'file://dummy\t.cursor/rules\trules\trulesets\n' > "${APP_DIR}/ai-rizz.skbd"
	fake_home="${TEST_DIR}/fake-home-fallback"
	mkdir -p "${fake_home}/.config/ai-rizz/repos/_ai-rizz.global/repo/rules"

	got="$(_call_get_repo_dir "${APP_DIR}" "${fake_home}")"
	expected="${fake_home}/.config/ai-rizz/repos/_ai-rizz.global/repo"
	assertEquals "Missing project cache should fall back to global cache" "${expected}" "${got}"
}

# ============================================================================
# _get_repo_dir: git repo without project manifests → global cache
# ============================================================================

test_get_repo_dir_git_without_project_manifest_uses_global_cache() {
	# Git repo with neither ai-rizz.skbd nor ai-rizz.local.skbd is global-only.
	bare_git="${TEST_DIR}/bare-git-global-only"
	mkdir -p "${bare_git}"
	(
		cd "${bare_git}" || exit 1
		git init . >/dev/null 2>&1
		git config user.email "test@example.com" >/dev/null 2>&1
		git config user.name "Test User" >/dev/null 2>&1
		echo x > file.txt
		git add file.txt >/dev/null 2>&1
		git commit --no-gpg-sign -m "init" >/dev/null 2>&1
	)
	fake_home="${TEST_DIR}/fake-home-git-global"
	mkdir -p "${fake_home}"

	got="$(_call_get_repo_dir "${bare_git}" "${fake_home}")"
	expected="${fake_home}/.config/ai-rizz/repos/_ai-rizz.global/repo"
	assertEquals "Git without project manifests should use global cache" "${expected}" "${got}"
}

# list completes -a and --all
test_list_completes_all_flags() {
	names="$(_complete_with_prev list "")"
	echo "${names}" | grep -qx -- "-a" || \
		fail "list should complete -a: ${names}"
	echo "${names}" | grep -qx -- "--all" || \
		fail "list should complete --all: ${names}"
	return 0
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
