# Bash completion for ai-rizz CLI tool
# Provides tab completion for commands, rules, and rulesets
#
# This completion script supports:
# - Command completion (init, deinit, list, add, remove, sync, help)
# - Rule and ruleset type completion for add/remove commands
# - Dynamic rule completion from the current project's repository
#   (includes both .mdc rules and .md commands)
# - Dynamic ruleset completion from the current project's repository
#
# Installation:
#   Source this file in your .bashrc or place in /etc/bash_completion.d/


# Get repository directory for the current project (matches ai-rizz get_repo_dir function)
#
# Globals:
#   HOME - User home directory
#
# Arguments:
#   None
#
# Outputs:
#   Stdout: Repository directory path for current project
#
# Returns:
#   0 on success
#
_get_repo_dir() {
	local config_dir="${HOME}/.config/ai-rizz"
	local project_name
	local git_root
	
	# Use git root directory name as project name, fallback to current directory
	if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
		project_name="$(basename "${git_root}")"
	else
		project_name="$(basename "$(pwd)")"
	fi
	
	echo "${config_dir}/repos/${project_name}/repo"
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
			# Get available rules and commands from the current project's repo
			# Rules are .mdc files, commands are .md files
			local repo_dir
			repo_dir="$(_get_repo_dir)"
			if [[ -d "${repo_dir}/rules" ]]; then
				COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rules" -type f \( -name "*.mdc" -o -name "*.md" \) -printf "%f\n" | grep -v '^[A-Z]' | sed 's/\.\(mdc\|md\)$//')" -- "${cur}") )
			fi
			;;
		ruleset)
			# Get available rulesets from the current project's repo
			local repo_dir
			repo_dir="$(_get_repo_dir)"
			if [[ -d "${repo_dir}/rulesets" ]]; then
				COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rulesets" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")" -- "${cur}") )
			fi
			;;
	esac
}

# Register the completion function
complete -F _ai_rizz_completion ai-rizz
