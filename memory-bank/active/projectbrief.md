# Project Brief: slobac-audit-fixes-2

## User Story

As an ai-rizz maintainer, I want the test suite to be free of the smells identified in [`slobac-audit-2.md`](../../slobac-audit-2.md), so that the suite genuinely tests the behaviors its names and structure claim to test, and is organized at the correct test tier.

## Source of Requirements

The authoritative source for this work is [`slobac-audit-2.md`](../../slobac-audit-2.md) at the repo root. It contains 16 findings across 7 smell types, each with location, rationale, prescribed remediation, and a "why this isn't a false positive" justification.

## Scope

All 16 findings in the audit must be remediated as prescribed:

- **7 `naming-lies`**: rename or strengthen tests where the name promises behavior the body doesn't verify.
- **3 `rotten-green`**: replace `grep ... || true` patterns with real assertions.
- **2 `semantic-redundancy`**: delete the weaker duplicates in `test_command_modes.test.sh`, keeping the canonical versions.
- **1 `conditional-logic`**: assert the failure contract unconditionally in `test_add_rule_with_invalid_repository`.
- **1 `vacuous-assertion`**: strengthen `test_init_mode_defaults` (overlaps with naming-lies on the same test).
- **1 `deliverable-fossils`**: regroup/retitle skill tests by durable capabilities instead of "behavior N" plan numbers.
- **1 `wrong-level`**: relocate filesystem/git-using tests out of `unit/` into a new integration/component tier.

## Out of Scope

- Changes to ai-rizz production code (`ai-rizz` script). This work touches only tests, test infrastructure (`Makefile`, `tests/common.sh`), and test directory layout.
- Findings or smells not listed in `slobac-audit-2.md`.

## Definition of Done

- Every finding in `slobac-audit-2.md` is either fixed as prescribed or has a documented justification for deviating from the prescription.
- The full test suite (`make test`) passes.
- No production code (`ai-rizz`) is modified.
