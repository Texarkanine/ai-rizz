# Reflection: Skill Support

**Task ID:** skill-support
**Date:** 2026-02-20
**Complexity:** Level 3

## Summary

Added complete skill support to ai-rizz: `is_skill()` detection, `get_skills_target_dir()` routing, deployment in `copy_entry_to_target()` (standalone and embedded), skills dir clearing in `sync_manifest_to_directory()`, `cmd_list()` display with status glyphs, and `cmd_deinit()` cleanup for all three modes. All 36 tests pass; every requirement from the project brief was implemented.

## Requirements vs Outcome

All requirements delivered as specified:
- `is_skill()`: two-case detection (standalone `rules/<name>`, embedded `rulesets/<r>/skills/<name>`) — complete
- `get_skills_target_dir()`: mode→path mapper — complete
- `copy_entry_to_target()`: standalone skill branch + embedded skills/ subdir walk — complete
- `sync_manifest_to_directory()`: skills dir cleared on sync — complete
- `cmd_list()`: "Available skills:" section with glyph status, `skills/` magic subdir in ruleset tree — complete
- `cmd_deinit()`: removes `.cursor/skills/<mode>/` for local/commit, `GLOBAL_SKILLS_DIR` for global — complete (added in QA rework #2)

One addition not in the original plan: `cmd_add_rule()` was extended to detect skill directories at add-time (`rules/<name>` with `SKILL.md` resolves to skill dir when no extension given). This was necessary for the user-facing `ai-rizz add my-skill` workflow to work correctly.

No requirements were dropped or descoped.

## Plan Accuracy

The plan was structurally accurate: all 10 implementation steps mapped correctly to the actual changes, the file list was correct, and the sequence (stubs → failing tests → implement → regression) worked without reordering.

**What surprised us:**

1. **`cmd_add_rule()` gap not in plan.** The plan assumed rules-path-based detection was handled inside `copy_entry_to_target()`, but the add-time resolution loop (extension inference) didn't know about skills. This required an unplanned modification to `cmd_add_rule()`. It was straightforward once discovered, but preflight missed it.

2. **`cmd_deinit()` gap not in plan.** The plan covered sync clearing but didn't analyze `cmd_deinit()`. Skills dirs were removed from disk during add/sync but `cmd_deinit()` left them behind. This was caught in the first QA pass and required a targeted rework (QA rework #2). The fix was mechanical — 3 `rm -rf` lines and 3 new tests.

3. **`set -e` + `grep` interaction.** The `cmd_list()` skills section uses `grep -v '^$' || true` to avoid aborting when no skills exist. This is a known POSIX shell hazard in this codebase (grep exits 1 on no-match, which `set -e` treats as fatal). The `|| true` workaround is established pattern here; applying it was mechanical.

**Plan accuracy assessment:** High (8/10). The two functional gaps (add-time detection, deinit cleanup) were both O(1)-complexity fixes that added a total of ~15 lines and 6 tests. They reflect plan incompleteness, not design errors.

## Creative Phase Review

No creative phase was executed. The plan noted "No open questions — implementation approach is clear. The `commands/` pattern (magic subdir, flat copy, tree rendering) is established and skills follows it."

This was correct. The `commands/` pattern provided sufficient precedent for every design decision encountered during build. No friction points emerged from the absence of a creative phase.

## Build & QA Observations

**What went smoothly:**
- All 10 planned steps executed in sequence without reordering
- `is_skill()` case-pattern matching was straightforward (two arms before the catch-all)
- `get_skills_target_dir()` was a direct structural copy of `get_commands_target_dir()`
- Embedded skills subdir walk in `copy_entry_to_target()` was 10 lines following the existing pattern

**Where we iterated:**
- `cmd_add_rule()` gap discovered during Step 5 (standalone skill deployment) — fixed inline rather than returning to plan
- `set -e`/grep interaction in `cmd_list()` — fixed during Step 8 build

**QA findings:**
- First QA pass: `cmd_deinit()` missing skills dir cleanup (substantive — required rework)
- First QA pass: `get_commands_target_dir()` docstring first line said "skills" instead of "commands" (trivial — fixed inline)
- First QA pass: `test_ruleset_tree_expands_skills_subdir` test too broad (trivial — tightened grep)
- Second QA pass: `cmd_deinit()` confirmation message (`cd_items_to_remove`) didn't list skills dirs even though they were removed (trivial — fixed inline, 3 string appends)
- Second QA pass: otherwise clean

The first QA failure was legitimate: `cmd_deinit()` is a well-established command with a clear pattern (cleans up everything it owns) and skills was an obvious omission. QA caught it at the right phase.

## Cross-Phase Analysis

**Planning gap → build addition:** The `cmd_add_rule()` gap was not caught by preflight. Preflight validated the plan against the codebase but didn't trace the full user-facing flow ("user types `ai-rizz add my-skill`") to verify every handler. Had the preflight check included a walkthrough of the CLI dispatch path for each entity type, this would have been caught.

**Planning gap → QA failure:** The `cmd_deinit()` gap was not in the plan and not caught by preflight. It surfaced at QA because QA reviewed the entire feature surface ("what else manages the skills directories?"). The pattern of failure: plan focused on the "add/sync" lifecycle and missed the "remove" lifecycle. This is a recurring risk for any feature that touches directory management — deinit is a separate lifecycle that deserves explicit attention in the plan's component analysis.

**Second QA pass (confirmation message):** The `cd_items_to_remove` omission was a true QA-appropriate trivial fix: the `rm -rf` was correct, the confirmation message was wrong. No design decision needed; it was a copy-paste omission. Appropriately caught and fixed in QA without routing back to build.

## Insights

### Technical

- **`cmd_deinit()` requires explicit attention in any feature touching directory management.** It is easy to implement the add/sync lifecycle (create, populate, rebuild) and forget the deinit lifecycle (remove). The pattern is: for every directory your feature creates, `cmd_deinit()` must remove it, AND the confirmation message must list it. Future plan templates for directory-management features should have a checklist item for deinit.

- **The `commands/` magic subdir pattern scales cleanly.** The entire skills feature followed it without friction: same detection logic, same copy approach, same sync clearing, same list display pattern, same deinit cleanup. When a new entity type is added to ai-rizz in the future, the pattern is: (1) detection function, (2) target dir getter, (3) branch in `copy_entry_to_target()`, (4) clear in `sync_manifest_to_directory()`, (5) section in `cmd_list()`, (6) cleanup in `cmd_deinit()`.

- **POSIX `set -e` + `grep` exit-1 is an ambient hazard.** Any new code in this codebase that uses `grep` in a pipeline where no-match is a valid outcome must add `|| true`. This is already established convention but worth keeping in mind for any new `cmd_*` function that searches for optional content.

### Process

- **Plan's component analysis should explicitly include the "remove" lifecycle.** The component analysis in `tasks.md` listed modified functions (copy_entry_to_target, cmd_list, sync_manifest_to_directory) but did not include `cmd_deinit()`. A checklist question in the plan template like "What removes the artifacts this feature creates?" would catch this class of omission before build.

- **Preflight should include a CLI flow trace.** Preflight caught the `is_skill()` case ordering issue but missed the `cmd_add_rule()` gap because it validated the plan structurally, not by tracing user-facing CLI flows. Adding a "trace each new entity type through the CLI dispatch path" step to preflight would catch add-time detection gaps before build.
