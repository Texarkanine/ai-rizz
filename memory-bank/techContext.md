# Tech Context

Single-file POSIX shell script (`ai-rizz`) with a shunit2-based test suite.

## Environment Setup

- Must NOT be tested in the project directory — `ai-rizz` uses itself to manage its own rules
- Tests require git user/email configured; use `git commit --no-gpg-sign` in tests
- WSL2 environment; run `git` with `--no-pager`

## Build Tools

- [`Makefile`](./Makefile) — `make install`, `make test`, `make test-unit`, `make test-integration`

## Testing Process

- Tests use [shunit2](./shunit2) (bundled at repo root) with test helpers in [`tests/common.sh`](./tests/common.sh)
- Run all tests: `make test`
- **`make test-unit`** — only [`tests/unit/`](./tests/unit/) (fast, minimal suites such as pure helper checks)
- **`make test-integration`** — everything under [`tests/integration/`](./tests/integration/) recursively, including [`tests/integration/functions/`](./tests/integration/functions/) (CLI suites plus direct `cmd_*` tests with real git/filesystem work)
- Run single suite (examples): `./tests/unit/test_skill_detection.test.sh`, `./tests/integration/functions/test_sync_operations.test.sh`
- Run single suite verbose: `VERBOSE_TESTS=true ./tests/integration/functions/test_sync_operations.test.sh`
- Test naming: `test_<description>()` functions; files named `test_<feature>.test.sh`
