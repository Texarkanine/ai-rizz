---
task_id: ai-rizz-properdocs-docsite-20260508
complexity_level: 3
date: 2026-05-09
status: completed
---

# TASK ARCHIVE: properdocs documentation site for ai-rizz

## SUMMARY

Delivered a properdocs-based documentation site under `docs/`, migrated the former monolithic README into structured guides, added strict-build CI (PR + push-to-main GitHub Pages), and shrunk the root README to a sales pitch plus quickstart. After the reflect phase, follow-up work reorganized information architecture (split CLI commands, added rule-authoring and developer architecture pages), captured two post-reflect creative decisions (getting-started onboarding and ruleset source-repo contract), and landed those changes in commits after `4c391c5`.

## REQUIREMENTS

From the project brief:

- Add `docs/` with a conventional properdocs layout; migrate all README content without loss; pass `properdocs build --strict`.
- Add `properdocs.yaml`, `pyproject.toml` `[dependency-groups] docs`, and `uv.lock` for reproducible docs builds.
- Add GitHub Actions: reusable strict build, deploy on push to `main`, and PR validation via existing `pr.yaml`.
- Reduce root `README.md` to under ~80 lines while linking prominently to full docs.
- Keep ai-rizz shell-first; Python toolchain docs-only.
- Follow Niko Level 3 workflow with TDD where applicable (strict build as integrity gate for docs).

## IMPLEMENTATION

### Core delivery (build phase)

1. **Toolchain**: `pyproject.toml` with docs dependency group; `uv.lock`; local Makefile targets (`docs`, `docs-build`).
2. **Configuration**: `properdocs.yaml` with strict mode, Material theme, validation, GitHub-compatible slugifier.
3. **Content migration**: README material split across `docs/index.md`, getting-started, user-guide, advanced, and developer-guide sections; internal links made relative; `.gitignore` for `site/`, `.venv/`, caches.
4. **CI/CD**: `.github/workflows/reusable-docs-build.yml` (single source of truth for `properdocs build --strict`), `.github/workflows/docs.yaml` (push to `main` + `workflow_dispatch`, Pages deploy), `pr.yaml` extended with a `docs` job using the reusable workflow without artifact upload.
5. **README**: Reduced from hundreds of lines to a concise landing page with links to the published docs site for depth.

### Post-reflect follow-up (commits after `4c391c5`)

Work continued after reflection was written. The following git history summarizes changes not covered by the original reflection closure:

| Commit     | Summary |
| ---------- | ------- |
| `2197237` | `chore: saving work` — Documentation IA iteration: split former `user-guide/commands.md` into per-command pages under `docs/user-guide/commands/`, introduced `docs/user-guide/.pages` and navigation tweaks, expanded `docs/index.md` and `docs/getting-started.md`, added `docs/user-guide/core-concepts.md`, moved and reshaped advanced/installation content, stubbed `docs/developer-guide/building-rulesets.md` and `docs/developer-guide/rules-cache.md`, removed or folded some redundant index pages. |
| `3d4bf69` | `fix(docs): I did id` — Larger docs restructure and alignment with creative decisions: added `docs/developer-guide/architecture.md` and `docs/developer-guide/manifest.md`; removed superseded `progressive-manifest.md`; introduced `docs/rule-authoring/` (`index.md`, `rules.md`, `rulesets.md`) for authoring-focused content; relocated advanced constraint/env docs under `docs/user-guide/advanced/`; expanded command docs (`docs/user-guide/commands/index.md`); trimmed duplicated index material; updated `properdocs.yaml`, `docs/.pages`, complexity-analysis reference; minor `README.md` and `ai-rizz` script touch-up; added `memory-bank/active/creative/` decision records; dependency refresh in `uv.lock`. |

Together, these commits complete the narrative that the reflect document had not yet seen: **creative phase artifacts were produced after reflect**, not before build.

### Creative phase decisions (inlined; post-reflect)

The reflection file stated no creative phase ran during the initial plan/build window. The following two documents were added later and are preserved here in full.

---

### Creative: Getting Started Next Steps

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
|-----------|-------------------------|-----------------------|----------------------|
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

---

### Creative: Ruleset Source Repository Contract

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
|-----------|-------------------|-------------------------------|----------------------|
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

---

### Reflection insights (inlined from `reflection-ai-rizz-properdocs-docsite-20260508.md`)

**Requirements vs outcome**: All brief requirements met; "Contributing" subsection was omitted because source README had no contributing material (appropriate adaptation).

**Plan accuracy**: Seven-step plan executed in order; content migration was the largest slice. Post-preflight refinement moved PR doc checks into existing `pr.yaml` (additive).

**Original creative phase (during plan)**: None — structure came from README ToC.

**Build**: `properdocs --strict` caught internal link/anchor issues during migration.

**QA**: Fixed README external anchor typo (`#-` vs `#--` for hook-based-ignore-local-mode); updated `techContext.md` for docs toolchain. Noted pre-existing wrong default path in installation docs migrated faithfully.

**Cross-phase**: Preflight PASS justified; first premature QA correctly failed until build complete.

**Technical insight**: `properdocs --strict` does not validate anchors inside absolute URLs (e.g., README → deployed site). Manual or supplementary URL checks would close the gap.

**Reconciliation**: The reflection’s “no creative phase” statement applied to the **initial** timeline. Follow-up creative documents and IA commits completed afterward are captured above under post-reflect work and inlined creative sections.

### Key files touched (non-exhaustive)

- `properdocs.yaml`, `pyproject.toml`, `uv.lock`, `Makefile`, `.gitignore`
- `.github/workflows/reusable-docs-build.yml`, `.github/workflows/docs.yaml`, `.github/workflows/pr.yaml`
- `docs/**` (site structure, later reorganized in commits after `4c391c5`)
- `README.md`
- `.cursor/skills/shared/niko/references/core/complexity-analysis.md` (minor edit in `3d4bf69`)

## TESTING

- `uv run properdocs build --strict`: required to pass locally and in CI; primary integrity gate for internal links and anchors.
- `make test`: full shell test suite green (32/32 at QA completion); docs changes do not alter runtime tests but regression suite was run during the task.
- GitHub Actions: reusable workflow invoked from PR pipeline and main deploy path.

## LESSONS LEARNED

1. **Strict mode value**: Internal cross-links and anchors fail fast; keeps migration honest.
2. **External README links**: Deployed-site URLs in README are outside strict validation — worth a separate check or discipline when editing anchors.
3. **QA gate**: First QA attempt correctly failed when build was incomplete; prerequisite enforcement worked.
4. **Plan flexibility**: Consolidating doc checks into `pr.yaml` improved contributor UX without duplicating workflow files.
5. **Phase ordering vs reality**: Creative exploration can legitimately land **after** reflect when documentation IA continues; archive should capture that chronology so future readers are not misled by an earlier “no creative” snapshot.

## PROCESS IMPROVEMENTS

- When documentation IA spans multiple commits after reflect, either update the reflection in place or treat post-reflect creative docs as first-class deliverables in archive (as done here).
- Consider a brief “freeze” checklist before reflect: “no further doc restructuring planned” — or explicitly schedule reflect after IA stabilizes.

## TECHNICAL IMPROVEMENTS

- Evaluate a post-build or CI step that checks a curated list of external URLs (or README-specific anchor patterns) if README continues to deep-link to GitHub Pages anchors.
- Optional follow-up: correct the installation default path documentation if product behavior is `~/.local/bin` vs `/usr/local/bin` (noted during QA as pre-existing migration).

## NEXT STEPS

- None required for closure of this task. Optional doc hygiene: fix installation path narrative if product defaults differ; add external URL anchor check if desired.
