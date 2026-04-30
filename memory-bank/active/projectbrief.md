# Project Brief: Fix silent failure on `ai-rizz add rule --global`

## Problem

`ai-rizz add rule <name> --global` silently exits with code 1 and no output when global mode is not initialized (no `~/ai-rizz.skbd`). The root cause is `sync_global_repo()` returning 1 with no error message when `get_global_source_repo()` returns empty, and `set -e` kills the script before any user-facing output.

## Requirements

- Produce an actionable error message when `--global` is used but global mode hasn't been initialized
- Error should guide the user to run `ai-rizz init <repo> --global` first
- Investigate WSL symlink situation as secondary concern
