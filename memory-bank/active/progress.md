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
