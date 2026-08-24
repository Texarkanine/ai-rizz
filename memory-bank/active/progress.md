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
