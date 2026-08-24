# Progress

Fix interactive prompts so Backspace deletes typed characters instead of inserting `^H`, using a POSIX-compliant input helper shared by every tty prompt.

**Complexity:** Level 2

## 2026-08-24 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Validated intent: inventory and fix all interactive prompts that cannot Backspace
    - Recorded POSIX `shell-posix-style` as a hard constraint
    - Classified Level 2
* Decisions made
    - Level 2: same bug at every interactive `read -r` site; fix is one helper plus call-site swap, not architecture
    - File/pipe `read` loops stay out of scope
* Insights
    - Known interactive sites: `cmd_init` source-repo and mode; `cmd_deinit` mode and confirm
    - Symptom `ai^H^H^C` matches cooked-mode `read` when tty erase does not match the Backspace byte

## 2026-08-24 - PLAN - COMPLETE

* Work completed
    - Wrote Level 2 TDD plan: helper unit suite plus one `cmd_init` backspace wiring test
    - Listed the four `read -r` replacements; file/pipe reads stay unchanged
* Decisions made
    - POSIX byte editor (`dd` + `${buf%?}`), not bash readline
    - Treat both `^H` and `^?` as erase
    - Tty: `stty -icanon -echo` and visual echo on `/dev/tty`; pipes skip `stty`
    - Callers assign `rpl_line` in-shell so a `stty` trap can restore the terminal
* Insights
    - Existing `echo "" | cmd_init` / `echo n | cmd_deinit` tests cover the pipe path
    - No user-doc change: CLI contract is unchanged

## 2026-08-24 - PREFLIGHT - PASS WITH ADVISORY

* Work completed
    - Preflight PASS WITH ADVISORY ([preflight](6cf08a40-6733-42a7-a609-99e3514946f8)); plan unchanged
* Decisions made
    - Build will apply advisories: stop `dd` on 0-byte EOF, newline to `/dev/tty` on submit, `stty`/trap only in `read_prompt_line`, prefixed `epl_`/`rpl_` names
    - Radical innovation (single function) not applied
* Insights
    - Pipe regressions already exist for empty init and `n` deinit confirm

## 2026-08-24 - BUILD - COMPLETE

* Work completed
    - Implemented `edit_prompt_line` (BS/DEL/CR/NL/EOF) and `read_prompt_line` (tty `stty` cbreak)
    - Replaced four interactive `read -r` sites
    - `make test` 38/38 suites passed
* Decisions made
    - `read_prompt_line` assigns `rpl_line` only; no stdout reprint
    - Visual echo is inside `edit_prompt_line` when `[ -t 0 ]`
* Insights
    - Piped `echo "" | cmd_init` and `echo n | cmd_deinit` stay green without a pty

## 2026-08-24 - PREFLIGHT - COMPLETE (PASS WITH ADVISORY)

* Work completed
    - Validated the Level 2 plan against `ai-rizz` and the existing init/deinit tests
    - Confirmed TDD order on both executable units; no change-detector strikes or step swaps
    - Wrote `memory-bank/active/.preflight-status` with first line `PASS WITH ADVISORY`
* Decisions made
    - Plan is acceptable as-is; advisories are implementer cautions, not a re-plan
    - Four stdin `read -r` sites is still the complete interactive inventory
* Insights
    - `set -e` plus a `dd` loop needs the planned `$(dd; echo x)` idiom and an EOF stop so Ctrl+D cannot spin
    - Existing pipe tests (`test_init_requires_mode_flag`, `echo "n" | cmd_deinit --local`) are the regression net for non-tty `read` replacement
