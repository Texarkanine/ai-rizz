# SLOBAC audit report

- **Scope invoked:** deliverable-fossils, naming-lies
- **Target suite root:** tests/
- **Audit date:** 2026-04-29

## Summary

5 findings across 34 test files (26 unit, 8 integration): 3 `deliverable-fossils` and 2 `naming-lies`. All findings are concentrated in two unit test files (`test_ruleset_bug_fixes.test.sh` and `test_command_modes.test.sh`), plus related section-header fossils in `test_ruleset_removal_and_structure.test.sh`. The remaining 31 test files are clean for both in-scope smells.

## Findings

### 1. `tests/unit/test_ruleset_bug_fixes.test.sh` (file-level) — deliverable-fossils

- **Location:** tests/unit/test_ruleset_bug_fixes.test.sh → file name and section headers
- **Smell:** `deliverable-fossils`
- **Rationale:** The file is named `test_ruleset_bug_fixes` and organized into sections keyed to bug-tracker numbers — `BUG 1`, `BUG 3`, `BUG 4` — rather than product capabilities. The file header reads *"Regression tests for ruleset bug fixes"* and *"Tests for 4 bugs in commands subdirectory implementation"*. A comment inside `test_list_shows_tree_for_all_rulesets` reads *"Currently: FAILS"*, an artifact of the TDD sprint that created it. Six months from now, "Bug 3" means nothing to a new contributor. Matched signal: *file names mirroring the delivery breakdown* and *`describe` / `context` groupings keyed to work phases rather than product behaviors*. See [deliverable-fossils](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/).
- **Prescribed remediation:** Phase A — rename the file to `test_ruleset_list_display.test.sh` (the tests verify tree display, .mdc visibility, and commands expansion). Replace the `BUG N` section headers with behavior-anchored groupings like `COMMANDS FLAT COPY`, `RULESET TREE DISPLAY`, `.MDC FILE VISIBILITY`. Remove the "Currently: FAILS" comments. Phase B — consolidate these tests with the overlapping display tests already in `test_list_display.test.sh` and `test_ruleset_removal_and_structure.test.sh`.
- **Why this isn't a false positive:** "Bug 1/3/4" is work vocabulary — it appears only in the test file's organization, not in the SUT. The product has no concept of "bug 3"; the behaviors are "tree display shows all rulesets" and ".mdc files appear in list output."

### 2. `tests/unit/test_ruleset_removal_and_structure.test.sh` (section headers) — deliverable-fossils

- **Location:** tests/unit/test_ruleset_removal_and_structure.test.sh → section headers and file header
- **Smell:** `deliverable-fossils`
- **Rationale:** The file header reads *"Tests for two bug fixes"* and sections are titled `BUG 1: COMMANDS NOT REMOVED WHEN RULESET REMOVED` and `BUG 2: FILE RULES IN SUBDIRECTORIES FLATTENED`. A comment inside `test_file_rules_in_subdirectories_preserve_structure` reads *"# CURRENTLY FAILS: Rules are flattened to root level"* — a development-phase artifact that persisted after the fix landed. The organization is by bug-tracker item rather than product capability. Matched signal: *`describe` / `context` groupings keyed to work phases*; *comments citing design-doc section numbers or AC identifiers*. See [deliverable-fossils](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/).
- **Prescribed remediation:** Phase A — rename the section headers to behavior-anchored names: `COMMAND LIFECYCLE ON RULESET REMOVAL` and `DIRECTORY STRUCTURE PRESERVATION FOR FILE RULES`. Remove the "CURRENTLY FAILS" comment. The test *names* inside (`test_commands_removed_when_ruleset_removed`, `test_file_rules_in_subdirectories_preserve_structure`) are already behavior-focused and need no change.
- **Why this isn't a false positive:** "Bug 1" and "Bug 2" are work vocabulary — the product's behavior is "commands are cleaned up when their ruleset is removed" and "file rules in subdirectories preserve directory structure." The bug numbers add no information about what the tests protect.

### 3. `tests/unit/test_command_modes.test.sh` → `test_show_ruleset_commands_error_removed` — deliverable-fossils

- **Location:** tests/unit/test_command_modes.test.sh → `test_show_ruleset_commands_error_removed`
- **Smell:** `deliverable-fossils`
- **Rationale:** This test verifies that an internal function (`show_ruleset_commands_error`) no longer exists: `if type show_ruleset_commands_error >/dev/null 2>&1; then fail "...should be removed"; fi`. The test's reason-for-existence is a refactoring event (a restriction on local-mode rulesets was removed), not a product guarantee. The other tests in the same file (`test_ruleset_with_commands_can_be_added_local`, etc.) already prove the restriction is gone by exercising the real behavior. This test adds no regression-detection power beyond what those tests provide. Matched signal: *test names that are verbs in the imperative tense against the developer* — it checks that someone cleaned up dead code, not that the product works correctly. See [deliverable-fossils](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/).
- **Prescribed remediation:** Phase A — delete this test. Its regression-detection power is already fully covered by `test_ruleset_with_commands_can_be_added_local`, `test_ruleset_with_commands_can_be_added_commit`, and `test_ruleset_with_commands_can_be_added_global`, which exercise the real behavior. If the function were accidentally re-introduced, those tests would fail first. Deletion is safe under the preservation gate because the mutation kill-set is unchanged.
- **Why this isn't a false positive:** The word "removed" here is not about a product removal operation — it describes a code-cleanup event. The test body does not exercise any product behavior; it inspects the implementation's function namespace. This is a refactor-verification test, not a behavior test.

### 4. `tests/unit/test_ruleset_bug_fixes.test.sh` → `test_commands_copied_recursively` — naming-lies

- **Location:** tests/unit/test_ruleset_bug_fixes.test.sh → `test_commands_copied_recursively`
- **Smell:** `naming-lies`
- **Rationale:** The title claims *"commands copied recursively"*, which implies directory-structure-preserving recursive copy. The body verifies the opposite — that commands from nested directories are copied **flat** to the target, with no directory structure preserved. The assertions explicitly state: `fail "Nested command should be copied (FLAT, not in subdir)"` and `assertEquals "Nested command content should match" "nested command content" "$(cat ".cursor/commands/shared/nested.md")"` (checking the file at the flat path, not a nested path). A reader trusting the name would expect the test to prove recursive directory copying; the body proves flat aggregation. Matched signal: *title-nouns with zero surface in the assertion set* — "recursively" does not appear in any assertion; "FLAT" dominates the assertion comments. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Rename — the body is correct and tests the real product behavior. Proposed name: `test_commands_from_nested_dirs_copied_flat`. The call graph is unchanged (rename-only).
- **Why this isn't a false positive:** This is not cross-language synonymy — "recursively" and "flat" are antonyms in the context of file copying. The title actively misleads about the direction of the assertion.

### 5. `tests/unit/test_ruleset_bug_fixes.test.sh` → `test_subdirectory_rules_visible_in_list` — naming-lies

- **Location:** tests/unit/test_ruleset_bug_fixes.test.sh → `test_subdirectory_rules_visible_in_list`
- **Smell:** `naming-lies`
- **Rationale:** The title claims *"subdirectory rules visible in list"*, promising that rules inside subdirectories appear in the list output. The body verifies the opposite — that subdirectory **contents** are NOT visible, and only the subdirectory name is shown. The key assertion is: `if echo "$output" | grep -A 10 "test-subdir" | grep -A 5 "supporting" | grep -q "subrule.mdc"; then fail "Subdirectory rule should NOT appear in list (subdir contents are not shown)"; fi`. The title says "visible"; the assertion says "should NOT appear." A reader trusting the title would expect the test to prove that subdirectory rules are displayed, but the test actually proves they are hidden. Matched signal: *title says "visible" but body asserts "NOT appear"* — the title-noun "visible" has inverse surface in the assertion set. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Rename — the body is correct and tests the real product behavior. Proposed name: `test_list_shows_subdirs_as_entries_but_hides_their_contents`. The call graph is unchanged (rename-only).
- **Why this isn't a false positive:** This is not under-specification — the title actively claims the opposite of what the body verifies. "Visible" and "should NOT appear" are contradictory, not merely imprecise.

## Tests considered but not flagged

- `tests/unit/test_ruleset_commands.test.sh` → `test_sync_cleans_old_ruleset_command_subdirs`, `test_sync_cleans_old_flat_standalone_commands`, `test_sync_cleans_old_flat_commands_from_ruleset` — The word "old" appears in these titles, which is fossil-adjacent, but "old" here is **domain vocabulary**: the product has a migration feature that explicitly handles old directory layouts. "Old" appears in the SUT's behavior (cleaning up legacy structures), not just in the test name. Cleared under the false-positive guard for domain vocabulary that appears in the SUT.

- `tests/unit/test_hook_based_local_mode.test.sh` → `test_hook_based_ignore_flag_is_noop` — "noop" and "backwards compat" are fossil-adjacent but describe the product's deliberate behavior: the flag is accepted for backwards compatibility and does nothing. This is the behavior under test, not a delivery artifact.

- `tests/unit/test_cache_isolation.test.sh` (file header) — Header comment references "Phase 7 bug fixes," which is fossil vocabulary. However, this appears only in the file-level comment, not in test names or section headers. The test names themselves (`test_global_repo_dir_set_when_global_active`, `test_get_global_source_repo_extracts_url`, etc.) are all behavior-focused. The fossil is cosmetic (a comment) rather than structural (organization or naming), so it does not meet the signal threshold.

- `tests/unit/test_initialization.test.sh` → Tests with `# TODO: Update` comments — Multiple tests contain TODO comments referencing implementation changes (e.g., "TODO: Update assertions - hook-based is now default"). These are development-phase artifacts in comments, but the test **names** and **organization** are behavior-focused. In-code TODOs are not a `deliverable-fossils` signal (the smell is about names and groupings, not code comments).

- `tests/unit/test_list_display.test.sh` → `test_list_handles_empty_commands_directory` — The assertion `assertTrue "commands/ should be shown" true` is always-true and vacuous, which makes this test smell-adjacent for `naming-lies` (title claims "handles" but body doesn't meaningfully verify). However, the root issue is a vacuous assertion, not a title/body semantic mismatch — the title is under-specified rather than lying. `vacuous-assertion` is not in Phase-1 scope.

- `tests/unit/test_command_modes.test.sh` → `test_ruleset_with_commands_can_be_added_local`, `test_ruleset_with_commands_can_be_added_commit`, `test_ruleset_with_commands_can_be_added_global` — The section header "RESTRICTION REMOVAL VERIFICATION" is fossil-adjacent (references the removal of a past restriction). However, the test names themselves are behavior-focused ("can be added"), and the section groups tests by the product capability they verify (adding rulesets with commands to each mode). The section header could be improved but does not rise to the level of a fossil — the organization is by product capability, not by work item.

## Out-of-scope requests

No out-of-scope smell slugs were requested. All requested slugs (`deliverable-fossils`, `naming-lies`) are in Phase-1 scope and were audited.
