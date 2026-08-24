# Task: interactive-prompt-backspace

* Task ID: interactive-prompt-backspace
* Complexity: Level 2
* Type: bug fix

At interactive prompts, Backspace inserts `^H` instead of deleting. Inventory is four tty `read -r` sites (`cmd_init` source-repo and mode; `cmd_deinit` mode and confirm). Replace them with one POSIX helper that treats both `^H` (BS) and `^?` (DEL) as erase, and leave file/pipe `read` loops alone.


## Test Plan (TDD)

### Behaviors to Verify

- [Printable then newline]: `printf 'local\n' | edit_prompt_line` → `local`
- [Backspace BS]: `printf 'ai\010\010local\n' | edit_prompt_line` → `local`
- [Backspace DEL]: `printf 'ai\177\177local\n' | edit_prompt_line` → `local`
- [Backspace on empty]: `printf '\010\177x\n' | edit_prompt_line` → `x`
- [Empty line]: `printf '\n' | edit_prompt_line` → empty string
- [CR terminator]: `printf 'yes\r' | edit_prompt_line` → `yes`
- [Non-tty `read_prompt_line`]: same BS input via `read_prompt_line` → `local` in `rpl_line` (no `stty`)
- [Init mode prompt with BS]: `printf 'ai\010\010local\n' | cmd_init <repo> -d <dir>` (no mode flag) → local mode initialized
- [Piped deinit confirm unchanged]: `echo n | cmd_deinit --local` still cancels (existing test remains)

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh` + `source_ai_rizz`
- Test location: `tests/unit/` for the helper; `tests/integration/functions/` for prompt wiring
- Conventions: `test_<description>()` in `test_<feature>.test.sh`; unit suites source `ai-rizz` and call functions
- New test files: `tests/unit/test_prompt_line_edits.test.sh`

## Implementation Plan

### 1. Prompt-line editor — executable — [x]

- Files: `tests/unit/test_prompt_line_edits.test.sh`, `ai-rizz` (Utilities section)

1. Stub tests: add `tests/unit/test_prompt_line_edits.test.sh` with empty `test_edit_prompt_line_*` and `test_read_prompt_line_non_tty_*` cases for the helper behaviors above
2. Stub interface: add `edit_prompt_line` and `read_prompt_line` in `ai-rizz` Utilities with POSIX function headers; empty bodies; `read_prompt_line` documents `rpl_line` as the result (callers must not wrap it in `$()` on a tty so `stty` restore runs in the main shell)
3. Write tests and run red: `printf` pipes of printable / `\010` / `\177` / empty / CR into `edit_prompt_line`; assert stdout. `read_prompt_line` on a pipe asserts `rpl_line`
4. Write code and run green: `edit_prompt_line` reads one byte at a time with `dd bs=1 count=1` (POSIX `$(dd; echo x)` / `%x` so newline is not stripped), appends printables, treats `\010` and `\177` as erase via `${buf%?}`, stops on `\n` or `\r`, writes the line to stdout. `read_prompt_line` calls `edit_prompt_line`, sets `rpl_line` to that line. If `[ -t 0 ]`, save `stty -g`, `stty -icanon -echo min 1 time 0`, echo typed chars and `\b \b` on erase to `/dev/tty`, restore `stty` on return and via `trap` on INT/TERM/EXIT (clear the trap after restore). If not a tty, no `stty` and no visual echo. No bash `read -e`, no `local`, no arrays. `shellcheck --shell=sh` clean on the new functions

### 2. Wire the four prompts — executable — [x]

- Files: `ai-rizz` (`cmd_init`, `cmd_deinit`), `tests/integration/functions/test_initialization.test.sh`

1. Stub tests: add `test_init_mode_prompt_backspace_accepts_local` in `test_initialization.test.sh` (empty)
2. Stub interface: none — `read_prompt_line` already stubbed in step 1
3. Write tests and run red: pipe `printf 'ai\010\010local\n'` into `cmd_init "$TEST_SOURCE_REPO" -d "$TEST_TARGET_DIR"` with no mode flag; assert local mode is active
4. Write code and run green: replace the four interactive `read -r` sites (`ci_source_repo`, `ci_mode`, `cd_mode`, `cd_confirm`) with `read_prompt_line` then assign from `rpl_line`. Keep empty-mode → `local` and confirm `y`/`Y` checks. Existing `echo "" | cmd_init` and `echo n | cmd_deinit` tests stay as pipe regressions

## Technology Validation

No new technology - validation not required

## Dependencies

- POSIX `dd`, `stty` (already assumed by a POSIX desktop/CLI environment)
- Existing shunit2 suite

## Challenges & Mitigations

- [Command substitution + `stty`]: `var=$(read_prompt_line)` runs in a subshell; a SIGINT can leave the tty in cbreak. Mitigation: production callers assign `rpl_line` in the current shell; restore `stty` on the function's normal path and a trap
- [Piped tests / `set -e`]: Replacing `read -r` must not break `echo "" | cmd_init` or exit on empty. Mitigation: helper always returns 0 after a completed line; empty line is a valid result; pipe path skips `stty`
- [Byte vs character]: `LC_ALL=C` means erase deletes one byte. Mitigation: these prompts are ASCII (URL, mode, y/N); do not add UTF-8 grapheme logic
- [`dd` / command-subst newline]: `$(dd)` strips a trailing newline and cannot see Enter. Mitigation: `$(dd bs=1 count=1 2>/dev/null; echo x)` then strip the sentinel `x`

## Pre-Mortem

- [Assumed the bug is "no line editor" when it is only this user's `stty erase`]: Handling both BS and DEL still fixes the reported `^H` case and the opposite mismatch; no scope cut
- [Unit-tested the editor but left prompts on `read -r`]: Step 2 exists so the four sites actually call the helper; the init BS pipe test fails if they do not
- [TTY left raw after Ctrl+C]: already covered by Challenge 1
- [Invented a pty harness that flakes in CI]: rejected — editor is tested on pipes; `stty` is a thin tty-only wrapper around the same editor

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [x] Build
- [ ] QA
