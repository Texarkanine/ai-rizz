# Active Context

## Current Task: interactive-prompt-backspace (rework)
**Phase:** COMPLEXITY-ANALYSIS - COMPLETE

## What Was Done
- Rework: drop `edit_prompt_line`. One function, `read_prompt_line` → `rpl_line`.
- Classified Level 1 (single helper, no new behavior).

## Next Step
- Build: retarget unit tests to `rpl_line`, then inline the editor.
