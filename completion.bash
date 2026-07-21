# Bash completion for ai-rizz CLI tool
# Provides tab completion for commands, rules, and rulesets
#
# This completion script supports:
# - Command completion (init, deinit, list, add, remove, sync, help)
# - Rule and ruleset type completion for add/remove commands
# - Dynamic rule completion from the current project's repository
#   (includes .mdc rules, .md commands, and standalone skills under rules/)
# - Dynamic ruleset completion from the current project's repository
#
# Installation:
#   Source this file in your .bashrc or place in /etc/bash_completion.d/
#
# Testing:
#   Set AI_RIZZ_COMPLETION_TEST=1 before sourcing to skip `complete -F` registration.


# Resolve the source-repo cache directory for completion (mirrors cmd_list)
#
# Selects the same cache ai-rizz uses when listing available items:
# - Project cache when the cwd's git root has a local/commit manifest
# - Global cache (_ai-rizz.global) otherwise (outside git, or global-only)
#
# Globals:
#   HOME - User home directory
#
# Arguments:
#   None
#
# Outputs:
#   Stdout: Repository directory path for completion discovery
#
# Returns:
#   0 on success
#
_get_repo_dir() {
	local config_dir="${HOME}/.config/ai-rizz"
	local global_repo="${config_dir}/repos/_ai-rizz.global/repo"
	local git_root project_name

	if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
		# Local/commit mode active when either project manifest exists (cmd_list)
		if [[ -f "${git_root}/ai-rizz.skbd" || -f "${git_root}/ai-rizz.local.skbd" ]]; then
			project_name="$(basename "${git_root}")"
			echo "${config_dir}/repos/${project_name}/repo"
			return 0
		fi
	fi

	# Global-only context: outside git, or git repo with no project manifests
	echo "${global_repo}"
}

# List completable names after `ai-rizz add rule` / `remove rule`
#
# Emits one name per line for entities installable via `add rule`:
# - `.mdc` rule files under rules/
# - lowercase `.md` command files under rules/ (uppercase docs like README.md excluded)
# - standalone skill directories: rules/<name>/SKILL.md
#
# Globals:
#   None
#
# Arguments:
#   $1 - Repository directory (cache clone root containing rules/)
#
# Outputs:
#   Stdout: completion names, one per line
#
# Returns:
#   0 on success
#
_ai_rizz_list_rule_names() {
	local repo_dir="$1"
	local rules_dir="${repo_dir}/rules"

	if [[ ! -d "${rules_dir}" ]]; then
		return 0
	fi

	# .mdc rules (all) and .md commands (exclude uppercase docs like README.md)
	find "${rules_dir}" -type f -name "*.mdc" | sed -e 's|.*/||' -e 's/\.mdc$//'
	find "${rules_dir}" -type f -name "*.md" | sed 's|.*/||' | LC_ALL=C grep -v '^[A-Z]' | sed 's/\.md$//'

	# Standalone skills: rules/<name>/SKILL.md (exactly one level under rules/).
	# Include symlinked SKILL.md; keep only paths that `[ -f ]` accepts (same as
	# cmd_list / is_skill), so dangling symlinks are omitted.
	local skill_md skill_name
	while IFS= read -r skill_md; do
		[[ -f "${skill_md}" ]] || continue
		skill_name="${skill_md%/*}"
		printf '%s\n' "${skill_name##*/}"
	done < <(find "${rules_dir}" -mindepth 2 -maxdepth 2 \( -type f -o -type l \) -name "SKILL.md")
}

# Main completion function for ai-rizz
#
# Globals:
#   COMPREPLY - Bash completion reply array
#
# Arguments:
#   None (uses bash completion variables)
#
# Outputs:
#   Sets COMPREPLY array with completion options
#
# Returns:
#   0 on success
#
_ai_rizz_completion() {
	local cur prev words cword
	_init_completion || return

	case "${prev}" in
		ai-rizz)
			COMPREPLY=( $(compgen -W "init deinit list add remove sync help" -- "${cur}") )
			;;
		add|remove)
			COMPREPLY=( $(compgen -W "rule ruleset" -- "${cur}") )
			;;
		init)
			COMPREPLY=( $(compgen -W "--local -l --commit -c -d -f --manifest -s --skibidi" -- "${cur}") )
			;;
		-d|-f|--manifest|-s|--skibidi)
			# These options take a value, no completion needed
			COMPREPLY=()
			;;
		rule)
			# Get available rules, commands, and standalone skills from the project's repo
			local repo_dir rules_list
			repo_dir="$(_get_repo_dir)"
			if [[ -d "${repo_dir}/rules" ]]; then
				rules_list="$(_ai_rizz_list_rule_names "${repo_dir}")"
				COMPREPLY=( $(compgen -W "${rules_list}" -- "${cur}") )
			fi
			;;
		ruleset)
			# Get available rulesets from the current project's repo
			local repo_dir
			repo_dir="$(_get_repo_dir)"
			if [[ -d "${repo_dir}/rulesets" ]]; then
				COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rulesets" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||')" -- "${cur}") )
			fi
			;;
	esac
}

# Register the completion function (skip when sourced under tests)
if [[ -z "${AI_RIZZ_COMPLETION_TEST:-}" ]]; then
	complete -F _ai_rizz_completion ai-rizz
fi
