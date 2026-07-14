# Task: Creamy Papery Docs Theme

* Task ID: creamy-papery-docs-theme
* Complexity: Level 2
* Type: simple enhancement

Port the exact Texarkanine paper/ember Material docs theme from slobac PR #27 / `../slobac` onto ai-rizz. Copy `extra.css` byte-for-byte; adapt only path/wiring for ai-rizz (`docs/` docs_dir, shell unit tests, techContext).

## Test Plan (TDD)

### Behaviors to Verify

- [Palette custom]: `properdocs.yaml` has `primary: custom` and `accent: custom` (≥2 each) and no `primary:`/`accent: indigo`
- [Palette toggles]: light `scheme: default` and dark `scheme: slate` retained with brightness toggle icons
- [extra_css wired]: `properdocs.yaml` lists `extra_css:` → `stylesheets/extra.css`
- [Light tokens]: `docs/stylesheets/extra.css` default scheme declares paper tokens (`#f6f0e4` bg, `#1f1a14` fg, `#b45309` primary, `#c2410c` accent, `#ebe4d4` code bg, `#2a241c` footer bg)
- [Dark tokens]: slate scheme declares ember tokens (`#1c1914` bg, `#f0e6d4` fg, `#de8131` primary, `#fb923c` accent/link, `#2a251c` code bg, `#12100c` footer bg)
- [File parity]: `docs/stylesheets/extra.css` is identical to `../slobac/skills/slobac-audit/references/docs/stylesheets/extra.css` (byte-for-byte)
- [Strict build]: `make docs-build` succeeds after theme wiring

### Edge Cases

- [Empty CSS]: stylesheet must exist and be non-empty
- [Partial indigo left]: any remaining `indigo` primary/accent fails the palette contract
- [Stale dark primary]: assert `#de8131` (final approved D), not the deleted slobac test’s stale `#f59e0b`

### Test Infrastructure

- Framework: shunit2 via `tests/common.sh` / `make test-unit`
- Test location: `tests/unit/`
- Conventions: `test_<feature>.test.sh`; `test_<description>()` functions; no pytest in this repo (Python is docs-only)
- New test files: `tests/unit/test_docs_theme_tokens.test.sh`
- Note: slobac’s `test_docs_theme_tokens.py` was removed before merge; recover assertion intent from commit `a7c228a` and adapt to shell + final CSS (`#de8131`). Do **not** introduce pytest.

## Implementation Plan

1. **Failing unit contracts for theme wiring/tokens**
   - Files: `tests/unit/test_docs_theme_tokens.test.sh` (new)
   - Changes: Add shunit2 suite covering Behaviors above (grep/regex against `properdocs.yaml` and `docs/stylesheets/extra.css`; cmp against `../slobac/.../extra.css` when that path exists, else skip-or-assert file presence). Run suite — expect fail (missing CSS / still indigo).

2. **Copy theme stylesheet exactly**
   - Files: `docs/stylesheets/extra.css` (new; create `docs/stylesheets/`)
   - Changes: `cp` from `../slobac/skills/slobac-audit/references/docs/stylesheets/extra.css` — no edits, no re-typed tokens.

3. **Wire Material custom palette + extra_css**
   - Files: `properdocs.yaml`
   - Changes: light/dark `primary`/`accent` → `custom`; add `extra_css: [stylesheets/extra.css]` (same relative key as slobac; resolves under `docs_dir: docs`).

4. **Re-run unit contracts + strict docs build**
   - Files: none (verification)
   - Changes: `VERBOSE_TESTS=true ./tests/unit/test_docs_theme_tokens.test.sh` then `make test-unit`; `make docs-build`.

5. **Document Design System pointer**
   - Files: `memory-bank/techContext.md`
   - Changes: Add Design System subsection pointing at `docs/stylesheets/extra.css` + `properdocs.yaml` custom wiring + unit contract path (mirror slobac techContext intent; ai-rizz paths).

## Technology Validation

No new technology - validation not required. Theme uses existing ProperDocs/Material; contract tests use existing shunit2 unit layout.

## Dependencies

- Local checkout of `../slobac` with final `extra.css` (source of byte-exact copy)
- Existing docs toolchain (`uv` + `properdocs` dependency group)

## Challenges & Mitigations

- [slobac pytest file deleted / stale `#f59e0b`]: Mitigate by copying live `extra.css` and asserting final `#de8131`; shell-adapt contracts from `a7c228a` intent only
- [Byte-copy vs path differences]: Only `extra.css` is copied verbatim; yaml/tests/techContext are path-adapted
- [cmp against sibling repo in CI]: Prefer asserting token values in-repo; optional sibling `cmp` only when `../slobac` exists (local), so CI does not depend on a sibling checkout

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
