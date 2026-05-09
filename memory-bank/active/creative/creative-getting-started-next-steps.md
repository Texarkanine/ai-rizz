# Decision: Getting Started Next Steps

## Context
We need to decide what a user should do immediately after `make install` in `docs/getting-started.md`.

This matters because "install and done" creates a dead end, while over-specific onboarding can be wrong for many users.

Constraints:
- Readers are unknown (solo, team, or multi-repo usage).
- First steps must be copy-pasteable and low risk.
- Examples should match real entities in the reference repo (`Texarkanine/.cursor-rules`).
- The flow should teach mode intent (local/commit/global), not just syntax.

## Options Evaluated
- **Single canonical local-first flow**: One "do this first" recipe using local mode only.
- **Mode chooser with three first-run recipes**: One short recipe per mode (local, commit, global).
- **Concept-only guidance**: Explain modes and defer all commands to command reference pages.

## Analysis
| Criterion | Single local-first flow | Three recipes by mode | Concept-only guidance |
|-----------|-------------------------|-----------------------|-----------------------|
| Clarity | High for one persona, weak for others | High across personas | Medium |
| Cognitive load | Lowest | Moderate | Low |
| Actionability | High | High | Low |
| Risk of wrong fit | Medium to high | Low | Medium |
| Consistency with docs goals | Medium | High | Medium |

Key insights:
- Local-first is excellent for safety but implies a preference that is not always true for teams.
- "Unknown reader" is better handled by offering explicit branches than by removing examples.
- Running `ai-rizz list` immediately after `init` lets users discover valid names in their own source repo.

## Decision
**Selected**: Mode chooser with three first-run recipes
**Rationale**: It keeps examples concrete while acknowledging that users have different sharing scopes. It also avoids forcing a default mental model.
**Tradeoff**: The section is longer than a single quickstart path.

## Implementation Notes
- Replace the TODO block with "Now Try One Path".
- Provide three copy-pasteable recipes:
  - local + add one rule
  - commit + add one ruleset
  - global + add one ruleset
- Include one sentence telling readers to substitute names from their own `ai-rizz list` output.
- Add links to deeper docs for mode behavior and mixed-mode workflows.
