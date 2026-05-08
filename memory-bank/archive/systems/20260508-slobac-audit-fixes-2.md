---
task_id: slobac-audit-fixes-2
complexity_level: 4
date: 2026-05-08
status: completed
---

# TASK ARCHIVE: SLOBAC audit remediation — slobac-audit-fixes-2

## SUMMARY

Level 4 project **slobac-audit-fixes-2** closed **sixteen** [SLOBAC](https://github.com/Texarkanine/slobac) findings against `tests/` (second-pass audit **2026-05-07**) through three milestones: **M1** remediated per-test smells (**snapshot rows 1–14**), **M2** regrouped skill tests by capability (**row 15**, smell `deliverable-fossils`), and **M3** introduced `tests/integration/functions/` for filesystem/git-heavy suites (**row 16**, smell `wrong-level`). **Production `ai-rizz` code was not modified**; **`make test`** remained green at each milestone boundary.

The **audit snapshot** below replaces any in-repo audit report file: this archive stays readable after that document is removed.

## AUDIT SNAPSHOT (2026-05-07)

Frozen summary of the **second-pass** SLOBAC report used to drive this work. Smell definitions live in the [SLOBAC taxonomy](https://texarkanine.github.io/slobac/) (upstream); rows preserve **finding order** from the original report for traceability.

| # | Smell | What was wrong (concise) |
|---|--------|---------------------------|
| 1 | `conditional-logic` | `test_cli_add_remove` / invalid-repository case asserted only on the failure branch; success path skipped the error contract. |
| 2 | `naming-lies` | `test_init_mode_defaults` claimed mode defaults but did not assert which mode was created. |
| 3 | `vacuous-assertion` | Same test: success exit only—many wrong mode-selection behaviors would pass. |
| 4 | `naming-lies` | Help test claimed “key commands” but passed if any single command string appeared. |
| 5 | `naming-lies` | Deinit “confirmation prompts” test used `-y`, bypassing prompts. |
| 6 | `rotten-green` | Deinit partial-cleanup scenario used `grep … \|\| true`—no failing oracle. |
| 7 | `rotten-green` | “Graceful empty repository” used permissive grep—output contract not asserted. |
| 8 | `naming-lies` | Hook + custom manifest name: asserted hook existence, not custom-manifest behavior. |
| 9 | `naming-lies` | Hook + custom target dir: asserted hook file exists, not custom-target behavior. |
| 10 | `naming-lies` | List “empty commands directory” ended with a tautological assertion—did not verify emptiness. |
| 11 | `naming-lies` | “Prevent downgrade” test name contradicted assertions (behavior was an allowed upgrade). |
| 12 | `rotten-green` | Sync missing-manifest check used `grep … \|\| true`. |
| 13 | `semantic-redundancy` | Command-add clusters duplicated between `test_command_modes` and stronger `test_command_sync`. |
| 14 | `semantic-redundancy` | Ruleset-command clusters duplicated between `test_command_modes` and stronger `test_ruleset_commands`. |
| 15 | `deliverable-fossils` | Skill suites organized by obsolete plan “BEHAVIOR N” numbering, not product capabilities. |
| 16 | `wrong-level` | Many filesystem/git/deployment tests lived under `tests/unit/` despite real I/O and subprocess-style work. |

**Counts:** sixteen findings across seven smell types (`naming-lies` ×7, `rotten-green` ×3, `semantic-redundancy` ×2, plus `conditional-logic`, `vacuous-assertion`, `deliverable-fossils`, `wrong-level` ×1 each).

## REQUIREMENTS

- Honor the **audit snapshot** above as the historical source of truth for what each row targeted; sub-run reflections mapped work back to these rows.
- **Preserve behavior coverage** when tests were renamed, strengthened, deleted as redundant, or moved.
- **Full suite passes:** `make test` exits 0 at every milestone.
- **No production script changes** inside this L4 (test-quality project); real bugs uncovered only as follow-up notes in reflections.
- **Do not introduce new SLOBAC smells** while fixing existing ones.

## MILESTONE LIST

Original plan (from `memory-bank/active/milestones.md` at capstone):

| ID | Scope |
|----|--------|
| **M1** | Remediate per-test smells (**snapshot rows 1–14**): rename/strengthen assertions (`naming-lies` / `vacuous-assertion`), replace `grep ... || true` `rotten-green` patterns, fix `conditional-logic` (row 1), delete weaker `semantic-redundancy` duplicates in `test_command_modes.test.sh` while folding intent into canonical suites (rows 13–14). |
| **M2** | Regroup skill tests by durable product capability (**row 15**, `deliverable-fossils`): three skill-related unit files — capability-oriented section banners instead of obsolete “BEHAVIOR N” plan numbering; no logic changes. |
| **M3** | Reorganize `wrong-level` tests (**row 16**): new tier `tests/integration/functions/` for direct-function tests with real filesystem/git/symlink work; inventory stay vs move; update `tests/common.sh` relative paths, docs (`memory-bank/techContext.md`, `memory-bank/systemPatterns.md`, `.cursor/rules/ai-rizz-development.mdc`, `README.md`), and runner help; preserve fast unit loop. |

**Evolution during execution:** No milestones were added, removed, or materially re-scoped. Execution order remained **M1 → M2 → M3** (with M1 and M2 logically parallelizable but run serially).

## SUB-RUN SUMMARIES

### M1 (Level 3) — snapshot rows 1–14

Delivered remediation in nine test files only: stronger or renamed assertions, removal of permissive `grep ... || true` oracles, subshell-safe invocation where `error()` would abort shunit2, and semantic redundancy trimmed from `test_command_modes.test.sh` while canonical coverage in `test_command_sync.test.sh` / `test_ruleset_commands.test.sh` retained duplicate intent. Environment hardening included clearing clone cache under `${HOME}/.config/ai-rizz/repos` for invalid-repo tests so failures were not masked by cached state; using `parse_manifest_filename_argument` for sourced `cmd_init` manifest basenames; wrapping commands that call `error()` in subshells in unit tests. Plan file mapping per snapshot row was accurate; surprises were tactical (cache, subshells, basename parsing). No creative phase ran. QA passed semantic review vs plan and snapshot; full **`make test`** was the regression gate.

### M2 (Level 2) — row 15 (`deliverable-fossils`)

Reorganized headers and section banners in `test_skill_detection.test.sh`, `test_skill_sync.test.sh`, and `test_skill_list_display.test.sh` to describe product capabilities (detection, deployment, list output, deinit, symlink security, etc.) instead of plan “BEHAVIOR N” numbering. Test logic unchanged; per-file runs gave fast feedback before a final full suite. QA mechanical.

### M3 (Level 3) — row 16 (`wrong-level`)

**Twenty-five** suites moved from `tests/unit/` to `tests/integration/functions/`; **`test_skill_detection.test.sh`** remained the sole file under **`tests/unit/`**. Relative paths to `tests/common.sh` and bundled repo-root `shunit2` were updated (`../../` vs `../../../` from `functions/`). Documentation and `tests/run_tests.sh` help aligned with a three-tier taxonomy; Makefile/`find`-based discovery needed no structural change. `test_skill_sync.test.sh` moved whole per plan allowance (no split). Preflight advisory on documenting `integration/functions/` in runner help was satisfied in build. QA noted pre-existing `# TODO` in two moved files as out of scope. No creative phase.

## IMPLEMENTATION

Work was confined to **`tests/`**, **`memory-bank/`**, **`.cursor/rules/`**, and **`README.md`** as described per milestone. M1 touched invalid-repo, deinit, list, sync, command modes, and related suites. M2 touched three skill test files only. M3 performed inventory-first batch moves and systematic path updates without altering ai-rizz product scripts.

## SYSTEM STATE

After all sub-runs:

- **Per-test quality:** **Rows 1–14** addressed in code comments, assertions, and redundancy consolidation; `rotten-green` and `conditional-logic` patterns reduced.
- **Skill tests:** Three suites use **capability-oriented** section structure (**row 15** / `deliverable-fossils`).
- **Test taxonomy:** **`tests/unit/`** holds fast, isolated helper-focused suites (currently effectively one primary skill-detection suite as documented); **`tests/integration/`** includes top-level integration suites plus **`tests/integration/functions/`** for filesystem/git-heavy direct-function tests (**row 16** / `wrong-level`). Docs and rules describe unit vs integration vs functions-tier conventions and example paths.

End-to-end: contributors run **`make test`** (full coverage) and **`make test-unit`** for a narrower loop per existing Makefile behavior.

## TESTING

Each sub-run ended with **`make test`** passing. M3 verification cited **1 unit + 32 integration** suites after relocation. QA phases (`/niko-qa` workflow) recorded **PASS** for each milestone where applicable.

## CROSS-RUN INSIGHTS

- **Shared testing pitfalls:** Invalid-repo scenarios require awareness of **clone cache** under `${HOME}/.config/ai-rizz/repos`. **`error()`** in sourced command paths needs **subshell isolation** for shunit2-based unit tests.
- **Redundancy deletes:** A written **removed test → canonical test** matrix (optional preflight advisory in M1) would speed future audits; **`make test`** proves behavior but not name-level traceability.
- **Nested tiers:** Any new directory under `tests/integration/` that sources `common.sh` and repo-root **shunit2** needs one extra **`../`** segment vs top-level integration suites — grep-worthy when adding tiers (M3).
- **Inventory-before-move:** Explicit **25 move / 1 stay** style tables (M3) made final layout auditable against **row 16** (`wrong-level`).
- **Process:** M2 showed that **one suite run per file** during comment edits minimizes iteration cost before a full suite.

## LESSONS LEARNED

- L4 decomposition (smells → naming → structure) matched snapshot row groupings and kept each sub-run classifiable as L2/L3.
- Test-only constraints forced honest fixes (cache, subshells) instead of patching product code inside this project.

## PROCESS IMPROVEMENTS

- Consider adopting **capability-first section templates** for new skill tests so **`deliverable-fossils`** / plan-numbered section cleanups are unnecessary later (per M2 reflection).

## TECHNICAL IMPROVEMENTS

- Optional follow-up: address legacy **`# TODO`** called out in QA in two moved function-tier files (pre-existing, out of M3 scope).

## NEXT STEPS

None required for this archived task. Optional: file separate issues for any production bugs explicitly deferred under L4 rules (none were committed as fixes here).
