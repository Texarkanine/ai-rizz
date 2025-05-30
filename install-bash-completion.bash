#!/bin/sh
# install-bash-completion.bash
#
# Installs or uninstalls the ai-rizz bash completion fenced block in ~/.bash_completion.
# Usage:
#   ./install-bash-completion.bash install   # Add or update fenced block
#   ./install-bash-completion.bash uninstall # Remove fenced block
#
# - Always uses ~/.bash_completion (cross-platform)
# - Idempotent: removes any previous ai-rizz block before adding
# - Sourcing path is always the absolute path to completion.bash in the current directory
#
# Returns 0 on success, 1 on error.

set -e

FENCE_START="# >>> ai-rizz bash completion >>>"
FENCE_END="# <<< ai-rizz bash completion <<<"
COMPLETIONS_FILE="$HOME/.bash_completion"
COMPLETION_BASH_PATH="$(cd "$(dirname "$0")" && pwd)/completion.bash"

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
    # Remove any previous ai-rizz fenced block
    awk -v start="$FENCE_START" -v end="$FENCE_END" 'BEGIN{inblock=0} {if($0==start){inblock=1} else if($0==end){inblock=0; next} if(!inblock) print $0}' "$COMPLETIONS_FILE" > "$COMPLETIONS_FILE.tmp"
    mv "$COMPLETIONS_FILE.tmp" "$COMPLETIONS_FILE"
    # Append new fenced block
    {
      echo "$FENCE_START"
      echo "if [ -f \"$COMPLETION_BASH_PATH\" ]; then"
      echo "  source \"$COMPLETION_BASH_PATH\""
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