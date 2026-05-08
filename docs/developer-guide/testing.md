# Testing

The project uses [shunit2](https://github.com/kward/shunit2) for unit and integration testing.

## Test Structure

```
tests/
├── common.sh                        # Common test utilities and helper functions
├── run_tests.sh                     # Test runner script
├── integration/                     # Integration tests (CLI + function-level)
│   └── functions/                  # Direct cmd_* / sync tests (real git & filesystem)
└── unit/                            # Fast unit-tier suites (e.g. pure helpers)
```

## Running Tests

```bash
# Run all tests (quiet mode - default)
make test

# Run tests with verbose output
VERBOSE_TESTS=true make test

# Run specific test file (quiet) — examples
sh tests/unit/test_skill_detection.test.sh
sh tests/integration/functions/test_sync_operations.test.sh

# Run specific test file (verbose)
VERBOSE_TESTS=true sh tests/integration/functions/test_sync_operations.test.sh
```

## Test Output Modes

**Quiet Mode (Default)**:

- Shows only test names and PASS/FAIL status
- Failed tests automatically re-run with verbose output for debugging
- Provides clean, summary-focused output for CI/CD and regular development

**Verbose Mode**:

- Shows all test setup, execution, and diagnostic information
- Useful for test development and troubleshooting
- Activated with `VERBOSE_TESTS=true`

## Testing Best Practices

**For Test Development**:

- Use `test_echo` for setup and progress messages
- Use `test_debug` for detailed diagnostic information
- Use `test_info` for general informational messages
- Keep `echo` for test assertions and critical errors
- Test in both quiet and verbose modes during development

**For Troubleshooting**:

- Failed tests automatically show verbose output
- Use `VERBOSE_TESTS=true` to see all test details
- Individual test files can be run directly with verbose output

**For CI/CD**:

- Default quiet mode provides clean, parseable output
- Failed tests include full diagnostic information
- Exit codes properly indicate success/failure

## GitHub Pages Setup (one-time)

For docs deployment to work, the repository must have GitHub Pages enabled with **Source: GitHub Actions** under Settings → Pages. This is a one-time per-repository configuration.
