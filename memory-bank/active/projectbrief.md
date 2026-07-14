# Project Brief: Creamy Papery Docs Theme

## User Story

As a reader of ai-rizz docs, I want the site chrome to use the same Texarkanine paper/ember Material theme as slobac, so the docs look consistent across Texarkanine projects.

## Use-Case(s)

### Use-Case 1

Port the finalized theme from [slobac PR #27](https://github.com/Texarkanine/slobac/pull/27) / `../slobac` onto ai-rizz’s ProperDocs site.

## Requirements

1. Apply the exact Texarkanine paper/ember docs theme from slobac (cream light `#f6f0e4`, warm charcoal dark `#1c1914`, ember/amber accents).
2. **Copy files exactly where possible** — do not read then re-infer token values or CSS structure; copy source artifacts from `../slobac` (notably `extra.css`) and adapt only path/wiring differences required by ai-rizz layout (`docs/` vs slobac’s docs_dir).
3. Wire theme via `properdocs.yaml`: `primary`/`accent: custom` and `extra_css` pointing at the copied stylesheet.
4. Add the same kind of theme-token contract coverage as slobac (`test_docs_theme_tokens.py` pattern), adapted to ai-rizz’s test layout if needed.
5. Point `memory-bank/techContext.md` Design System (or equivalent) at the docs CSS tokens.

## Constraints

1. Exact visual/token parity with slobac PR #27 — not a reinterpreted palette.
2. Prefer byte-faithful copies of theme artifacts; only rewrite when project paths force it.

## Acceptance Criteria

1. Light and dark Material schemes use `custom` primary/accent and load the copied `extra.css`.
2. Token values match slobac’s `extra.css` exactly.
3. Theme contract tests pass; docs build (`properdocs build --strict` or project equivalent) succeeds.
