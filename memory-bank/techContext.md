# Tech Context

Single-file POSIX shell script (`ai-rizz`) with a shunit2-based test suite.

## Environment Setup

- Must NOT be tested in the project directory — `ai-rizz` uses itself to manage its own rules
- Tests require git user/email configured; use `git commit --no-gpg-sign` in tests
- WSL2 environment; run `git` with `--no-pager`

## Build Tools

- [`Makefile`](./Makefile) — `make install`, `make test`, `make test-unit`, `make test-integration`

## Testing Process

- Tests use [shunit2](./shunit2) (bundled) with test helpers in [`tests/common.sh`](./tests/common.sh)
- Run all tests: `make test`
- Run single suite: `./tests/unit/test_foo.test.sh`
- Run single suite verbose: `VERBOSE_TESTS=true ./tests/unit/test_foo.test.sh`
- Unit tests in `tests/unit/`, integration tests in `tests/integration/`
- Test naming: `test_<description>()` functions; files named `test_<feature>.test.sh`
