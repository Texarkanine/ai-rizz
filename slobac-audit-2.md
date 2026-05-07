# SLOBAC audit report

- **Scope invoked:** `all` (full supported taxonomy: 15 smell slugs)
- **Target suite root:** `tests/`
- **Audit date:** 2026-05-07

## Summary

This audit examined **33** shell test files under `tests/` (~379 `test_*()` functions, ~389k characters total). **Sixteen** findings were recorded across seven smell types: **naming-lies** (7), **rotten-green** (3), **semantic-redundancy** (2), **conditional-logic** (1), **vacuous-assertion** (1), **deliverable-fossils** (1), and **wrong-level** (1). Orchestration used **one** batch assessor because the suite fits the requested **1M context window** budget; the cross-suite assessor **ran**; behavior-summary richness was **`full`**.

No findings for scope `tautology-theatre`.
No findings for scope `presentation-coupled`.
No findings for scope `monolithic-test-file`.
No findings for scope `implementation-coupled`.
No findings for scope `mystery-guest`.
No findings for scope `pseudo-tested`.
No findings for scope `shared-state`.
No findings for scope `over-specified-mock`.

## Findings

### 1. `integration/test_cli_add_remove.test.sh` → `test_add_rule_with_invalid_repository` — `conditional-logic`

- **Location:** `integration/test_cli_add_remove.test.sh` → `test_add_rule_with_invalid_repository`
- **Smell:** `conditional-logic`
- **Rationale:** The test claims invalid repository handling should fail gracefully, but the assertion is inside `if [ $exit_code -ne 0 ]`; if the command succeeds unexpectedly, the test can pass without checking the error contract. This matches the canonical signal for conditional assertion paths with an unasserted alternate. See [conditional-logic](https://texarkanine.github.io/slobac/taxonomy/conditional-logic/).
- **Prescribed remediation:** Assert the expected failure or graceful-success contract unconditionally, then assert output/state for that contract.
- **Why this isn't a false positive:** This is not a symmetric parameterized branch; only the failure branch asserts the claimed behavior.

### 2. `integration/test_cli_init.test.sh` → `test_init_mode_defaults` — `naming-lies`

- **Location:** `integration/test_cli_init.test.sh` → `test_init_mode_defaults`
- **Smell:** `naming-lies`
- **Rationale:** The name/comment claims mode defaults are verified, but the body only pipes `commit` into `init` and asserts exit status 0. It never checks which mode was created. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Either rename the test to describe accepting prompted mode input, or assert the resulting manifest/directory mode.
- **Why this isn't a false positive:** This is not an under-specified title; “mode defaults” is a specific behavior absent from the assertions.

### 3. `integration/test_cli_init.test.sh` → `test_init_mode_defaults` — `vacuous-assertion`

- **Location:** `integration/test_cli_init.test.sh` → `test_init_mode_defaults`
- **Smell:** `vacuous-assertion`
- **Rationale:** The only oracle is successful exit, which many wrong implementations of mode selection/defaulting would satisfy. This matches the canonical signal where the SUT runs and the assertion fires, but interesting wrong answers still pass. See [vacuous-assertion](https://texarkanine.github.io/slobac/taxonomy/vacuous-assertion/).
- **Prescribed remediation:** Strengthen the assertion to check the created manifest name, target directory, and selected mode.
- **Why this isn't a false positive:** This is not a side-effect absence contract; the claimed contract has concrete side effects.

### 4. `integration/test_help_and_usage.test.sh` → `test_help_mentions_key_commands` — `naming-lies`

- **Location:** `integration/test_help_and_usage.test.sh` → `test_help_mentions_key_commands`
- **Smell:** `naming-lies`
- **Rationale:** The test claims help mentions key commands, but it passes when any one of `init|add|remove|list|sync|deinit` appears. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Assert each required command, or rename to describe mentioning at least one command.
- **Why this isn't a false positive:** “Key commands” is not merely terse; the body verifies a weaker, different claim.

### 5. `unit/test_deinit_modes.test.sh` → `test_deinit_confirmation_prompts` — `naming-lies`

- **Location:** `unit/test_deinit_modes.test.sh` → `test_deinit_confirmation_prompts`
- **Smell:** `naming-lies`
- **Rationale:** The name claims confirmation prompts are tested, but the body runs `cmd_deinit --all -y`, explicitly bypassing prompts, and only asserts cleanup. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Feed interactive input without `-y` and assert prompt text, or rename to match yes-flag cleanup behavior.
- **Why this isn't a false positive:** This is not synonymy; the flag suppresses the behavior named by the test.

### 6. `unit/test_deinit_modes.test.sh` → `test_deinit_partial_cleanup_on_error` — `rotten-green`

- **Location:** `unit/test_deinit_modes.test.sh` → `test_deinit_partial_cleanup_on_error`
- **Smell:** `rotten-green`
- **Rationale:** The only failure/error check is `grep ... || true`, followed by permission restoration; no assertion can fail if cleanup/error handling is broken. See [rotten-green](https://texarkanine.github.io/slobac/taxonomy/rotten-green/).
- **Prescribed remediation:** Assert the expected exit status and post-error state, or mark the scenario pending with a reason.
- **Why this isn't a false positive:** This is not an explicit pending marker; it reports green while verifying no outcome.

### 7. `unit/test_error_handling.test.sh` → `test_graceful_empty_repository` — `rotten-green`

- **Location:** `unit/test_error_handling.test.sh` → `test_graceful_empty_repository`
- **Smell:** `rotten-green`
- **Rationale:** The final output check is `grep ... || true`, so the test passes regardless of `cmd_list` output after initializing an empty repo. See [rotten-green](https://texarkanine.github.io/slobac/taxonomy/rotten-green/).
- **Prescribed remediation:** Assert a concrete empty-state output or explicit successful empty listing behavior.
- **Why this isn't a false positive:** The permissive `|| true` is not a runner skip; it silently disables the oracle.

### 8. `unit/test_hook_based_local_mode.test.sh` → `test_hook_works_with_custom_manifest_name` — `naming-lies`

- **Location:** `unit/test_hook_based_local_mode.test.sh` → `test_hook_works_with_custom_manifest_name`
- **Smell:** `naming-lies`
- **Rationale:** The name/comment claims the hook works with a custom manifest name, but the body only checks hook existence and never runs the hook or verifies it finds the custom manifest. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Stage local files under the custom manifest scenario, run the hook, and assert they are unstaged.
- **Why this isn't a false positive:** This is not an under-specified title; “works with custom manifest name” is a stronger behavior than existence.

### 9. `unit/test_hook_based_local_mode.test.sh` → `test_hook_works_with_custom_target_directory` — `naming-lies`

- **Location:** `unit/test_hook_based_local_mode.test.sh` → `test_hook_works_with_custom_target_directory`
- **Smell:** `naming-lies`
- **Rationale:** The name/comment claims the hook uses a custom target directory, but the body only asserts the hook file exists. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Stage files in the custom local target, run the hook, and assert they are unstaged.
- **Why this isn't a false positive:** The body verifies setup, not the custom-target behavior in the title.

### 10. `unit/test_list_display.test.sh` → `test_list_handles_empty_commands_directory` — `naming-lies`

- **Location:** `unit/test_list_display.test.sh` → `test_list_handles_empty_commands_directory`
- **Smell:** `naming-lies`
- **Rationale:** The test claims empty commands directory handling, but after checking that `commands` appears it ends with `assertTrue ... true`; it never verifies absence of child files. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Assert the relevant tree slice contains `commands` and excludes command file entries.
- **Why this isn't a false positive:** The title is specific; the final tautological assertion does not encode the empty-directory contract.

### 11. `unit/test_ruleset_management.test.sh` → `test_prevent_downgrade_from_local_ruleset` — `naming-lies`

- **Location:** `unit/test_ruleset_management.test.sh` → `test_prevent_downgrade_from_local_ruleset`
- **Smell:** `naming-lies`
- **Rationale:** The name says downgrade is prevented, but the comments and assertions verify the opposite: local ruleset to committed individual rule is allowed as an upgrade. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Rename to `test_allow_rule_upgrade_from_local_ruleset_to_commit`, or change the body to test an actual blocked downgrade.
- **Why this isn't a false positive:** This is not domain synonymy; “prevent” and “should succeed” are contradictory claims.

### 12. `unit/test_sync_operations.test.sh` → `test_sync_handles_missing_manifests` — `rotten-green`

- **Location:** `unit/test_sync_operations.test.sh` → `test_sync_handles_missing_manifests`
- **Smell:** `rotten-green`
- **Rationale:** After removing the manifest, the only output check is `grep ... || true`, so sync can produce any result and the test still passes. See [rotten-green](https://texarkanine.github.io/slobac/taxonomy/rotten-green/).
- **Prescribed remediation:** Assert a concrete warning/error or preserved state after missing-manifest sync.
- **Why this isn't a false positive:** This is not a deliberate framework smoke test; the oracle is disabled.

### 13. `unit/test_command_modes.test.sh` and `unit/test_command_sync.test.sh` command-add tests — `semantic-redundancy`

- **Location:** `unit/test_command_modes.test.sh` → `test_command_can_be_added_in_local_mode`, `test_command_can_be_added_in_commit_mode`, `test_command_can_be_added_in_global_mode`; `unit/test_command_sync.test.sh` → `test_command_syncs_to_local_commands_dir`, `test_command_syncs_to_commit_commands_dir`, `test_command_syncs_to_global_commands_dir`
- **Smell:** `semantic-redundancy`
- **Rationale:** Targeted reads confirm both files exercise the same observable behavior: `cmd_add_rule <*.md> --<mode>` deploys commands to the mode-specific commands directory. This matches the taxonomy signal for cross-file behavior clusters and same SUT entry point with assertion sets that are subsets of each other. `test_command_sync.test.sh` is the stronger canonical copy because it also asserts commands do not deploy to rules directories. See [semantic-redundancy](https://texarkanine.github.io/slobac/taxonomy/semantic-redundancy/).
- **Prescribed remediation:** Keep the three `test_command_sync.test.sh` tests as canonical, fold any unique “no error output” intent from `test_command_modes.test.sh` into explicit exit-status assertions there if needed, then delete the weaker command-mode copies.
- **Why this isn't a false positive:** This is not mirrored-component duplication or different business knowledge; both clusters call the same SUT function for the same command entity and mode placement contract.

### 14. `unit/test_command_modes.test.sh` and `unit/test_ruleset_commands.test.sh` ruleset-command tests — `semantic-redundancy`

- **Location:** `unit/test_command_modes.test.sh` → `test_ruleset_with_commands_can_be_added_local`, `test_ruleset_with_commands_can_be_added_commit`; `unit/test_ruleset_commands.test.sh` → `test_ruleset_with_commands_works_in_local_mode`, `test_ruleset_with_commands_allows_commit_mode`
- **Smell:** `semantic-redundancy`
- **Rationale:** Targeted reads confirm both files verify that rulesets containing commands can be added in local/commit mode and deploy command files to `.cursor/commands/{local,shared}`. The `test_ruleset_commands.test.sh` copies are stronger because they assert manifest placement and no old auto-switch warning. This matches the taxonomy’s cross-file same-observable cluster signal. See [semantic-redundancy](https://texarkanine.github.io/slobac/taxonomy/semantic-redundancy/).
- **Prescribed remediation:** Keep the `test_ruleset_commands.test.sh` versions as canonical for local/commit behavior; delete or fold the weaker `test_command_modes.test.sh` local/commit ruleset-command tests. Keep the global ruleset-command test unless a stronger global equivalent is added elsewhere.
- **Why this isn't a false positive:** The overlap is not protecting separate product surfaces; both tests target the same ruleset-command mode behavior through `cmd_add_ruleset`.

### 15. skill test organization — `deliverable-fossils`

- **Location:** `unit/test_skill_detection.test.sh`, `unit/test_skill_sync.test.sh`, and `unit/test_skill_list_display.test.sh`
- **Smell:** `deliverable-fossils`
- **Rationale:** Targeted reads show the skill tests are still organized and annotated by numbered “behaviors” from a “skill-support plan” (`behaviors 1-7`, `8-15`, `22-27`, `BEHAVIOR 1`, etc.) rather than only durable product capabilities. This matches the taxonomy signal for comments/docstrings citing design-doc section numbers or acceptance-criteria identifiers. See [deliverable-fossils](https://texarkanine.github.io/slobac/taxonomy/deliverable-fossils/).
- **Prescribed remediation:** Regroup/retitle the skill test inventory by durable product capabilities, for example skill detection, skill deployment, skill list rendering, skill cleanup, and skill symlink security. Remove plan behavior numbers from comments once the capability grouping is clear.
- **Why this isn't a false positive:** These numbers are not product vocabulary; they reference a development plan/checklist and do not appear to be part of ai-rizz’s user-facing model.

### 16. function-level filesystem/git tests under `unit/` — `wrong-level`

- **Location:** Representative examples: `unit/test_sync_operations.test.sh` → `test_sync_all_initialized_modes`, `test_sync_dual_mode_with_rulesets`; `unit/test_symlink_security.test.sh` → `test_commands_malicious_symlink_rejected`; `unit/test_skill_sync.test.sh` → `test_standalone_skill_deployed_to_skills_dir`; shared setup in `tests/common.sh`
- **Smell:** `wrong-level`
- **Rationale:** Targeted reads confirm many `unit/` tests deliberately leave the SUT-only call stack: they create real temp repositories, run real `git init/add/commit`, create symlinks and filesystem trees, mutate `$HOME`, and assert deployed files on disk. Under the supplied convention `unit/` → unit tier, this matches the taxonomy signal for unit-tier tests doing file I/O/subprocess-style integration work. See [wrong-level](https://texarkanine.github.io/slobac/taxonomy/wrong-level/).
- **Prescribed remediation:** Split the direct-function suite by actual level: keep pure helper tests in `unit/`, and move filesystem/git deployment/security/sync tests to an integration or component tier such as `tests/integration/functions/` or `tests/component/`, with CI sharding that preserves the fast loop.
- **Why this isn't a false positive:** The repo’s integration directory currently focuses on public CLI invocation, but the supplied tier convention still labels these files as unit; the targeted tests verify real filesystem/git integration effects, not isolated pure or mocked unit behavior.

## Tests considered but not flagged

- `integration/test_cli_deinit.test.sh` and `unit/test_deinit_modes.test.sh` share several scenario names, but targeted comparison shows different knowledge surfaces: full CLI invocation versus sourced `cmd_*` functions. These were not flagged as `semantic-redundancy`.
- CLI glyph and list-rendering tests were considered for `presentation-coupled`, but terminal output is part of this CLI’s public contract, so exact glyph assertions are appropriate.
- Env-var fallback tests use grep-heavy output/manifest checks, but they assert concrete override precedence and were not flagged as `vacuous-assertion`.
- Security and symlink tests use real filesystem fixtures; those fixtures are the input domain, so they were not flagged as `mystery-guest`.
- Shared `tests/common.sh` helpers are widely used, but the audit did not confirm order-dependent mutable state leakage, so `shared-state` was not flagged.

## Out-of-scope Requests

None.
