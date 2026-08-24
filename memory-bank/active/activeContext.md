# Active Context

## Current Task: interactive-prompt-backspace
**Phase:** PLAN - COMPLETE

## What Was Done
- Classified Level 2. Operator constraint: POSIX `shell-posix-style` (no bash `read -e`).
- Inventory: four interactive `read -r` sites (`cmd_init` source-repo/mode, `cmd_deinit` mode/confirm).
- Plan: `edit_prompt_line` (byte editor, BS+DEL) + `read_prompt_line` (tty `stty` cbreak + `/dev/tty` echo; pipe skips `stty`). Callers use `rpl_line`, not `$()`.
- Tests: new `tests/unit/test_prompt_line_edits.test.sh`; one init-mode BS case in `test_initialization.test.sh`.

## Next Step
- Preflight validation (spawn `/niko-preflight`).
