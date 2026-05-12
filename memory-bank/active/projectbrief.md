# Project Brief: macOS/BSD Cross-Platform Bug Fixes

## Summary

Fix three cross-platform bugs that break ai-rizz on macOS/BSD systems.

## Bugs

### Bug 1: GNU-only `find -printf` in `completion.bash`

Lines 84, 85, 95 use `-printf "%f\n"` which is a GNU find extension. BSD/macOS `find` rejects it. Replace with portable `sed 's|.*/||'` equivalents.

### Bug 2: Locale-sensitive `[A-Z]` glob drops `.md` commands

On macOS with `LANG=en_US.UTF-8`, shell glob `[A-Z]` uses dictionary collation and matches lowercase letters. This causes `.md` command files to be silently skipped during install and hidden from tab completion. Affected locations:
- `ai-rizz` line 4762: `case "${cett_filename}" in [A-Z]*.md)`
- `ai-rizz` line 4897: `case "${cett_first_char}" in [A-Z])`
- `completion.bash` line 85: `grep -v '^[A-Z]'`

Fix by setting `LC_ALL=C` at the top of both scripts.

### Bug 3: `find -empty -delete` removes target root directory

`ai-rizz` line 4478: `find "${smtd_commands_dir}" -type d -empty -delete` can delete the target directory itself. Add `-mindepth 1`.

## Constraints

- All fixes must be non-breaking and work on both GNU/Linux and BSD/macOS.
- POSIX-compliant solutions preferred (ai-rizz uses `#!/bin/sh`).
