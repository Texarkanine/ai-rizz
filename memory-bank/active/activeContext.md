# Active Context

## Current Task: interactive-prompt-backspace
**Phase:** BUILD - READY

## What Was Done
- Plan complete. Preflight PASS WITH ADVISORY.
- Advisories to apply in build: EOF stops `dd` loop; `/dev/tty` newline on submit; `stty`/trap only in `read_prompt_line`; prefixed locals.

## Next Step
- Build step 1: stub `edit_prompt_line` / `read_prompt_line` tests and interface.
