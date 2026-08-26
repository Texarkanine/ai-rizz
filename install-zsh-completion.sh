#!/bin/sh
# install-zsh-completion.bash
#
# Installs or uninstalls the ai-rizz zsh completion fenced block in ~/.zshrc.
# Usage:
#   ./install-zsh-completion.bash install   # Add or update fenced block
#   ./install-zsh-completion.bash uninstall # Remove fenced block
#
# - Always uses ~/.zshrc (cross-platform)
# - Idempotent: removes any previous ai-rizz block before adding
# - Sourcing path is always the absolute path to completion.zsh in the current directory
#
# Returns 0 on success, 1 on error.

set -e

FENCE_START="# >>> ai-rizz zsh completion >>>"
FENCE_END="# <<< ai-rizz zsh completion <<<"
COMPLETIONS_FILE="$HOME/.zshrc"
COMPLETION_ZSH_PATH="$(cd "$(dirname "$0")" && pwd)/completion.zsh"

usage() {
  echo "Usage: $0 install|uninstall" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  usage
fi

case "$1" in
  install)
    mkdir -p "$HOME"
    touch "$COMPLETIONS_FILE"
    awk -v start="$FENCE_START" -v end="$FENCE_END" 'BEGIN{inblock=0} {if($0==start){inblock=1} else if($0==end){inblock=0; next} if(!inblock) print $0}' "$COMPLETIONS_FILE" > "$COMPLETIONS_FILE.tmp"
    mv "$COMPLETIONS_FILE.tmp" "$COMPLETIONS_FILE"
    {
      echo "$FENCE_START"
      echo "autoload -Uz compinit compdef"
      echo "compinit -C"
      echo "if [ -f \"$COMPLETION_ZSH_PATH\" ]; then"
      echo "  source \"$COMPLETION_ZSH_PATH\""
      echo "fi"
      echo "$FENCE_END"
    } >> "$COMPLETIONS_FILE"
    ;;
  uninstall)
    if [ -f "$COMPLETIONS_FILE" ]; then
      awk -v start="$FENCE_START" -v end="$FENCE_END" 'BEGIN{inblock=0} {if($0==start){inblock=1} else if($0==end){inblock=0; next} if(!inblock) print $0}' "$COMPLETIONS_FILE" > "$COMPLETIONS_FILE.tmp"
      mv "$COMPLETIONS_FILE.tmp" "$COMPLETIONS_FILE"
    fi
    ;;
  *)
    usage
    ;;
esac

exit 0
