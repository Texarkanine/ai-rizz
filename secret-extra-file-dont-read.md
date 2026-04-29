# SLOBAC audit report

- **Scope invoked:** all (Phase-1: `deliverable-fossils`, `naming-lies`)
- **Target suite root:** `tests/` (all `*.test.sh` under `tests/unit` and `tests/integration`; harness `tests/common.sh` and `tests/run_tests.sh` excluded)
- **Audit date:** 2026-04-29

## Summary

Five findings total: three for `deliverable-fossils` and two for `naming-lies`. The deliverable-fossil cases are driven by file headers and section comments that frame suites as numbered bugs or phased work rather than durable product behavior. The naming-lie cases are in `test_ruleset_bug_fixes.test.sh`, where two function names contradict what the bodies assert. No other in-scope smell produced additional findings; there are no unused Phase-1 scopes to report as silent.

## Findings

### 1. `tests/unit/test_ruleset_bug_fixes.test.sh` → `test_commands_copied_recursively` — deliverable-fossils

- **Location:** `unit/test_ruleset_bug_fixes.test.sh` → `test_commands_copied_recursively`
- **Smell:** `deliverable-fossils`
- **Rationale:** The file name (`test_ruleset_bug_fixes`) and header describe “Regression tests for ruleset bug fixes” with enumerated bugs; section comments use `BUG 1`, `BUG 3`, `BUG 4` and “Phase 3” framing. That matches the taxonomy signal for file names and groupings keyed to delivery history rather than product capabilities ([file names mirroring the delivery breakdown](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/); [describe/context groupings keyed to work phases](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/)). This test is the first behavioral case under that scaffold; the same header/section pattern applies to the rest of the file.
- **Prescribed remediation:** Phase A: replace fossil filename with a capability label (e.g. ruleset list and command deploy behavior); rewrite the file header and replace `BUG N` / “Phase 3” section comments with `describe`-equivalent groupings named after behaviors (list tree shape, flat command deploy, mdc visibility). Phase B: if other files overlap these behaviors, emit a short suite TOC (behavior → tests) and regroup/move only after review. Preserve regression-detection power: rename-only string changes first; moves second with identical test count.
- **Why this isn't a false positive:** This is not domain vocabulary (e.g. a product “checklist” feature); “bug fix” and numbered `BUG` blocks are pure work-tracking scaffolding, not terms from the SUT’s user-facing contract.

### 2. `tests/unit/test_ruleset_removal_and_structure.test.sh` → `test_commands_removed_when_ruleset_removed` — deliverable-fossils

- **Location:** `unit/test_ruleset_removal_and_structure.test.sh` → `test_commands_removed_when_ruleset_removed`
- **Smell:** `deliverable-fossils`
- **Rationale:** The file header opens with “Tests for two bug fixes” and numbered symptoms; section banners are `BUG 1` / `BUG 2`. The individual test names are largely behavior-shaped, but the suite is still organized and introduced as historical defects, matching [groupings keyed to work phases rather than product behaviors](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/) and [delivery-breakdown mirroring in headers](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/).
- **Prescribed remediation:** Phase A: drop “two bug fixes” / `BUG N` framing; use section titles that state the invariant (e.g. “ruleset removal clears deployed commands”, “subdirectory file rules preserve paths”). Phase B: optional regroup with other ruleset lifecycle tests after a behavior→tests TOC. Renames only must not change which functions run.
- **Why this isn't a false positive:** These headings document past defect IDs, not a first-class domain concept inside ai-rizz’s CLI surface; they read as sprint residue, not product vocabulary.

### 3. `tests/unit/test_cache_isolation.test.sh` → `test_global_repo_dir_set_when_global_active` — deliverable-fossils

- **Location:** `unit/test_cache_isolation.test.sh` → `test_global_repo_dir_set_when_global_active`
- **Smell:** `deliverable-fossils`
- **Rationale:** The file header cites “Phase 7 bug fixes” and lists implementation bullets—classic [docstrings/comments tying the suite to a phase label](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/) and [work-phase grouping](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/). The cited test is representative; the header frames the whole module’s reason-for-existence as a phase, not “global manifest cache isolation” as the primary story.
- **Prescribed remediation:** Phase A: rewrite the header to state the product guarantees (separate global repo dir from app repo, manifest URL parsing, per-mode repo dirs) without phase numbers; keep test identifiers unchanged unless a name is later found weak. Phase B: none required unless duplicative files exist—then use a TOC before moving tests.
- **Why this isn't a false positive:** “Phase 7” is release/process vocabulary, not a user-visible mode or flag in the application; it does not fall under the “domain term that looks like fossil vocabulary” guard.

### 4. `tests/unit/test_ruleset_bug_fixes.test.sh` → `test_commands_copied_recursively` — naming-lies

- **Location:** `unit/test_ruleset_bug_fixes.test.sh` → `test_commands_copied_recursively`
- **Smell:** `naming-lies`
- **Rationale:** The identifier promises recursive copying; the body and inline comments require **flat** deployment into `.cursor/commands/shared/` (nested source paths, single shared destination). That is a [title/docstring claim that does not match what the assertions prove](https://texarkanine.github.io/slobac/taxonomy/naming-lies/) (weaker/different behavior: flattening, not preserving subdirectory layout in the commands tree).
- **Prescribed remediation:** **Rename** (body is authoritative): choose a name that states flat deployment of nested ruleset command markdown (e.g. nested `.md` under ruleset `commands/` all land in shared commands dir). Do not change assertions unless product intent is genuinely ambiguous after [describe-before-edit](https://texarkanine.github.io/slobac/principles/).
- **Why this isn't a false positive:** This is not cross-language synonymy (“recursive” vs `cp -r`); the test explicitly contradicts recursive **directory preservation** in the destination tree.

### 5. `tests/unit/test_ruleset_bug_fixes.test.sh` → `test_subdirectory_rules_visible_in_list` — naming-lies

- **Location:** `unit/test_ruleset_bug_fixes.test.sh` → `test_subdirectory_rules_visible_in_list`
- **Smell:** `naming-lies`
- **Rationale:** The name asserts subdirectory rules are **visible** in `cmd_list` output; the body requires top-level listing, expects the subdirectory name to appear, and **fails** if `subrule.mdc` appears under that subtree in the listing—i.e. subdirectory rule **files** are not visible in the list. That contradicts the title’s claim, matching [title claims behavior X; body verifies a different display contract](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** **Rename** to match the negative display rule plus positive deploy checks (e.g. list hides nested rule files but deploy still preserves `supporting/subrule.mdc` on disk). The inline comment already states the intended behavior; align the function name with that comment.
- **Why this isn't a false positive:** This is not the taxonomy’s “failure-case test” guard—the title is phrased as a positive visibility claim (`visible`), while the oracle is that nested rule files stay out of the list.

## Tests considered but not flagged

- **`unit/test_command_modes.test.sh` → `test_show_ruleset_commands_error_removed`** — Implementation-focused name, but the body checks exactly that the symbol is absent; no overpromise vs oracle mismatch once “error” is read as the deprecated helper.
- **`unit/test_ruleset_bug_fixes.test.sh` → `test_list_shows_tree_for_all_rulesets`**, **`test_mdc_files_visible_in_list`**, **`test_complex_ruleset_display`** — Names align with grep-based list checks in the body; fossil concern for this file is covered under deliverable-fossils above, not extra naming-lie hits.
- **`unit/test_ruleset_commands.test.sh`** — Inline “BUG CHECK” comments are not the test identifier; function names describe CLI flag parsing behavior.
- **`unit/test_skill_sync.test.sh`** — “BEHAVIOR N” comments enumerate scenarios but public test names read as product outcomes (`test_ruleset_without_skills_subdir_unchanged`, etc.); not strong fossil or lie signal on the identifiers reviewed.
- **Broader sample (`test_cli_*`, `test_envvar_fallbacks`, `test_command_entity_detection`)** — Names map cleanly to assertions (modes, env fallbacks, `is_command` / `get_entity_type`).

## Out-of-scope requests

None. All requested Phase-1 slugs were in scope.
