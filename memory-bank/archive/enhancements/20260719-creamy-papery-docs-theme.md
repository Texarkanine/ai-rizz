---
task_id: creamy-papery-docs-theme
complexity_level: 2
date: 2026-07-19
status: completed
---

# TASK ARCHIVE: Creamy Papery Docs Theme

## SUMMARY

Ported the Texarkanine paper/ember Material docs theme from slobac PR #27 onto ai-rizz by byte-copying `extra.css`, wiring `properdocs.yaml` to `custom` primary/accent + `extra_css`, and adding shunit2 token contracts. Strict docs build and full suite (35/35) passed.

## REQUIREMENTS

- Exact paper/ember visual/token parity with slobac (cream light `#f6f0e4`, warm charcoal dark `#1c1914`, ember accents; dark primary `#de8131`).
- Byte-faithful copy of `extra.css`; adapt only path/wiring for ai-rizz (`docs/` docs_dir).
- Wire `properdocs.yaml`: `primary`/`accent: custom`, `extra_css: [stylesheets/extra.css]`.
- Theme-token contract coverage adapted to ai-rizz shunit2 unit layout (no pytest).
- Point `memory-bank/techContext.md` Design System at the docs CSS tokens.

## IMPLEMENTATION

- **`docs/stylesheets/extra.css`:** Copied verbatim from `../slobac/skills/slobac-audit/references/docs/stylesheets/extra.css`.
- **`properdocs.yaml`:** Replaced indigo primary/accent with `custom`; retained light `default` / dark `slate` schemes and brightness toggle; added `extra_css`.
- **`tests/unit/test_docs_theme_tokens.test.sh`:** New shunit2 suite for palette wiring, light/dark tokens, empty-CSS guard, and optional local-only `cmp` against sibling slobac (skipped in CI when sibling absent).
- **`memory-bank/techContext.md`:** Design System subsection pointing at stylesheet + yaml wiring + unit contract path.

## TESTING

- TDD: unit contracts written first (expected red), then CSS copy + yaml wiring (green).
- `VERBOSE_TESTS=true ./tests/unit/test_docs_theme_tokens.test.sh`; `make test-unit`; `make docs-build`; `make test` 35/35.
- `/niko-qa` semantic review: PASS; built site loads `stylesheets/extra.css` with paper/ember tokens. Preflight: PASS WITH ADVISORY (sibling `cmp` must stay local-only).

## LESSONS LEARNED

- Prefer in-repo token asserts as the CI gate; sibling-repo `cmp` is a local convenience, not a pipeline dependency.
- When the operator says “copy exactly,” recover deleted upstream tests from git history for *assertion intent*, but treat the live artifact as the source of truth for values (stale `#f59e0b` vs live `#de8131`).
- For two small docs sites, an identical checked-in `extra.css` plus contract tests is the right weight vs a shared package — nothing more elegant was warranted.

## PROCESS IMPROVEMENTS

None material. Plan sequence held; main adaptation (shell contracts instead of deleted slobac pytest) was anticipated in planning.

## TECHNICAL IMPROVEMENTS

Optional later: a shared stylesheet package or submodule if theme sharing becomes a multi-repo norm. Not warranted for two sites today.

## NEXT STEPS

None.
