# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them in your working repositories either:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)

Each rule can be handled independently. Rule repositories may also choose to bundle rules into "rulesets" for easier management of related rules.


## Quick Start

### Prerequisites
- git
- tree (optional; makes prettier displays easier)

### Installation
```
git clone https://github.com/yourusername/ai-rizz.git
cd ai-rizz
make install
```

### Common Recipes

**Personal rules only (git-ignored):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
ai-rizz add rule my-personal-rule.mdc
ai-rizz list
```

**Team rules (committed to repo):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --commit
ai-rizz add rule team-shared-rule.mdc
ai-rizz list
```

**Mix of both:**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
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

### Configuration

ai-rizz stores copies of source repositories in `$HOME/.config/ai-rizz/repos/PROJECT-NAME/repo/` where PROJECT-NAME is the current directory name. This allows different projects to use different source repositories without conflicts.

### Rule Modes

#### Local mode (`--local`)
- Rules stored in `.cursor/rules/local/`
- Files ignored by bit
- Personal rules that don't get committed

#### Commit mode (`--commit`)
- Rules stored in `.cursor/rules/shared/`
- Files are committed to git
- Other developers get them when they clone/pull

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

**Local-only setup (git-ignored rules):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
```

**Commit-only setup (git-tracked rules):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --commit
```

#### Adding Rules and Rulesets

```
ai-rizz add rule <rule>... [--local|-l|--commit|-c]
ai-rizz add ruleset <ruleset>... [--local|-l|--commit|-c]
```

```bash
ai-rizz add rule foo.mdc              # Uses your current mode if only one mode active
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

## Advanced Usage

### Rule and Ruleset Constraints

ai-rizz enforces certain constraints to maintain data integrity and prevent conflicts between local and committed modes. Understanding these constraints helps you work effectively with complex rule management scenarios.

#### Example Repository Structure

For the examples below, assume your source repository has this structure:

```
rules/
├── personal-productivity.mdc
├── code-review.mdc
└── documentation.mdc

rulesets/
├── shell/
│   ├── bash-style.mdc
│   ├── posix-style.mdc
│   └── shell-tdd.mdc
└── python/
    ├── pep8-style.mdc
    ├── type-hints.mdc
    └── testing.mdc
```

#### Upgrade/Downgrade Rules

**Upgrade (Individual → Ruleset)**: ✅ Always allowed

*Scenario*: You have `bash-style.mdc` installed individually, then add the `shell` ruleset:

```bash
# Starting state: individual rule installed
ai-rizz add rule bash-style.mdc --local
ai-rizz list
# Shows: ◐ bash-style.mdc

# Add the ruleset containing that rule
ai-rizz add ruleset shell --local
ai-rizz list  
# Shows: ◐ shell (contains bash-style.mdc, posix-style.mdc, shell-tdd.mdc)
# The individual bash-style.mdc entry is automatically removed
```

**Downgrade (Ruleset → Individual)**: ⚠️ Conditionally blocked

*Scenario*: You have the `shell` ruleset committed, then try to add just `bash-style.mdc` locally:

```bash
# Starting state: ruleset committed
ai-rizz add ruleset shell --commit
ai-rizz list
# Shows: ● shell (contains bash-style.mdc, posix-style.mdc, shell-tdd.mdc)

# Try to add individual rule locally - BLOCKED
ai-rizz add rule bash-style.mdc --local
# Error: Cannot add individual rule 'bash-style.mdc' to local mode: 
# it's part of committed ruleset 'rulesets/shell'. 
# Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
```

*Why blocked*: Prevents fragmenting committed rulesets, which could lead to incomplete team configurations.

#### Valid Operations

**Same-mode operations**: ✅ Always allowed
```bash
# Add individual rules from our example repository
ai-rizz add rule personal-productivity.mdc --local    # Add to local mode
ai-rizz add rule code-review.mdc --commit             # Add to commit mode

# Add rulesets from our example repository  
ai-rizz add ruleset python --local                    # Add ruleset to local mode
ai-rizz add ruleset shell --commit                    # Add ruleset to commit mode
```

**Cross-mode migrations**: ✅ Always allowed
```bash
# Moving individual rules between modes
ai-rizz add rule documentation.mdc --local           # Rule in local mode
ai-rizz add rule documentation.mdc --commit          # Now in commit mode

# Moving rulesets between modes
ai-rizz add ruleset python --commit                  # Ruleset in commit mode  
ai-rizz add ruleset python --local                   # Now in local mode
```

**Ruleset upgrades**: ✅ Always allowed
```bash
# Individual rule gets absorbed into ruleset
ai-rizz add rule bash-style.mdc --local              # Individual rule
ai-rizz add ruleset shell --local                    # Ruleset contains bash-style.mdc
# Result: Only the ruleset remains, individual bash-style.mdc entry removed
```

#### Blocked Operations

**Downgrade from committed ruleset**: ❌ Blocked
```bash
# Set up: shell ruleset committed (contains bash-style.mdc, posix-style.mdc, shell-tdd.mdc)
ai-rizz add ruleset shell --commit            
ai-rizz list
# Shows: ● shell

# Try to extract individual rule to local mode - BLOCKED
ai-rizz add rule bash-style.mdc --local       # ❌ BLOCKED
# Error: Cannot add individual rule 'bash-style.mdc' to local mode: 
# it's part of committed ruleset 'rulesets/shell'. 
# Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
```

**Why this is blocked**: Prevents fragmenting committed rulesets, which could lead to:
- Incomplete rulesets in commit mode (team missing some rules)
- Confusion about which rules are shared vs. personal
- Merge conflicts when team members have different rule subsets

#### Workarounds for Complex Scenarios

**Scenario**: You want only `bash-style.mdc` from the committed `shell` ruleset in local mode

**Solution 1**: Move entire ruleset to local mode, then remove unwanted rules
```bash
ai-rizz add ruleset shell --local           # Move whole ruleset to local
ai-rizz remove rule posix-style.mdc         # Remove unwanted rules
ai-rizz remove rule shell-tdd.mdc           # Remove unwanted rules
# Result: Only bash-style.mdc remains in local mode
```

**Solution 2**: Remove ruleset and add individual rules separately
```bash
ai-rizz remove ruleset shell                # Remove committed ruleset
ai-rizz add rule bash-style.mdc --local     # Add desired rule locally
ai-rizz add rule posix-style.mdc --commit   # Re-add others to commit mode
ai-rizz add rule shell-tdd.mdc --commit     # Re-add others to commit mode
```

**Scenario**: Team wants to adopt your local `python` ruleset

**Solution**: Promote local ruleset to commit mode
```bash
ai-rizz add ruleset python --commit         # Moves to commit mode
git add ai-rizz.inf .cursor/rules/shared/   # Stage for commit
git commit -m "Add team Python ruleset"    # Share with team
```

### Repository Integrity

#### Source Repository Consistency
Both modes must use the same source repository. If they differ, `ai-rizz` will complain and ask you to resolve it.

#### Conflict Resolution
When both modes contain the same rule/ruleset:
- **Commit mode wins**: Committed rules take precedence
- **Automatic cleanup**: Conflicting local entries are silently removed

### Best Practices

#### For Individual Contributors
- Start with local mode for experimentation
- Promote stable rules to commit mode for team sharing
- Use rulesets for related rules that should stay together

#### For Teams
- Establish team rulesets in commit mode early
- Avoid fragmenting team rulesets across modes
- Use local mode for personal productivity rules

#### For Rule Authors
- Group related rules into logical rulesets
- Include README.md files in rulesets for documentation
- Use semantic naming for rules and rulesets

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
└── unit/                            # Unit tests
```

#### Running Tests

```bash
# Run all tests (quiet mode - default)
make test

# Run tests with verbose output
VERBOSE_TESTS=true make test

# Run specific test file (quiet)
sh tests/unit/test_progressive_init.sh

# Run specific test file (verbose)
VERBOSE_TESTS=true sh tests/unit/test_progressive_init.sh
```

#### Test Output Modes

**Quiet Mode (Default)**:
- Shows only test names and PASS/FAIL status
- Failed tests automatically re-run with verbose output for debugging
- Provides clean, summary-focused output for CI/CD and regular development

**Verbose Mode**:
- Shows all test setup, execution, and diagnostic information
- Useful for test development and troubleshooting
- Activated with `VERBOSE_TESTS=true`

#### Testing Best Practices

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
