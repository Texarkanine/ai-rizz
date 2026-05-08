# Project Brief

## User Story

As a maintainer and contributor to the ai-rizz project, I want a properdocs (MkDocs successor) documentation site so that the very long README.md can be sliced into a sane, cross-linked, navigable docsite under `docs/`, while the root README is reduced to a concise sales pitch + quickstart for developers. New documentation must be published automatically on every push to `main` (ai-rizz's lifecycle is "merge to main = live at HEAD of default branch").

## Use-Case(s)

### Use-Case 1: Initial Setup & Content Migration
A new contributor or maintainer can run `uv run properdocs serve` locally and `uv run properdocs build --strict` in CI. The entire informational content currently crammed into the 721-line README is reorganized into a logical docsite structure (getting-started, reference, guides, etc.) with working internal links, and `properdocs --strict` guarantees zero broken links or anchors.

### Use-Case 2: Continuous Documentation Deployment
Every push to the `main` branch triggers a GitHub Actions workflow that builds the docs site with `properdocs build --strict` and deploys it to GitHub Pages. The site is always at the latest HEAD of the default branch (no release-please, no tag-based publishing).

### Use-Case 3: Developer Onboarding via README
A developer landing on the GitHub repo sees a short, compelling README that explains why they would benefit from ai-rizz and gives a 60-second quickstart, with a prominent link to the full documentation site for deeper information.

## Requirements

1. Create a `docs/` directory with a normal/typical properdocs layout (index.md, getting-started/, reference/, etc.).
2. Add `properdocs.yaml` at the repo root (modeled on slobac's but adapted for ai-rizz paths and push-to-main publishing).
3. Add docs-build dependencies to `pyproject.toml` under `[dependency-groups] docs` (properdocs, mkdocs-material, etc.) using loose pins + uv.lock for reproducibility.
4. Add GitHub Actions workflows:
   - Reusable `reusable-docs-build.yml` (checkout, uv sync --group docs --frozen, properdocs build --strict, optional Pages artifact upload).
   - `docs.yaml` that triggers on `push: branches: [main]` + workflow_dispatch, calls the reusable build, then deploys to GitHub Pages (with appropriate permissions and concurrency).
5. Slice the content of the existing long `README.md` into the new `docs/` tree, preserving all information and ensuring `properdocs --strict` passes with no broken links.
6. Reduce the root `README.md` to a sales-pitch + quickstart (developers still get immediate value; everything else lives in the docs site).
7. All changes must follow TDD where code/config is involved, full Niko L3 workflow, and be committed as one logical unit.
8. `properdocs --strict` must be the integrity gate (warnings become errors).

## Constraints

1. No release-please in ai-rizz; docs publish on every push to main.
2. Keep the project primarily a shell-script / rule-based tool — the Python toolchain is **only** for docs building (no runtime Python code added to ai-rizz itself).
3. Follow slobac's proven patterns exactly for the tooling/CI shape (properdocs.yaml, pyproject.toml, reusable workflow) while changing only the trigger and paths.
4. All internal links in the new docs must be relative and pass `properdocs --strict` validation.
5. The root README must remain useful and not become a stub.

## Acceptance Criteria

1. `uv sync --group docs && uv run properdocs build --strict` succeeds locally with zero warnings/errors.
2. Pushing to main triggers the docs workflow; the built site is deployed to GitHub Pages.
3. The `docs/` tree contains all information previously in README.md, organized logically, with a clean navigation structure.
4. Root `README.md` is now a concise sales pitch + quickstart (target: < 80 lines) with a link to the full docs site.
5. No broken links, anchors, or omitted files (`properdocs --strict` passes in CI).
6. All new files and changes are committed together following project conventions.