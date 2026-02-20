# Active Context

## Current Task

**skill-support** — Add complete skill support to ai-rizz

## Phase

`BUILD - COMPLETE (PASS)`

## What Was Done

- Implemented all 10 TDD steps: stubs → failing tests → implementation → full regression pass
- `is_skill()`: case-pattern detection for standalone (`rules/<name>`) and embedded (`rulesets/<r>/skills/<name>`) skill paths
- `get_skills_target_dir()`: mode→path mapper analogous to `get_commands_target_dir()`
- `cmd_add_rule()`: extended to accept skill directories (no-extension name resolves to skill dir check)
- `copy_entry_to_target()`: standalone skill branch + embedded skills/ subdir walk with `cp -rL`
- `sync_manifest_to_directory()`: skills dir cleared on sync alongside commands dir
- `cmd_list()`: "Available skills:" section with glyph status; skills/ magic subdir in ruleset tree
- 3 new test files (25 tests) + fixed 2 bugs (set -e/grep, double-prefix in test)
- 33/33 tests pass (26 unit + 7 integration)

## Decisions

- `cmd_add_rule` was not originally planned to change, but gap discovered: need skill dir detection at add-time
- `grep -v '^$' || true` required to prevent `set -e` from aborting `cmd_list` when no skills exist in repo
- Embedded skill installed status determined by checking parent ruleset in manifest (not by direct manifest entry)

## Next Step

Run `/qa` to begin QA phase.
