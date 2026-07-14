# Tech Context

Single-file POSIX shell script (`ai-rizz`) with a shunit2-based test suite.

## Environment Setup

- Must NOT be tested in the project directory — `ai-rizz` uses itself to manage its own rules
- Tests require git user/email configured; use `git commit --no-gpg-sign` in tests
- WSL2 environment; run `git` with `--no-pager`

## Build Tools

- [`Makefile`](./Makefile) — `make install`, `make test`, `make test-unit`, `make test-integration`, `make docs`, `make docs-build`

## Docs-Build Toolchain

The documentation site is built with [properdocs](https://github.com/ProperDocs/properdocs) (MkDocs continuation) + [mkdocs-material](https://squidfunk.github.io/mkdocs-material/). There is no runtime Python code in this project; the Python toolchain exists solely for docs.

- Configuration: [`properdocs.yaml`](./properdocs.yaml) (strict mode enabled — warnings become errors)
- Dependencies: [`pyproject.toml`](./pyproject.toml) `[dependency-groups] docs` + [`uv.lock`](./uv.lock)
- Local preview: `make docs` (or `uv run properdocs serve`)
- CI-parity build: `make docs-build` (or `uv sync --group docs --frozen && uv run properdocs build --strict`)

## Testing Process

- Tests use [shunit2](./shunit2) (bundled at repo root) with test helpers in [`tests/common.sh`](./tests/common.sh)
- Run all tests: `make test`
- **`make test-unit`** — only [`tests/unit/`](./tests/unit/) (fast, minimal suites such as pure helper checks)
- **`make test-integration`** — everything under [`tests/integration/`](./tests/integration/) recursively, including [`tests/integration/functions/`](./tests/integration/functions/) (CLI suites plus direct `cmd_*` tests with real git/filesystem work)
- Run single suite (examples): `./tests/unit/test_skill_detection.test.sh`, `./tests/integration/functions/test_sync_operations.test.sh`
- Run single suite verbose: `VERBOSE_TESTS=true ./tests/integration/functions/test_sync_operations.test.sh`
- Test naming: `test_<description>()` functions; files named `test_<feature>.test.sh`

## Design System

Docs site chrome: [`docs/stylesheets/extra.css`](../docs/stylesheets/extra.css) (`primary`/`accent: custom` via [`properdocs.yaml`](../properdocs.yaml)). Two families — Texarkanine (`default`/`slate`) and Rizzed (`rizz`/`rizz-slate`) — toggled by a palette-swatch inline right of search ([`overrides/partials/header.html`](../overrides/partials/header.html) + [`docs/javascripts/theme-family.js`](../docs/javascripts/theme-family.js)).
