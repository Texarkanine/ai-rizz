# Active Context

## Current Task: interactive-prompt-backspace (rework)
**Phase:** BUILD - COMPLETE

## What Was Done
- Collapsed to `read_prompt_line` only. Tests assert `rpl_line`.
- Fixed newline detection (`$(printf '\n')` was empty; old `$()` hid it).
- `make test`: 4/4 unit, 34/34 integration.

## Next Step
- QA.
