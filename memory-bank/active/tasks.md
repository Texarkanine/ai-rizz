# Task: properdocs documentation site for ai-rizz

* Task ID: ai-rizz-properdocs-docsite-20260508
* Complexity: Level 3
* Type: feature (new documentation subsystem + CI publishing)

Migrate the comprehensive but monolithic 721-line README into a properdocs documentation site under `docs/`, add the required tooling and GitHub Actions for strict-mode builds and push-to-main deployment to GitHub Pages, and shrink the root README to a focused sales-pitch + quickstart while preserving every piece of information.

## Pinned Info

### Recommended Doc Site Structure
The existing README ToC already provides an excellent logical outline. We will map it almost 1:1 into MkDocs-style sections for minimal cognitive load during migration.

## Component Analysis

### Affected Components
- **README.md** (root): Current single source of truth (721 lines) → Reduced to sales pitch + quickstart + prominent "Full Documentation" link. All other content moved to `docs/`.
- **`docs/` (new directory)**: New canonical home for all user/developer documentation. Will contain `index.md`, `getting-started.md`, `user-guide/`, `advanced/`, `developer-guide/`, and `reference.md` (or equivalent).
- **`properdocs.yaml` (new, at root)**: Site configuration, strict mode, theme, plugins, validation. Modeled directly on slobac's working example.
- **`pyproject.toml` (new or extended)**: Add `[project]` stub + `[dependency-groups] docs` (properdocs, mkdocs-material, pymdown-extensions, mkdocs-awesome-pages-plugin) using the same loose-pin style as slobac.
- **`.github/workflows/reusable-docs-build.yml` (new)**: Reusable job that does `uv sync --group docs --frozen && uv run properdocs build --strict`. Optional Pages artifact upload. Called by both PR validation and the deploy workflow.
- **`.github/workflows/docs.yaml` (new)**: Main workflow triggered on `push: branches: [main]` + `workflow_dispatch`. Calls reusable build (with artifact upload), then deploys to GitHub Pages. (Different trigger than slobac's release-based one; ai-rizz publishes docs on every merge to main.)
- **`.github/workflows/pr.yaml` (existing)**: Add a new `docs` job that calls the reusable build workflow (upload-pages-artifact: false) to enforce `properdocs --strict` validation on every PR. This provides early feedback on doc link/anchor integrity without requiring separate workflow file. (Best practice per operator feedback — keeps all PR checks in one place.)
- **Makefile (existing)**: Optional but recommended: add a `docs` target for local `uv run properdocs serve` convenience.
- **Existing test/CI infrastructure**: Unaffected at runtime; `make test` must still pass. Docs build is a separate concern.

### Cross-Module Dependencies
- Content in README.md must be faithfully extracted; all internal links rewritten to relative `docs/` paths.
- The new CI must coexist with any existing GitHub Actions (ai-rizz currently has none visible in quick scan).
- `properdocs --strict` acts as the automated link/anchor integrity gate for the entire cross-linked tree.

### Boundary Changes
- The project's public "front door" changes from a long README to a docs site + slim README.
- New Python dependency group introduced (dev-only; no impact on shell runtime or `make install`).

## Open Questions

None — implementation approach is clear. The current README ToC provides a ready-made navigation skeleton. Content slicing will follow that structure with only minor polish for web readability. `properdocs --strict` will catch any link issues during build.

## Test Plan (TDD)

### Behaviors to Verify
- `uv sync --group docs --frozen && uv run properdocs build --strict` completes with exit code 0 and zero warnings (link/anchor validation passes).
- Local `uv run properdocs serve` works for preview.
- The reusable build is called from PR checks (via updated pr.yaml) and from the deploy workflow, providing strict validation on every PR and on every push to main.
- GitHub Actions deploy workflow triggers on push to main, builds cleanly, and produces a deployable Pages artifact.
- Root README remains useful: developer can install and run the first recipe in < 2 minutes.
- All original information from the 721-line README is present in the docs site (no loss of content).

### Test Infrastructure
- Framework: properdocs (strict mode) + uv for environment.
- New "test" locations: the docs build command itself + existing `make test` (must stay green).
- No traditional shunit2 tests for docs config; the strict build serves as the verification step.
- New test files: none (config + content validation via build).

### Integration Tests
- Full docs build + strict validation in CI (cross-checks all internal links created during content slicing).

## Implementation Plan

1. **Setup Python/docs toolchain (foundational, fewest dependencies)**
   - Create `pyproject.toml` with `[project]` stub (name=ai-rizz-docs, requires-python, description) and `[dependency-groups] docs` exactly mirroring slobac's pins.
   - Create `uv.lock` by running `uv lock` (or let CI generate on first run).
   - Files: `pyproject.toml`, `uv.lock`

2. **Create properdocs configuration**
   - Write `properdocs.yaml` at repo root.
   - `docs_dir: docs`, `site_dir: site`, `strict: true`, validation block, material theme, awesome-pages plugin, pymdown extensions (copy/adapt from slobac).
   - Files: `properdocs.yaml`

3. **Create the `docs/` tree and migrate content (largest creative slice)**
   - `docs/index.md` — Overview + sales pitch (why use ai-rizz) + link to quickstart.
   - `docs/getting-started.md` — Prerequisites, installation, common recipes (move from README Quick Start).
   - `docs/user-guide/` — Configuration, Rule Modes, Installation Options, Commands (full CLI reference).
   - `docs/advanced/` — Constraints, Rulesets with Commands, Repository Integrity, Environment Variable Fallbacks.
   - `docs/developer-guide/` — Progressive Manifest System, Testing (how to run `make test`, etc.), Contributing.
   - Rewrite all internal links to be relative and GitHub-compatible (so they also render on github.com).
   - Files: many new `.md` under `docs/`

4. **Shrink the root README.md**
   - Keep: Project description, why you'd benefit, Quick Start (minimal recipes), prominent link to full docs site.
   - Remove: Detailed User Guide, Advanced, Developer sections (now in docs/).
   - Target length: ~60-80 lines.
   - Files: `README.md`

5. **Add GitHub Actions workflows** (split retained for reusability + PR validation)
   - Create `.github/workflows/reusable-docs-build.yml` (checkout, setup-uv, uv sync --group docs --frozen, properdocs build --strict, conditional artifact upload). This is the single source of truth for the strict build.
   - Create `.github/workflows/docs.yaml` (trigger on `push: branches: [main]` + `workflow_dispatch`, permissions for Pages, concurrency group, calls reusable build *with* artifact upload, then deploy-pages). This handles the production docs deployment on every merge to main.
   - **Update existing `.github/workflows/pr.yaml`**: Add a `docs` job (after the existing shellcheck + tests jobs) that calls the reusable build workflow with `upload-pages-artifact: false`. This gives every PR immediate `properdocs --strict` feedback (link/anchor validation, build success) without a separate workflow file. (Preferred approach per clarification — keeps all PR checks consolidated.)
   - Files: reusable + deploy workflows (new) + modification to pr.yaml (existing)

6. **Optional convenience: Makefile target**
   - Add a `docs` target that runs the local preview command.
   - Files: `Makefile`

7. **Verification & Polish**
   - Run `uv sync --group docs && uv run properdocs build --strict` locally until green.
   - Run full `make test` to ensure no regression.
   - Commit everything together.

## Technology Validation

New technology: properdocs + uv + mkdocs-material stack (identical to the proven slobac setup). Validation will occur by successfully running the build command locally before the first PR. No proof-of-concept script needed beyond the actual docs site build.

## Challenges & Mitigations
- **Challenge**: Content slicing could introduce broken links or lose nuance. **Mitigation**: `properdocs --strict` + manual review of key pages; all links relative; GitHub slugifier configured for compatibility.
- **Challenge**: First-time uv + properdocs setup in a shell-only repo. **Mitigation**: Exact copy of slobac's working `pyproject.toml` + `properdocs.yaml` patterns; documentation in the new developer guide.
- **Challenge**: GitHub Pages environment/permissions must be enabled on the repo. **Mitigation**: Document the one-time repo setting in the developer guide; workflow uses standard `actions/deploy-pages`.

## Status
PLAN - COMPLETE (refined post-preflight for PR doc validation via existing pr.yaml; preflight still valid — additive change only)