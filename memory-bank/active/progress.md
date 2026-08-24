# Progress

Fix interactive prompts so Backspace deletes typed characters instead of inserting `^H`, using a POSIX-compliant input helper shared by every tty prompt.

**Complexity:** Level 1

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

## 2026-08-24 - QA - PASS

* Work completed
    - QA PASS ([qa](0bf6e0b0-5bce-413d-8eab-310e7b1a1f54)); implementation accepted
    - Wrote `memory-bank/active/.qa-validation-status`
* Decisions made
    - Advisories (trap without `exit`, header “printable” vs any byte, cbreak Ctrl+D) do not block
    - Ctrl+C: dash and bash 5 exit 130 after the `stty` trap on process-group SIGINT, so empty-mode → local does not run
* Insights
    - No interactive `read -r` remains in `cmd_init` / `cmd_deinit`
    - Tty visual echo and `stty` remain untested in-suite (pre-mortem rejected a pty harness)

## 2026-08-24 - REFLECT - COMPLETE

* Work completed
    - Wrote `memory-bank/active/reflection/reflection-interactive-prompt-backspace.md`
    - Reconciled persistent files: `systemPatterns.md` gained the interactive-prompt contract
* Decisions made
    - productContext and techContext unchanged
* Insights
    - Cooked `read -r` is not portable when tty erase ≠ Backspace; handle both `^H` and `^?` in-process

## 2026-08-24 - REWORK INITIATED

* Work completed
    - Operator requested rework after Reflect: collapse the unused `edit_prompt_line` stdout API
* Decisions made
    - Apply preflight's radical innovation: one function, `read_prompt_line`, result in `rpl_line`
* Insights
    - `edit_prompt_line` existed to make the editor testable via stdout; unit tests of `read_prompt_line` already cover that path, so the extra API was unused scaffolding

## 2026-08-24 - COMPLEXITY-ANALYSIS (rework) - COMPLETE

* Work completed
    - Classified the rework as Level 1: one helper, no new user behavior
* Decisions made
    - L1: skip plan/preflight/reflect; build then QA
    - Tests assert `rpl_line` via file redirect; do not keep a stdout API for `$()`
* Insights
    - Original work stays L2 in the history above; this rework is L1

## 2026-08-24 - BUILD (rework) - COMPLETE

* Work completed
    - Removed `edit_prompt_line`; `read_prompt_line` is the only helper
    - Unit tests assert `rpl_line` via file redirect
    - `make test` 4/4 unit, 34/34 integration
* Decisions made
    - No stdout editor API; no `$()` around the helper
    - Newline byte via `$(printf '\n'; printf x)` / `%x` — same sentinel as `dd`
* Insights
    - `$(printf '\n')` is empty; the old `rpl_line=$(edit_prompt_line)` stripped an accidentally appended NL and hid the bug

## 2026-08-24 - QA (rework) - PASS

* Work completed
    - QA PASS ([qa](f0a664f4-0e51-47d4-82f6-d09ca240671c))
    - Renamed leftover `epl_bs` in the init backspace test
* Decisions made
    - Advisories (trap without `exit`, tty untested) inherited, not blocking
* Insights
    - `systemPatterns.md` already names `read_prompt_line` only; no persistent-file edit


## 2026-08-24 - QA (rework) - PASS

* Work completed
    - QA PASS on rework: single `read_prompt_line`, tests on `rpl_line`, newline sentinel fix
    - Wrote `memory-bank/active/.qa-validation-status`
* Decisions made
    - Advisories from original QA (trap without exit, tty untested, stale `epl_bs` test var name) do not block
* Insights
    - Collapsing removed ~15 lines and eliminated the hidden newline bug from `$()` around the editor

