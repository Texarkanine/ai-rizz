#!/bin/sh
#
# test_zsh_completion.test.sh - Zsh completion listing test suite
#
# Mirrors test_bash_completion.test.sh for completion.zsh.
#
# Dependencies: shunit2, common test utilities, zsh (completion.zsh is zsh-specific)
# Usage: sh test_zsh_completion.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Zsh tests fail (not skip) if zsh is not on PATH
if ! command -v zsh >/dev/null 2>&1; then
	echo "ERROR: zsh is required for test_zsh_completion.test.sh but was not found on PATH" >&2
	exit 1
fi

# Resolve completion.zsh to an absolute path before setUp cds away.
_COMPLETION_ZSH=""
if [ -n "${AI_RIZZ_PATH}" ] && [ -f "$(dirname "${AI_RIZZ_PATH}")/completion.zsh" ]; then
	_COMPLETION_ZSH="$(cd "$(dirname "${AI_RIZZ_PATH}")" && pwd)/completion.zsh"
elif [ -f "./completion.zsh" ]; then
	_COMPLETION_ZSH="$(pwd)/completion.zsh"
elif [ -f "$(dirname "$0")/../../completion.zsh" ]; then
	_COMPLETION_ZSH="$(cd "$(dirname "$0")/../.." && pwd)/completion.zsh"
else
	echo "ERROR: Cannot find completion.zsh" >&2
	exit 1
fi

# Invoke _ai_rizz_list_rule_names via zsh.
#
# Arguments:
#   $1 - Repository directory path
#
# Outputs:
#   Stdout: completion names, one per line (sorted for stable asserts)
#
_list_rule_names() {
	zsh -c '
		AI_RIZZ_COMPLETION_TEST=1
		# shellcheck disable=SC1090
		. "$1"
		_ai_rizz_list_rule_names "$2"
	' zsh "${_COMPLETION_ZSH}" "$1" | sort
}

# Invoke _get_repo_dir via zsh with an isolated HOME and cwd.
#
# Arguments:
#   $1 - Directory to cd into before calling _get_repo_dir
#   $2 - HOME directory to export
#
# Outputs:
#   Stdout: path returned by _get_repo_dir
#
_call_get_repo_dir() {
	zsh -c '
		AI_RIZZ_COMPLETION_TEST=1
		HOME="$2"
		export HOME
		cd "$3" || exit 1
		# shellcheck disable=SC1090
		. "$1"
		_get_repo_dir
	' zsh "${_COMPLETION_ZSH}" "$2" "$1"
}

# Invoke _ai_rizz with stubbed compadd for list-flag completion (prev=list).
#
# Outputs:
#   Stdout: completion entries, one per line
#
_complete_list_flags() {
	zsh -c '
		AI_RIZZ_COMPLETION_TEST=1
		# shellcheck disable=SC1090
		. "$1"
		words=(ai-rizz list "")
		CURRENT=3
		compadd() {
			local a
			for a; do
				[[ "$a" == -- ]] && continue
				print -r -- "$a"
			done
		}
		_ai_rizz
	' zsh "${_COMPLETION_ZSH}"
}

test_list_rule_names_includes_standalone_skill() {
	mkdir -p "${REPO_DIR}/rules/my-skill"
	echo "# My Skill" > "${REPO_DIR}/rules/my-skill/SKILL.md"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "my-skill" || \
		fail "Standalone skill 'my-skill' should be listed: ${names}"
	return 0
}

test_list_rule_names_includes_symlinked_skill_md() {
	mkdir -p "${REPO_DIR}/rules/link-skill" "${REPO_DIR}/skill-targets"
	echo "# Linked Skill" > "${REPO_DIR}/skill-targets/SKILL.md"
	ln -s "../../skill-targets/SKILL.md" "${REPO_DIR}/rules/link-skill/SKILL.md"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "link-skill" || \
		fail "Skill with symlinked SKILL.md should be listed: ${names}"
	return 0
}

test_list_rule_names_excludes_non_skill_directory() {
	mkdir -p "${REPO_DIR}/rules/plain-dir"
	echo "nested rule" > "${REPO_DIR}/rules/plain-dir/nested.mdc"

	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "rule1" || \
		fail "Baseline rule 'rule1' should still be listed: ${names}"
	echo "${names}" | grep -qx "plain-dir" && \
		fail "Non-skill directory 'plain-dir' must not be listed: ${names}"
	return 0
}

test_list_rule_names_includes_rules_and_commands() {
	names="$(_list_rule_names "${REPO_DIR}")"
	echo "${names}" | grep -qx "rule1" || \
		fail "Rule 'rule1' should be listed: ${names}"
	echo "${names}" | grep -qx "command1" || \
		fail "Command 'command1' should be listed: ${names}"
	return 0
}

test_list_rule_names_excludes_nested_skill_path() {
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

test_get_repo_dir_outside_git_uses_global_cache() {
	non_git_dir="${TEST_DIR}/not-a-git-repo"
	mkdir -p "${non_git_dir}"
	fake_home="${TEST_DIR}/fake-home-global"
	mkdir -p "${fake_home}"

	got="$(_call_get_repo_dir "${non_git_dir}" "${fake_home}")"
	expected="${fake_home}/.config/ai-rizz/repos/_ai-rizz.global/repo"
	assertEquals "Outside git should resolve to global cache" "${expected}" "${got}"
}

test_get_repo_dir_with_project_manifest_uses_project_cache() {
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

test_get_repo_dir_git_without_project_manifest_uses_global_cache() {
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

test_list_completes_all_flags() {
	names="$(_complete_list_flags)"
	echo "${names}" | grep -qx -- "-a" || \
		fail "list should complete -a: ${names}"
	echo "${names}" | grep -qx -- "--all" || \
		fail "list should complete --all: ${names}"
	return 0
}

test_registers_compdef_without_prior_compinit() {
	# Minimal zsh (-f): no .zshrc, no compinit — completion must self-register.
	got="$(zsh -f -c '
		emulate -L zsh
		# shellcheck disable=SC1090
		. "$1"
		if [[ -n ${_comps[ai-rizz]:-} ]]; then
			print -r -- yes
		else
			print -r -- no
		fi
	' zsh "${_COMPLETION_ZSH}")"
	assertEquals "should register compdef when compinit was not preloaded" "yes" "${got}"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
