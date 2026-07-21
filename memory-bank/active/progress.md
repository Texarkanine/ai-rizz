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
