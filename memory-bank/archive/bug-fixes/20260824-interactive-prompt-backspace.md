---
task_id: interactive-prompt-backspace
complexity_level: 2
date: 2026-08-24
status: completed
---

# TASK ARCHIVE: interactive prompt backspace

## SUMMARY

Interactive `cmd_init` / `cmd_deinit` prompts no longer use cooked `read -r`. They go through POSIX `read_prompt_line`, which treats BS (`^H`) and DEL (`^?`) as erase. On a tty: cbreak, echo to `/dev/tty`, restore `stty`. Callers assign `rpl_line` in the current shell. File and pipe `read -r` loops are unchanged. Draft PR [#52](https://github.com/Texarkanine/ai-rizz/pull/52).

A first cut split a stdout `edit_prompt_line` “for testability.” Tests never used it; rework collapsed to one function. That also fixed newline detection (`$(printf '\n')` is empty).

## REQUIREMENTS

- Backspace deletes at `ai-rizz init` mode prompt (and the other interactive prompts on the same path).
- POSIX only: no bash `read -e`, arrays, or `local`.
- Piped / non-tty input still works.
- `shellcheck --shell=sh` clean on the changed code.
- Rework: no extra API written only to make tests easier.

## IMPLEMENTATION

- **[`ai-rizz`](https://github.com/Texarkanine/ai-rizz/blob/cli-entry/ai-rizz) `read_prompt_line`:** Byte loop (`dd bs=1 count=1` + `$(…; printf x)` / `%x`). Append other bytes; BS/DEL erase via `${rpl_line%?}`. Stop on NL/CR/0-byte EOF. Tty: `stty -icanon -echo`, echo/`\b \b` on `/dev/tty`, trap restores `stty`. Four sites: init source-repo and mode; deinit mode and confirm.
- **Persistent bank:** `systemPatterns.md` — interactive stdin prompts use `read_prompt_line`, not cooked `read -r`.

## TESTING

- Unit: `tests/unit/test_prompt_line_edits.test.sh` — `rpl_line` via file redirect (printable, BS, DEL, erase on empty, empty line, CR).
- Integration: `test_init_mode_prompt_backspace_accepts_local` pipes `ai<BS><BS>local`.
- Existing `echo "" | cmd_init` and `echo n | cmd_deinit` remain pipe regressions.
- `make test`: 4/4 unit, 34/34 integration after collapse.
- QA PASS (original and rework). Tty visual echo/`stty` untested in-suite (pre-mortem rejected a pty harness).

## LESSONS LEARNED

Inlined from ephemeral reflection, plus rework:

- Cooked `read -r` is not portable when tty erase ≠ Backspace. Handle both `^H` and `^?` in-process; `stty erase` can only pick one.
- `$(dd bs=1 count=1; printf x)` plus `${byte%x}` is required so Enter is visible and a failed EOF `dd` does not trip `set -e`.
- `$(printf '\n')` is empty. The old `rpl_line=$(edit_prompt_line)` stripped an accidentally appended NL and hid a broken terminator. Do not wrap the helper in `$()`.
- A stdout editor that tests never call is not a testability design. Assert `rpl_line` from a file redirect.
- Preflight advisories that name a busy-loop or a missing restore are worth applying immediately. “Rewrite it as one function” was optional style until the operator made it a rework.

## PROCESS IMPROVEMENTS

- Do not add a second function so `$()` tests look nicer. If the production API is a global, test that global.
- L1 rework after L2 reflect is the right size for collapsing unused scaffolding; do not re-plan the original feature.

## TECHNICAL IMPROVEMENTS

None required for ai-rizz. SumMem nits found on the accidental vendor copy were filed upstream: [Texarkanine/SumMem#38](https://github.com/Texarkanine/SumMem/issues/38) (`tomllib` vs `require_python`), [#40](https://github.com/Texarkanine/SumMem/issues/40) (`named_ids` exception tuple), [#39](https://github.com/Texarkanine/SumMem/issues/39) (unused `equal_grain_pair`).

## NEXT STEPS

Merge [PR #52](https://github.com/Texarkanine/ai-rizz/pull/52) when ready. Do not land `memory-bank/active/` (cleared by this archive). SumMem-on-this-branch is still out of scope for the prompt fix.
