# Bash completion for ai-rizz
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
            # Get available rules from the repo
            if [ -d "$HOME/.config/ai-rizz/repo/rules" ]; then
                COMPREPLY=( $(compgen -W "$(find "$HOME/.config/ai-rizz/repo/rules" -name "*.mdc" -printf "%f\n" | sed 's/\.mdc$//')" -- "$cur") )
            fi
            ;;
        ruleset)
            # Get available rulesets from the repo
            if [ -d "$HOME/.config/ai-rizz/repo/rulesets" ]; then
                COMPREPLY=( $(compgen -W "$(find "$HOME/.config/ai-rizz/repo/rulesets" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")" -- "$cur") )
            fi
            ;;
    esac
}

complete -F _ai_rizz_completion ai-rizz 