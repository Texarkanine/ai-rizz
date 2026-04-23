# TASK ARCHIVE: Skill Support

## METADATA

- **Task ID**: skill-support
- **Complexity**: Level 3 (Intermediate Feature)
- **Date Completed**: 2026-02-20
- **Final test count**: 36 (29 unit + 7 integration), all pass

---

## SUMMARY

Added complete **skill** support to ai-rizz so directories containing `SKILL.md` deploy to `.cursor/skills/<mode>/` with the same lifecycle discipline as rules, commands, and rulesets. Two valid definition paths: standalone `rules/<skill-name>/` (manifest entry) and embedded `rulesets/<ruleset>/skills/<skill-name>/` (deployed with the parent ruleset). Implementation followed the established `commands/` pattern (detection, `cp -rL`, sync clearing, `cmd_list` section, ruleset tree magic subdir, `cmd_deinit` cleanup). Unplanned but necessary extensions: `cmd_add_rule()` for add-time resolution of skill dirs, and `cmd_deinit()` + confirmation text for skills dirs in all three modes (local, commit, global).

---

## REQUIREMENTS

### User story (from project brief)

As an ai-rizz user, I want skills to be fully supported so that I can manage AI skill directories (containing `SKILL.md`) through the same `add` / `remove` / `list` / `sync` workflow as rules, commands, and rulesets — with skills deployed to `.cursor/skills/<mode>/`.

### Skill detection (`is_skill`)

- **Valid only**: `rules/<skill-name>/SKILL.md` (standalone, one level under `rules/`) and `rulesets/<ruleset-name>/skills/<skill-name>/SKILL.md` (embedded).
- **Invalid**: `rulesets/skills/<name>`, `rulesets/<name>` as symlink-to-skill at ruleset root, nested paths that break the one-level contract.

### Deployment

- Whole skill dirs copied to `.cursor/skills/<mode>/` via `copy_entry_to_target()`; `cp -rL` to follow symlinks within the skill.
- Standalone: manifest-driven; embedded: walked from `skills/` under each ruleset during ruleset processing.

### List and UX

- `cmd_list`: "Available skills:" with status glyphs (`●` committed, `◐` local, `★` global, `○` uninstalled), trailing `/`, deduplication when the same name appears in both places.
- Ruleset tree: `skills/` as a magic subdir with one level of children (like `commands/`).

### Sync and cleanup

- Skills target dir cleared and rebuilt on sync (analogous to commands).
- `cmd_deinit` removes per-mode skills dirs and `GLOBAL_SKILLS_DIR` for global; confirmation lists what will be removed.

### Constraints

- POSIX shell, TDD, `make test` must pass; no breaking existing tests.

### Process requirements (task tracking)

- Component analysis, TDD test plan, 10-step implementation plan, preflight, build, QA, reflect — all completed.

---

## IMPLEMENTATION

### New and touched surfaces

| Area | What changed |
|------|----------------|
| Globals / init | `GLOBAL_SKILLS_DIR`, initialization in `init_global_paths()`. |
| `is_skill()` | Two-case path detection: `rules/<name>` and `rulesets/<r>/skills/<name>` (correct arm ordering before catch-all `rulesets/*`). |
| `get_skills_target_dir()` | Mode → `.cursor/skills/<mode>/` (and global path), analogous to `get_commands_target_dir()`. |
| `cmd_add_rule()` | Resolves no-extension add targets to a skill directory when `rules/<name>/SKILL.md` exists (gap found during build). |
| `copy_entry_to_target()` | Early branch: standalone skill → copy to skills target; inside ruleset branch: iterate `skills/` subdirs with `SKILL.md`, `cp -rL` each. |
| `sync_manifest_to_directory()` | Clear skills directory before repopulating (with commands). |
| `cmd_list()` | "Available skills:" from filesystem discovery + installed status; embedded skills use parent ruleset manifest membership; `grep -v '^$' \|\| true` for `set -e` when no skills; ruleset tree `skills/` case. |
| `cmd_deinit()` | `rm -rf` skills dirs per mode; confirmation strings list skills dirs (QA rework). |

### Design precedents

- **No separate creative phase** was run: the `commands/` magic-subdir pattern was sufficient for every design choice.
- **Plan gaps fixed in flight**: (1) add-time skill resolution in `cmd_add_rule`, (2) deinit and confirmation for skills — both small, mechanical follow-ups.

### Key files

- `ai-rizz` (main script): detection, copy, sync, list, deinit, globals.
- Tests: `tests/unit/test_skill_detection.test.sh`, `test_skill_sync.test.sh`, `test_skill_list_display.test.sh` (plus existing suite).

---

## TESTING

- **Approach**: TDD — stubs, failing tests, implementation, full `make test`.
- **Coverage**: Skill detection, standalone and embedded deploy, sync clearing, list display, deduplication, ruleset tree, deinit for local/commit/global.
- **Final result**: 36/36 tests pass (29 unit + 7 integration) after QA reworks (deinit tests, confirmation copy).

---

## CREATIVE PHASE

No creative phase was executed. The plan stated there were no open questions; the `commands/` pattern fully determined structure (magic subdir, flat copy, tree rendering, sync clearing). **Friction:** None attributable to skipping creative; two gaps were lifecycle completeness (add / deinit), not ambiguous design.

---

## LESSONS LEARNED (from reflection, inlined)

### Technical

1. **`cmd_deinit()` is mandatory scope for any feature that creates directories** — for each new artifact location, deinit must remove it *and* the confirmation prompt must list it.
2. **The `commands/` pattern scales** — future entity types can follow: detection helper, `get_*_target_dir()`, `copy_entry_to_target` branch, sync clear, `cmd_list` section, `cmd_deinit` cleanup.
3. **POSIX `set -e` + `grep`**: when no-match is valid, use `\|\| true` (established in this codebase).

### Plan accuracy

- Plan was structurally right (10 steps, correct files). **Gaps:** `cmd_add_rule()` not in component analysis; `cmd_deinit()` not in "remove" lifecycle. Both were small fixes (~15 lines + tests combined).

### Process

- **Component analysis** should ask: "What removes the artifacts this feature creates?"
- **Preflight** can add a **CLI flow trace** per entity type (`add` → resolution → copy) to catch add-time gaps.

### QA

- First QA found substantive `cmd_deinit` omission; second pass fixed confirmation text only. Appropriate depth for the phase.

---

## PROCESS IMPROVEMENTS

- Add a checklist item to plan templates for directory-management features: deinit + confirmation.
- Add preflight step: trace each new entity type through CLI dispatch and add path.

## TECHNICAL IMPROVEMENTS

- None required beyond the above discipline; architecture stayed consistent with existing patterns.

## NEXT STEPS

None. Task closed; memory bank cleared for the next work item.

---

## APPENDIX: Phase history (from progress.md)

Condensed: complexity set to Level 3; plan and preflight completed (including a design reset for valid paths only: standalone + `rulesets/<r>/skills/<name>`). Build completed all 10 TDD steps; QA passed with deinit and messaging fixes; reflect completed 2026-02-20.

## APPENDIX: Pinned design (mermaid, from tasks.md)

Skill flow at a glance:

- Standalone: `rules/<name>/` with `SKILL.md` → manifest entry → `copy_entry_to_target` → `.cursor/skills/<mode>/<name>/`.
- Embedded: under `rulesets/<r>/`, walk `skills/<name>/` with `SKILL.md` → same target layout.

`sync_manifest_to_directory` clears the skills target before rebuild; `is_skill()` validates paths for completeness checks elsewhere.

---

*Ephemeral sources inlined: `memory-bank/tasks.md`, `activeContext.md`, `progress.md`, `projectbrief.md`, `reflection/reflection-skill-support.md`.*
