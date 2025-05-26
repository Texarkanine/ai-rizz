# Bash completion for ai-rizz

# Repository Directory Functions
# ==============================

# Get repository directory for the current project (matches ai-rizz get_repo_dir function)
_get_repo_dir() {
    local config_dir="${HOME}/.config/ai-rizz"
    local project_name
    
    # Use git root directory name as project name, fallback to current directory
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        project_name=$(basename "${git_root}")
    else
        project_name=$(basename "$(pwd)")
    fi
    
    echo "${config_dir}/repos/${project_name}/repo"
}

_ai_rizz_completion() {
    local cur prev words cword
    _init_completion || return

    case $prev in
        ai-rizz)
            COMPREPLY=( $(compgen -W "init deinit list add remove sync help" -- "$cur") )
            ;;
        add|remove)
            COMPREPLY=( $(compgen -W "rule ruleset" -- "$cur") )
            ;;
        rule)
            # Get available rules from the current project's repo
            local repo_dir
            repo_dir=$(_get_repo_dir)
            if [ -d "${repo_dir}/rules" ]; then
                COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rules" -name "*.mdc" -printf "%f\n" | sed 's/\.mdc$//')" -- "${cur}") )
            fi
            ;;
        ruleset)
            # Get available rulesets from the current project's repo
            local repo_dir
            repo_dir=$(_get_repo_dir)
            if [ -d "${repo_dir}/rulesets" ]; then
                COMPREPLY=( $(compgen -W "$(find "${repo_dir}/rulesets" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")" -- "${cur}") )
            fi
            ;;
    esac
}

complete -F _ai_rizz_completion ai-rizz
