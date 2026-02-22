# Active Context

## Current Task

**skill-support** — Add complete skill support to ai-rizz

## Phase

`REFLECT - COMPLETE`

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

## QA Rework (Step 9)

- `cmd_list()` ruleset tree now correctly expands `skills/` as a magic subdir (like `commands/`) — shows one level of skill dir names indented under the `skills/` entry
- Test `test_ruleset_tree_expands_skills_subdir` tightened: now greps for `skill-one`/`skill-two` without trailing `/` (tree format) rather than checking the whole output
- Trivial fix: `get_commands_target_dir()` docstring first line had "skills" instead of "commands"
- 33/33 tests pass

## QA Rework #2

- `cmd_deinit()` now removes skills dirs alongside commands dirs for all three modes
- 3 new tests added to `test_skill_sync.test.sh`: behaviors 24/25/26 (local/commit/global deinit)
- 36/36 tests pass (29 unit + 7 integration)

## Next Step

Run `/archive` to create the archive document and finalize.
