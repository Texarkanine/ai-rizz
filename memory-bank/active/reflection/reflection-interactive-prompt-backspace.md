---
task_id: interactive-prompt-backspace
date: 2026-08-24
complexity_level: 2
---

# Reflection: interactive-prompt-backspace

## Summary

Interactive prompts now go through a POSIX byte editor that treats BS and DEL as erase. The four `cmd_init` / `cmd_deinit` sites are wired; `make test` and QA passed.

## Requirements vs Outcome

Delivered as asked: inventory was those four prompts, Backspace deletes, POSIX only. Piped/non-tty input still works. No CLI contract or user-doc change. `read_prompt_line` does not reprint to stdout (plan said it might); that avoided a double echo on a tty.

## Plan Accuracy

Sequence and file list were right. The real design wrinkle was that visual echo has to live inside the `dd` loop, so it landed in `edit_prompt_line` when stdin is a tty, not beside `stty` in `read_prompt_line`. Challenges (subshell + `stty`, `set -e` + `dd`, sentinel-x for newline) were the ones that mattered. Preflight's EOF-stop and `/dev/tty` newline advisories were load-bearing; the single-function radical innovation was correctly left unused.

## Build & QA Observations

TDD went red/green on the first try: empty stub, then `Invalid mode: ai^H^Hlocal`, then local mode. QA passed with no rework. Advisories were comment/trap clarity, not defects.

## Insights

### Technical
- Cooked `read -r` is not portable line editing when the tty erase byte is not what Backspace sends. Handling both `^H` and `^?` in-process is the POSIX fix; `stty erase` can only pick one.
- `$(dd bs=1 count=1; printf x)` plus `${byte%x}` is required so Enter is visible and a failed EOF `dd` does not trip `set -e`.

### Process
- Preflight advisories that name a busy-loop or a missing restore are worth applying immediately. "Rewrite it as one function" is optional style and should stay optional.

### Million-Dollar Question

If prompt editing had been assumed from the start, the shape would still be one byte editor, a thin tty `stty` wrapper, and every interactive `read` going through it. That is what shipped. A single `rpl_line`-only function would be a bit smaller, not a different design.
