# Decision: Ruleset Source Repository Contract

## Context
We need to define and document the source-repository authoring contract for rulesets in `docs/developer-guide/building-rulesets.md`.

This matters because current docs do not clearly state what `ai-rizz` supports for:
- ruleset-local rules
- ruleset-local skills
- command detection behavior
- symlink conventions vs requirements

Constraints:
- Documentation must reflect current `ai-rizz` behavior and tests.
- `.cursor-rules` should be treated as canonical convention evidence, not as a hard format requirement.
- Must clearly distinguish required structure from recommended structure.
- Must capture magic subdirectories (`skills/`, optional `commands/`) and edge-case handling.

## Options Evaluated
- **Symlink-only spec**: Document only symlink-based rulesets as supported.
- **Permissive behavior-first spec**: Document everything currently supported by implementation/tests (symlink and non-symlink patterns).
- **Convention-only spec**: Describe `.cursor-rules` layout as the de facto standard and omit less common supported cases.

## Analysis
| Criterion | Symlink-only spec | Permissive behavior-first spec | Convention-only spec |
|-----------|-------------------|--------------------------------|----------------------|
| Accuracy vs runtime behavior | Low | High | Medium |
| Maintainability | Medium | High | Medium |
| Onboarding clarity | Medium | High | High |
| Regression risk from docs drift | High | Low | Medium |
| Alignment with existing tests | Low | High | Medium |

Key insights:
- `ai-rizz` explicitly supports ruleset-local `.mdc` files and embedded skills under `rulesets/<r>/skills/<name>/SKILL.md`; omitting these would be incorrect.
- Symlink-heavy layout is a strong recommendation (and common in `.cursor-rules`), but not a parser requirement.
- Command detection includes an important exception: `.md` files under `skills/` are intentionally excluded from flat command deployment.

## Decision
**Selected**: Permissive behavior-first spec
**Rationale**: This is the only option that is fully faithful to implementation and test coverage while still allowing conventions to be recommended.
**Tradeoff**: The page is more detailed and less minimal than a convention-only guide.

## Implementation Notes
- Document standalone entity contract for `rules/` (rules, commands, standalone skills).
- Document ruleset contract for `rulesets/<name>/`:
  - `.mdc` behavior (file structure preservation vs symlink flattening)
  - `.md` command flattening rules
  - `skills/` embedded-skill behavior
- Explicitly mark symlink-first as recommendation, not requirement.
- Add practical layout examples (symlink-biased and ruleset-local).
- Link advanced user-facing command behavior page back to this developer contract.
