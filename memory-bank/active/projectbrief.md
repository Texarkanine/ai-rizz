# Project Brief: M1 — slobac-audit-fixes-2

## User Story

As an ai-rizz maintainer, I want **Milestone 1** of the SLOBAC remediation (audit findings **1–14** in [`slobac-audit-2.md`](../../slobac-audit-2.md)) applied to the test suite, so that named tests match their assertions, rotten-green `grep ... || true` oracles are replaced, conditional assertions are unconditional where required, and redundant command/ruleset tests are removed without losing coverage.

## Source of Requirements

- [`slobac-audit-2.md`](../../slobac-audit-2.md) — findings **1–14** only (see Findings section).
- [`memory-bank/active/milestones.md`](milestones.md) — M1 scope and cross-milestone invariants.

## Scope (M1)

Per [`slobac-audit-2.md`](../../slobac-audit-2.md):

| # | File(s) | Smell | Test |
|---|---------|-------|------|
| 1 | `integration/test_cli_add_remove.test.sh` | conditional-logic | `test_add_rule_with_invalid_repository` |
| 2–3 | `integration/test_cli_init.test.sh` | naming-lies, vacuous-assertion | `test_init_mode_defaults` |
| 4 | `integration/test_help_and_usage.test.sh` | naming-lies | `test_help_mentions_key_commands` |
| 5 | `unit/test_deinit_modes.test.sh` | naming-lies | `test_deinit_confirmation_prompts` |
| 6 | `unit/test_deinit_modes.test.sh` | rotten-green | `test_deinit_partial_cleanup_on_error` |
| 7 | `unit/test_error_handling.test.sh` | rotten-green | `test_graceful_empty_repository` |
| 8–9 | `unit/test_hook_based_local_mode.test.sh` | naming-lies | custom manifest / custom target hook tests |
| 10 | `unit/test_list_display.test.sh` | naming-lies | `test_list_handles_empty_commands_directory` |
| 11 | `unit/test_ruleset_management.test.sh` | naming-lies | `test_prevent_downgrade_from_local_ruleset` |
| 12 | `unit/test_sync_operations.test.sh` | rotten-green | `test_sync_handles_missing_manifests` |
| 13 | `unit/test_command_modes.test.sh` vs `unit/test_command_sync.test.sh` | semantic-redundancy | command-add clusters |
| 14 | `unit/test_command_modes.test.sh` vs `unit/test_ruleset_commands.test.sh` | semantic-redundancy | ruleset-command clusters |

## Out of Scope (defer to M2/M3)

- Finding **15** (skill test deliverable-fossils) — **M2**.
- Finding **16** (wrong-level / tier reorg) — **M3**.
- Any change to production script `ai-rizz` (cross-milestone invariant).

## Definition of Done (M1)

- Findings **1–14** remediated as prescribed in `slobac-audit-2.md`, or deviation documented with rationale in the M1 reflection.
- **`make test`** exits 0.
- Cross-milestone invariants in `milestones.md` respected (coverage preserved when deleting tests, no new SLOBAC smells traded in).
