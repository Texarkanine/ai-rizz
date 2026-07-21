# Progress

Replace the `deinit --all` footgun with `deinit --both` (local+commit only), and remove `--all` so project deinit cannot wipe global settings. Per [issue #42](https://github.com/Texarkanine/ai-rizz/issues/42).

**Complexity:** Level 2

## 2026-07-21 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Validated intent against issue #42
    - Classified as Level 2: self-contained enhancement to deinit flag surface
* Decisions made
    - Scope is exactly the two issue bullets: add `--both`, remove `--all` footgun
* Insights
    - Recent #40/#41 work deliberately left `deinit --all` out of scope; this task picks that up

## 2026-07-21 - PLAN - COMPLETE

* Work completed
    - Mapped behaviors to existing deinit function + CLI test suites
    - Linear TDD plan: tests first, then `cmd_deinit` `--both`/`-b`, remove `--all`/`-a`, docs/completion/error text
* Decisions made
    - `--both` removes local+commit only; no single-flag full wipe (use `--both` then `--global`)
    - Short flag `-b` for parity with other mode shorts
    - Interactive prompt and no-mode default use `both` instead of `all`; `AI_RIZZ_MODE=all` no longer accepted
* Insights
    - `cmd_help` never listed `--all` under deinit options; docs and `cmd_deinit` did — docs/completion are the user-visible gaps
