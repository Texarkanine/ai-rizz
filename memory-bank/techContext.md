# Memory Bank: Technical Context

## Technology Stack

- **Language**: POSIX shell script (sh-compatible)
- **Test Framework**: shunit2
- **Version Control**: Git
- **CI/CD**: GitHub Actions (`.github/workflows/pr.yaml`)

## Project Structure

```
ai-rizz/
├── ai-rizz                 # Main executable script
├── Makefile                # Test runner
├── shunit2                 # Test framework
├── tests/
│   ├── common.sh           # Shared test utilities
│   ├── run_tests.sh        # Test orchestrator
│   ├── unit/               # Unit test suites
│   └── integration/        # Integration test suites
├── memory-bank/            # Project documentation
└── .cursor/rules/          # ai-rizz's own rules (dogfooding)
```

## Key Architectural Patterns

### Three-Mode Architecture

ai-rizz supports three operational modes:

| Mode | Manifest | Rules Target | Commands Target | Glyph |
|------|----------|--------------|-----------------|-------|
| local | `ai-rizz.local.skbd` | `.cursor/rules/local/` | `.cursor/commands/local/` | `◐` |
| commit | `ai-rizz.skbd` | `.cursor/rules/shared/` | `.cursor/commands/shared/` | `●` |
| global | `~/ai-rizz.skbd` | `~/.cursor/rules/ai-rizz/` | `~/.cursor/commands/ai-rizz/` | `★` |

### Entity Types

- **Rules**: `*.mdc` files - Cursor rule definitions
- **Commands**: `*.md` files - Cursor command definitions
- **Rulesets**: Directories containing rules/commands

### Manifest Format

```
# ai-rizz.skbd
source_repo: <repo-url-or-path>
target_dir: <target-directory>

rules/<rule-name>.mdc
rules/<rule-name>.md
rulesets/<ruleset-name>
```

### Variable Naming Convention

Functions use prefixed local variables to avoid conflicts:
- `cmd_init` uses `ci_` prefix
- `cmd_list` uses `cl_` prefix
- `copy_entry_to_target` uses `cett_` prefix

### Test Infrastructure

- Tests use `setUp()` and `tearDown()` for isolation
- `TEST_DIR` is a temp directory created per test
- `REPO_DIR` points to the test source repository
- `source_ai_rizz()` loads the script with mocked `git_sync()`
- Global mode tests use `TEST_HOME` for isolation

## Key Functions

### Mode Detection
- `is_mode_active(mode)` - Returns "true"/"false"
- `select_mode(mode)` - Smart mode selection with auto-detect

### Entity Handling
- `is_command(filename)` - Returns "true"/"false" for `*.md`
- `get_entity_type(filename)` - Returns "rule" or "command"
- `get_commands_target_dir(mode)` - Mode-specific commands directory

### Path Management
- `init_global_paths()` - Initializes global paths (uses `$HOME`)
- `get_manifest_and_target(mode)` - Returns manifest and target for mode

### Sync Operations
- `sync_manifest_to_directory(manifest, target, mode)` - Syncs entries
- `copy_entry_to_target(entry, target, mode)` - Copies single entry
- `sync_all_modes()` - Orchestrates full sync

## Testing Guidelines

1. Run all tests: `make test`
2. Run single suite: `./tests/unit/test_foo.test.sh`
3. Verbose mode: `VERBOSE_TESTS=true ./tests/unit/test_foo.test.sh`
4. Never test in the project directory (ai-rizz manages itself)

## Dependencies

- POSIX shell utilities: `find`, `grep`, `sed`, `mktemp`, `dirname`, `basename`
- Git (for repository operations)
- No external dependencies required
