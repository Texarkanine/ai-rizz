# Current Task: Fix ruleset command install scope (GitHub #31)

**Complexity:** Level 1

## Build

- [x] Restrict ruleset command `find` to `rulesets/<r>/commands/` in `copy_entry_to_target`.
- [x] Update integration tests and docs that assumed root-level `.md` commands.

## QA

- [x] Semantic review vs project brief; record `.qa-validation-status`.

### QA result

- **PASS** — Implementation matches brief: `copy_entry_to_target` limits `find` to `rulesets/<r>/commands/`; skills subtree unchanged; docs/tests updated; no stray complexity; full `make test` green.
