# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them in your working repositories either:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)

Each rule can be handled independently.


## Quick Start

### Prerequisites
- git
- POSIX-compatible shell (bash, dash, zsh, etc.)
- Core Unix utilities (find, grep, cat, mktemp, etc.)
- tree (for displaying directory structures)

### Installation
```
git clone https://github.com/yourusername/ai-rizz.git
cd ai-rizz
make install
```

### Common Recipes

**Personal rules only (git-ignored):**
```bash
ai-rizz init https://github.com/example/rules.git --local
ai-rizz add rule my-personal-rule.mdc
ai-rizz list
```

**Team rules (committed to repo):**
```bash
ai-rizz init https://github.com/example/rules.git --commit
ai-rizz add rule team-shared-rule.mdc
ai-rizz list
```

**Mix of both:**
```bash
ai-rizz init https://github.com/example/rules.git --local
ai-rizz add rule personal-rule.mdc          # goes to local
ai-rizz add rule shared-rule.mdc --commit   # creates commit mode
ai-rizz list                                # shows: ○ ◐ ●
```

## User Guide

```
Usage: ai-rizz <command> [command-specific options]

Available commands:
  init [<source_repo>]     Initialize one mode in the repository
  deinit                   Deinitialize mode(s) from the repository
  list                     List available rules/rulesets with status
  add rule <rule>...       Add rule(s) to the repository
  add ruleset <ruleset>... Add ruleset(s) to the repository
  remove rule <rule>...    Remove rule(s) from the repository
  remove ruleset <ruleset>... Remove ruleset(s) from the repository
  sync                     Sync all initialized modes
  help                     Show this help

Command-specific options:
  init options:
    -d <target_dir>        Target directory (default: .cursor/rules)
    --local, -l            Initialize local mode (git-ignored)
    --commit, -c           Initialize commit mode (git-tracked)

  add options:
    --local, -l            Add to local mode (auto-initializes if needed)
    --commit, -c           Add to commit mode (auto-initializes if needed)

  deinit options:
    --local, -l            Remove local mode only
    --commit, -c           Remove commit mode only
    --all, -a              Remove both modes completely
    -y                     Skip confirmation prompts
```

### Basic Workflows

**Set up personal rules (won't be committed):**
1. `cd` into your repository
2. `ai-rizz init https://github.com/you/your-rules.git --local`
3. `ai-rizz add rule personal-rule.mdc`
4. `ai-rizz list` to see what's available

**Set up team rules (will be committed):**
1. `cd` into your repository  
2. `ai-rizz init https://github.com/you/your-rules.git --commit`
3. `ai-rizz add rule team-rule.mdc`
4. `git add` and `git commit` the results

**Add team rules to personal setup:**
1. (Starting with local setup above)
2. `ai-rizz add rule shared-rule.mdc --commit`
3. `git add` and `git commit` the new shared rule
4. `ai-rizz list` now shows both types: ◐ (local) ● (committed)

### Configuration

ai-rizz stores copies of source repositories in `$HOME/.config/ai-rizz/repos/PROJECT-NAME/repo/` where PROJECT-NAME is the current directory name. This allows different projects to use different source repositories without conflicts.

### Rule Modes

#### Local mode (`--local`)
- Rules stored in `.cursor/rules/local/`
- Git ignores these files automatically
- Personal rules that don't get committed
- Other team members won't see them

#### Commit mode (`--commit`)
- Rules stored in `.cursor/rules/shared/`
- Files are committed to git
- Shared with team
- Other team members get them when they clone/pull

#### Status Display
What `ai-rizz list` shows:
- **○** Rule available but not installed
- **◐** Rule installed locally only (git-ignored)  
- **●** Rule installed and committed (git-tracked)

#### Moving Rules Between Modes
```bash
ai-rizz add rule some-rule.mdc --local    # adds to local mode
ai-rizz add rule some-rule.mdc --commit   # moves to commit mode
```

### Installation Options

Install to the default location (/usr/local/bin):
```
make install
```

Install to a custom location:
```
make PREFIX=~/local install    # installs to ~/local/bin
```

Uninstall:
```
make uninstall
```

### Commands

#### Initialization

```
ai-rizz init [<source_repo>] [-d <target_dir>] [--local|-l|--commit|-c]
```

Sets up one mode in your repository:

- `<source_repo>`: URL of the source git repository
- `-d <target_dir>`: Target directory (default: `.cursor/rules`)
- `--local, -l`: Set up local mode (git-ignored rules)
- `--commit, -c`: Set up commit mode (git-tracked rules)

If you don't specify `--local` or `--commit`, ai-rizz will ask which you want.

Examples:

Local-only setup (git-ignored rules):
```bash
ai-rizz init https://github.com/example/rules.git --local
```

Commit-only setup (git-tracked rules):
```bash
ai-rizz init https://github.com/example/rules.git --commit
```

#### Adding Rules and Rulesets

```
ai-rizz add rule <rule>... [--local|-l|--commit|-c]
ai-rizz add ruleset <ruleset>... [--local|-l|--commit|-c]
```

```bash
ai-rizz add rule foo.mdc              # Uses your current mode
ai-rizz add rule bar.mdc --local      # Force local (git-ignored)
ai-rizz add rule baz.mdc --commit     # Force commit (git-tracked)
```

**Note**: Adding to a non-existent mode creates it automatically. Re-adding an existing rule moves it between modes.

#### Removing Rules and Rulesets

```
ai-rizz remove rule <rule>...
ai-rizz remove ruleset <ruleset>...
```

```bash
ai-rizz remove rule foo.mdc          # Finds and removes it
ai-rizz remove ruleset code          # Removes entire ruleset
```

#### Listing Rules and Rulesets

```
ai-rizz list
```

```
○ available-rule.mdc     # Available but not installed
◐ personal-rule.mdc      # Installed locally (git-ignored)
● team-rule.mdc          # Installed and committed (git-tracked)
```

#### Synchronizing

```
ai-rizz sync
```

Pulls latest rules from source repository and updates your local copies.

#### Deinitializing

```
ai-rizz deinit [--local|-l|--commit|-c|--all|-a] [-y]
```

```bash
ai-rizz deinit --local               # Remove only local rules/setup
ai-rizz deinit --commit              # Remove only committed rules/setup  
ai-rizz deinit --all                 # Remove everything
ai-rizz deinit                       # Interactive: ask which to remove
```

## Developer Guide

### Progressive Manifest System

ai-rizz uses a dual-manifest system to support per-rule mode selection:

#### Manifest Files

**`ai-rizz.inf`** (Committed Manifest):
- Always git-tracked when it exists
- Contains rules/rulesets intended to be committed
- Located in repository root

**`ai-rizz.local.inf`** (Local Manifest):
- Automatically added to `.git/info/exclude` (git-ignored)
- Contains rules/rulesets intended to be local-only
- Located in repository root

#### Directory Structure

**`.cursor/rules/shared/`** (Committed Directory):
- Always git-tracked when it exists
- Contains rules from committed manifest
- Created when commit mode is initialized

**`.cursor/rules/local/`** (Local Directory):
- Automatically git-ignored via `.git/info/exclude`
- Contains rules from local manifest
- Created when local mode is initialized

#### Manifest File Schema

Both manifest files use the same format:

```
<source_repo>[TAB]<target_dir>
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

- First line: source repository URL and target directory (tab-separated)
- Subsequent lines: installed rules/rulesets (one per line)
- Rule entries: `rules/` prefix + filename
- Ruleset entries: `rulesets/` prefix + name

### Conflict Resolution

#### Rule Mode Conflicts
When a rule exists in one mode and user adds it to another:
1. Rule is moved from current mode to target mode
2. Immediate sync updates file locations and git tracking
3. For rulesets: all constituent rules move together

#### Duplicate Entries
If manual editing creates duplicates in both manifests:
1. Committed mode takes precedence
2. Local entry silently removed during sync
3. No warning shown (automatic cleanup)

### Testing

The project uses [shunit2](https://github.com/kward/shunit2) for unit and integration testing.

#### Test Structure
```
tests/
├── common.sh                        # Common test utilities and helper functions  
├── run_tests.sh                     # Test runner script
├── unit/
│   ├── test_progressive_init.sh        # Single-mode initialization
│   ├── test_lazy_initialization.sh     # Auto-mode-creation logic
│   ├── test_mode_detection.sh          # Mode state detection
│   ├── test_mode_operations.sh         # Add/remove with mode detection
│   ├── test_conflict_resolution.sh     # Conflict resolution
│   ├── test_migration.sh               # Legacy repository migration
│   └── test_error_handling.sh          # Error cases and edge conditions
└── integration/
    ├── test_complete_workflows.sh      # End-to-end scenarios
    ├── test_backward_compat.sh         # Migration scenarios
    └── test_progressive_usage.sh       # Progressive workflows
```

#### Running Tests
```bash
# Run all tests
make test

# Run specific test file
sh tests/unit/test_progressive_init.sh
```
