# Project Brief

## User Story

As a ruleset author, I want symlinked skill directories under a ruleset's `skills/` directory to be discovered and installed just like normal embedded skills so that reusable skills can be shared without duplication.

## Use-Case(s)

### Use-Case 1

A ruleset contains `skills/<name>/SKILL.md` as a real directory and `skills/<name2>` as a symlink to another in-repo skill directory. Both appear in `ai-rizz list`.

### Use-Case 2

When installing or syncing that ruleset, both real and symlinked skill directories are copied into `.cursor/skills/<mode>/`.

### Use-Case 3

A symlink that resolves outside the source repository is rejected/skipped for safety and is not listed as installable.

## Requirements

1. Update embedded skill discovery so symlinked directories are considered for both listing and install/sync.
2. Preserve or strengthen existing symlink safety checks so only in-repository targets are accepted.
3. Add/adjust automated tests to verify expected behavior for in-repo and out-of-repo symlink targets.
4. Update documentation site content to describe support for symlinked embedded skills and safety constraints.

## Constraints

1. Follow existing shell style and command architecture used in the `ai-rizz` codebase.
2. Do not weaken existing security posture around symlink resolution.
3. Execute test changes using project testing conventions (`make test`, targeted suites only for iteration).

## Acceptance Criteria

1. `ai-rizz list` shows symlinked embedded skills when the symlink resolves to a valid in-repo skill directory with `SKILL.md`.
2. Install/sync deploys symlinked embedded skills into `.cursor/skills/<mode>/`.
3. Symlinks resolving outside the repo remain skipped/rejected.
4. Regression tests cover both supported and rejected symlink scenarios.
5. Documentation site is updated to reflect behavior and constraints.
