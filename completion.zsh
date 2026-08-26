#compdef ai-rizz
# shellcheck shell=zsh

# Zsh completion for ai-rizz CLI tool
# Provides tab completion for commands, rules, and rulesets
#
# Discovery helpers (_get_repo_dir, _ai_rizz_list_rule_names) must stay in lockstep
# with completion.bash — same algorithm as cmd_list catalog discovery.
#
# Installation:
#   Source this file from ~/.zshrc (see install-zsh-completion.sh)
#
# Testing:
#   Set AI_RIZZ_COMPLETION_TEST=1 before sourcing to skip compdef registration.

# Resolve the source-repo cache directory for completion (mirrors cmd_list)
_get_repo_dir() {
	local grd_config_dir="${HOME}/.config/ai-rizz"
	local grd_global_repo="${grd_config_dir}/repos/_ai-rizz.global/repo"
	local grd_git_root grd_project_name grd_project_repo

	if grd_git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
		if [[ -f "${grd_git_root}/ai-rizz.skbd" || -f "${grd_git_root}/ai-rizz.local.skbd" ]]; then
			grd_project_name="$(basename "${grd_git_root}")"
			grd_project_repo="${grd_config_dir}/repos/${grd_project_name}/repo"
			if [[ -d "${grd_project_repo}/rules" ]]; then
				print -r -- "${grd_project_repo}"
				return 0
			fi
		fi
	fi

	print -r -- "${grd_global_repo}"
}

# List completable names after `ai-rizz add rule` / `remove rule`
# Algorithm matches completion.bash / cmd_list (top-level rules, commands, skills only).
_ai_rizz_list_rule_names() {
	local lrn_repo_dir="$1"
	local lrn_rules_dir="${lrn_repo_dir}/rules"
	local lrn_skill_md lrn_skill_name

	if [[ ! -d "${lrn_rules_dir}" ]]; then
		return 0
	fi

	find "${lrn_rules_dir}" -maxdepth 1 -type f -name "*.mdc" | sed -e 's|.*/||' -e 's/\.mdc$//'
	find "${lrn_rules_dir}" -maxdepth 1 -type f -name "*.md" | sed 's|.*/||' | LC_ALL=C grep -v '^[A-Z]' | sed 's/\.md$//'

	while IFS= read -r lrn_skill_md; do
		[[ -f "${lrn_skill_md}" ]] || continue
		lrn_skill_name="${lrn_skill_md%/*}"
		print -r -- "${lrn_skill_name##*/}"
	done < <(find "${lrn_rules_dir}" -mindepth 2 -maxdepth 2 \( -type f -o -type l \) -name "SKILL.md")
}

_ai_rizz() {
	local aic_prev="${words[CURRENT - 1]}"

	# Dispatch mirrors completion.bash _ai_rizz_completion (prev-word cases).
	case "${aic_prev}" in
		ai-rizz)
			compadd init deinit list add remove sync help
			;;
		add|remove)
			compadd rule ruleset
			;;
		init)
			compadd -- --local -l --commit -c -d -f --manifest -s --skibidi
			;;
		deinit)
			compadd -- --local -l --commit -c --global -g --both -b -y
			;;
		list)
			compadd -- -a --all
			;;
		-d|-f|--manifest|-s|--skibidi)
			;;
		rule)
			local aic_repo_dir aic_rules_output
			aic_repo_dir="$(_get_repo_dir)"
			if [[ -d "${aic_repo_dir}/rules" ]]; then
				aic_rules_output="$(_ai_rizz_list_rule_names "${aic_repo_dir}")"
				[[ -n "${aic_rules_output}" ]] && compadd -- ${(f)aic_rules_output}
			fi
			;;
		ruleset)
			local aic_repo_dir aic_rulesets_output
			aic_repo_dir="$(_get_repo_dir)"
			if [[ -d "${aic_repo_dir}/rulesets" ]]; then
				aic_rulesets_output="$(find "${aic_repo_dir}/rulesets" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||')"
				[[ -n "${aic_rulesets_output}" ]] && compadd -- ${(f)aic_rulesets_output}
			fi
			;;
	esac
}

_ai_rizz_register_completion() {
	if [[ -n "${AI_RIZZ_COMPLETION_TEST:-}" ]]; then
		return 0
	fi
	if (( ! $+functions[compdef] )); then
		autoload -Uz compinit compdef
		compinit -C
	fi
	compdef _ai_rizz ai-rizz
}

_ai_rizz_register_completion
