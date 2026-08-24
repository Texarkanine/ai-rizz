# Project Brief

## User Story

As a developer using `ai-rizz` interactively, I want Backspace to delete characters at prompts such as `Mode [local/commit/global]:` so that I can correct typing mistakes without aborting the command.

## Use-Case(s)

### Init Mode Prompt

At `ai-rizz init`, type into `Mode [local/commit/global]:`, press Backspace, and the last typed character is removed instead of `^H` being inserted.

### Other Interactive Prompts

The same editing behavior applies at every other interactive prompt that currently shares this input path (source-repo URL, deinit mode, deinit confirmation).

## Requirements

1. Inventory every interactive prompt that cannot Backspace and fix them.
2. After the fix, typed characters appear and Backspace deletes the previous character.
3. Remain POSIX-compliant per `.cursor/skills/shared/shell-posix-style/SKILL.md` (no bash `read -e`, no arrays, no `local`).

## Constraints

1. POSIX `#!/bin/sh` only — no bash-isms.
2. TDD: tests first; do not invent change-detector tests for prose.
3. Never test `ai-rizz` in the project directory; use the suite or a temp dir.
4. Existing non-interactive / piped `read` of files and command output is out of scope.

## Acceptance Criteria

1. At `ai-rizz init`'s mode prompt, Backspace deletes rather than echoing `^H`.
2. Every other interactive tty prompt in `ai-rizz` has the same editing behavior.
3. Piped or non-tty input still works (scripts, tests, `printf | ai-rizz init ...`).
4. `shellcheck --shell=sh` remains clean for the changed code.
