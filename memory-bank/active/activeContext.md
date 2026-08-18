# Active Context

## Current Task: list-installed-default
**Phase:** PLAN - COMPLETE

## What Was Done

- Level 2 plan written: default `cmd_list` is inventory; `-a`/`--all` is today's catalog; one footer `N available, not shown`; omit section headers with no installed members.
- Footer `N` is the count of omitted top-level glyph-bearing rows, oracle'd from `○` rows in `--all` output (not ruleset tree children).
- Section titles stay `Available X:` (header rename out of scope).
- Tests live in existing list suites; catalog/`○` assertions retarget to `--all` before implementation.

## Next Step

- Preflight validation (subagent).
