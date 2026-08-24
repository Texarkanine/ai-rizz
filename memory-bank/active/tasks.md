# Current Task: interactive-prompt-backspace (rework)

**Complexity:** Level 1

## Fix

Dropped `edit_prompt_line`. `read_prompt_line` owns the byte loop, tty `stty`, and `rpl_line`. Unit tests assert `rpl_line` via file redirect (no stdout API, no `$()`).

Newline terminator uses the same `$(printf '\n'; printf x)` sentinel as `dd` — `$(printf '\n')` is empty because command substitution strips trailing newlines. The old stdout helper hid that (`$()` stripped the appended NL).

## Files

- `ai-rizz` — one helper
- `tests/unit/test_prompt_line_edits.test.sh` — `rpl_line` only

## QA (2026-08-24 rework)

**Result:** PASS

- Rework complete: `edit_prompt_line` removed; `read_prompt_line` owns byte loop, tty `stty`, and `rpl_line`
- Unit tests assert `rpl_line` via file redirect; no stdout API, no `$()`
- Newline sentinel fix applied consistently (`rpl_nl` and `dd` reads)
- Four interactive call sites unchanged; integration backspace test still pipes to `cmd_init`
- Advisories (non-blocking): trap restores stty without `exit`; tty echo/stty untested in-suite; integration test still names `epl_bs` locally
