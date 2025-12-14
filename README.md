# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them in your working repositories either:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)

Each rule can be handled independently. Rule repositories may also choose to bundle rules into "rulesets" for easier management of related rules.

Check out my rules in [texarkanine/.cursor-rules](https://github.com/texarkanine/.cursor-rules.git) for examples.

## Table of Contents

- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Common Recipes](#common-recipes)
- [User Guide](#user-guide)
  - [Configuration](#configuration)
  - [Rule Modes](#rule-modes)
  - [Installation Options](#installation-options)
  - [Commands](#commands)
- [Advanced Usage](#advanced-usage)
  - [Rule and Ruleset Constraints](#rule-and-ruleset-constraints)
  - [Rulesets with Commands](#rulesets-with-commands)
  - [Repository Integrity](#repository-integrity)
  - [Environment Variable Fallbacks](#environment-variable-fallbacks)
- [Developer Guide](#developer-guide)
  - [Progressive Manifest System](#progressive-manifest-system)
  - [Testing](#testing)

## Quick Start

### Prerequisites
- git
- tree (optional; makes prettier displays easier)

### Installation

Install the tool:

```
git clone https://github.com/texarkanine/ai-rizz.git
cd ai-rizz
make install
```

### Common Recipes

Add some rules to your repository:

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

> ## ⚠️ `.gitignore` and `.cursorignore`
> Some builds of Cursor [ignore all files ignored by git](https://forum.cursor.com/t/cursor-2-1-50-ignores-rules-in-git-info-exclude-on-mac-not-on-windows-wsl/145695/4).
> If you find that local rules aren't being applied (quick test: can you [@Mention](https://cursor.com/docs/context/mentions) the files?), see the [--hook-based-ignore `init` option](#--hook-based-ignore-local-mode).

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
    -c, --commit           Initialize commit mode (git-tracked)
    -d <target_dir>        Target directory (default: .cursor/rules)
    -f, --manifest <file>  Alias for --skibidi
    -l, --local            Initialize local mode (git-ignored)
    -s, --skibidi <file>   Use custom manifest filename

  add options:
    -c, --commit           Add to commit mode (auto-initializes if needed)
    -l, --local            Add to local mode (auto-initializes if needed)

  deinit options:
    -a, --all              Remove both modes completely
    -c, --commit           Remove commit mode only
    -l, --local            Remove local mode only
    -y                     Skip confirmation prompts
```

### Configuration

ai-rizz stores copies of source repositories in `$HOME/.config/ai-rizz/repos/PROJECT-NAME/repo/` where PROJECT-NAME is the current directory name. This allows different projects to use different source repositories without conflicts.

### Rule Modes

#### Local mode (`--local`)
- Rules stored in `.cursor/rules/local/`
- Files not committed to git
  - Default: ignored by git (via `.git/info/exclude`)
  - When `init`ialized with `--hook-based-ignore`: Not ignored by git, protected by pre-commit hook (leaves "dirty" git status)
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
ai-rizz init [<source_repo>] [-d <target_dir>] [--local|-l|--commit|-c] [-f|--manifest|-s|--skibidi <file>]
```

Sets up one mode in your repository:

- `<source_repo>`: URL of the source git repository
- `-d <target_dir>`: Target directory (default: `.cursor/rules`)
- `--local, -l`: Set up local mode (git-ignored rules)
- `--commit, -c`: Set up commit mode (git-tracked rules)
- `-f, --manifest <file>`: Use custom manifest filename instead of default ai-rizz.skbd
- `-s, --skibidi <file>`: Alias for --manifest

If you don't specify `--local` or `--commit`, ai-rizz will ask which you want.

Examples:

**Local-only setup (git-ignored rules):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
```

**Local mode with hook-based ignore:**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local --hook-based-ignore
```
Note: This leaves files untracked (visible in `git status`) but prevents them from being committed.

**Commit-only setup (git-tracked rules):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --commit
```

**Custom manifest filename:**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local -f cursor-rules.conf
```

##### --hook-based-ignore Local Mode

Some builds of Cursor [ignore all files ignored by git](https://forum.cursor.com/t/cursor-2-1-50-ignores-rules-in-git-info-exclude-on-mac-not-on-windows-wsl/145695/4).
If you find that local rules aren't being applied (quick test: can you [@Mention](https://cursor.com/docs/context/mentions) the files?), you can use 

```bash
ai-rizz init --local --hook-based-ignore
```

When `init`ialized with `--hook-based-ignore`, local mode files will not be ignored by git.
Instead, a pre-commit hook will strip them from every commit so they remain visible but un-committed.
This will ensure that Cursor indexes, and your Agents can see, the rules.
However, `git status` will always show untracked files:

```
$ git status
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        .cursor/rules/local/
        ai-rizz.local.skbd
```

If you have any local tooling that tries to get a clean `git status`, this may cause a conflict.
Sorry! You'll have to wait until Cursor updates to offer an alternative.

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

Available rulesets:
○ shell
  ├── commands
  │   ├── setup.sh
  │   └── cleanup.sh
  ├── bash-style.mdc
  └── posix-style.mdc
```

Note: Rulesets with a `commands/` subdirectory will show the directory expanded in the list output. Commands themselves are copied to `.cursor/commands/` and don't appear separately in the list.

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
git add ai-rizz.skbd .cursor/rules/shared/   # Stage for commit
git commit -m "Add team Python ruleset"    # Share with team
```

### Ruleset-Local Rules

Rulesets may contain `.mdc` *files* in addition to symlinks to rules in the `rules/` directory.

Such "ruleset-local rules" will

1. be installed alongside symlinked rules normally
2. show up in `ai-rizz list` output as part of the ruleset
3. **not** show up in `ai-rizz` "rules" list
4. **not** be able to be installed or removed individually

### Rulesets with Commands

Rulesets can include a special `commands/` subdirectory that contains [Cursor Command](https://cursor.com/docs/agent/chat/commands) files. These commands are automatically copied to `.cursor/commands/` when the ruleset is added in commit mode.

**Commands must be committed**: Rulesets containing a `commands/` subdirectory can only be added in commit mode. Attempting to add them in local mode will result in an error.
#### Example Workflow

```bash
# Attempting to add a ruleset with commands in local mode
ai-rizz init https://github.com/example/rules.git --local
ai-rizz add ruleset memory-bank
# Error: Ruleset 'memory-bank' contains a 'commands' subdirectory 
# and must be added in commit mode.

# Correct approach: use commit mode
ai-rizz init https://github.com/example/rules.git --commit
ai-rizz add ruleset memory-bank --commit
# Success! Commands from rulesets/memory-bank/commands/* 
# are now in .cursor/commands/
```

#### Source Repository Structure

For a ruleset with commands, your source repository would have this structure:

```
rulesets/
└── memory-bank/
    ├── commands/
    │   ├── van.md
    │   ├── plan.md
    │   └── build.md
    ├── rule1.mdc
    └── rule2.mdc
```

When added in commit mode:
- Rules (`rule1.mdc`, `rule2.mdc`) are copied to `.cursor/rules/shared/`
- Commands (`van.md`, `plan.md`, `build.md`) are copied to `.cursor/commands/`

#### Error Message and Resolution

If you attempt to add a ruleset with commands in local mode, you'll see:

```
Error: Ruleset 'memory-bank' contains a 'commands' subdirectory and must be added in commit mode.

Rulesets with commands must be committed to the repository to ensure commands are version-controlled.

To fix this:
  1. If you haven't initialized commit mode yet:
     ai-rizz init <repository-url> --commit
  
  2. If you already have local mode initialized:
     ai-rizz init <repository-url> --commit
  
Then add the ruleset:
  ai-rizz add ruleset memory-bank --commit
```

### Repository Integrity

#### Source Repository Consistency
Both modes must use the same source repository. If they differ, `ai-rizz` will complain and ask you to resolve it.

#### Conflict Resolution
When both modes contain the same rule/ruleset:
- **Commit mode wins**: Committed rules take precedence
- **Automatic cleanup**: Conflicting local entries are silently removed

### Environment Variable Fallbacks

ai-rizz supports environment variables as fallbacks for CLI arguments. This allows you to set default values for commonly used options without having to specify them on the command line each time.

#### Available Environment Variables

| Environment Variable | CLI Equivalent | Description |
|---------------------|----------------|-------------|
| `AI_RIZZ_MANIFEST` | `--manifest`/`--skibidi` | Custom manifest filename |
| `AI_RIZZ_SOURCE_REPO` | `<source_repo>` | Repository URL for rules source |
| `AI_RIZZ_TARGET_DIR` | `-d <target_dir>` | Target directory for rules |
| `AI_RIZZ_RULE_PATH` | `--rule-path <path>` | Path to rules in source repo |
| `AI_RIZZ_RULESET_PATH` | `--ruleset-path <path>` | Path to rulesets in source repo |
| `AI_RIZZ_MODE` | `--local`/`--commit` | Default mode for operations |

#### Precedence Rules

The precedence order for option values is:
1. CLI arguments (highest priority)
2. Environment variables 
3. Default values or interactive prompts (lowest priority)

If an environment variable is empty, it is ignored and ai-rizz falls back to defaults or prompts.

#### Usage Examples

**Setting Default Repository**

Set a default repository URL for init:

```bash
export AI_RIZZ_SOURCE_REPO="https://github.com/example/rules.git"
ai-rizz init --local  # Uses the repo URL from environment
```

**Custom Manifest Name**

Set a custom manifest filename:

```bash
export AI_RIZZ_MANIFEST="cursor-rules.conf"
ai-rizz init https://github.com/example/rules.git --local
# Creates cursor-rules.conf and cursor-rules.local.conf
```

## Developer Guide

### Progressive Manifest System

ai-rizz uses a dual-manifest system to support per-rule mode selection:

#### Manifest Files

**`ai-rizz.skbd`** (Committed Manifest):
- Always git-tracked when it exists
- Contains rules/rulesets intended to be committed
- Located in repository root

**`ai-rizz.local.skbd`** (Local Manifest):
- Automatically added to `.git/info/exclude` (git-ignored) by default
  - When `init`ialized with `--hook-based-ignore`: Not git-ignored, protected by pre-commit hook instead (leaves "dirty" git status)
- Contains rules/rulesets intended to be local-only
- Located in repository root

#### Directory Structure

**`.cursor/rules/shared/`** (Committed Directory):
- Always git-tracked when it exists
- Contains rules from committed manifest
- Created when commit mode is initialized

**`.cursor/rules/local/`** (Local Directory):
- Automatically git-ignored via `.git/info/exclude` by default
  - When `init`ialized with `--hook-based-ignore`: Not git-ignored, protected by pre-commit hook (leaves "dirty" git status)
- Contains rules from local manifest
- Created when local mode is initialized

#### Manifest File Schema

Both manifest files use the same format:

```
<source_repo>[TAB]<target_dir>[TAB]<rules_dir>[TAB]<rulesets_dir>
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

- First line: tab-separated values:
  1. source repository URL
  2. target directory in your repository (where ai-rizz will install rules)
  3. rules directory in source repository (where rules are pulled from)
  4. rulesets directory in source repository (where rulesets are pulled from)
- Subsequent lines: installed rules/rulesets (one per line)
- Rule entries: `<rules_dir>/` prefix + filename
- Ruleset entries: `<rulesets_dir>/` prefix + name

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
├── integration/                     # Integration tests (against CLI interface)
└── unit/                            # Unit tests (against functions)
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
