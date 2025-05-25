# Implementation Phase 0: README Rewrite

## Overview

This document provides a detailed step-by-step implementation plan for Phase 0 of the ai-rizz progressive initialization design. The goal is to update the README.md to accurately reflect the new progressive initialization behavior, moving away from the current single-mode system to the new "Nothing → Local → Committed" progression with lazy initialization.

**Important**: This README update will intentionally conflict with the current system implementation, as it documents the target design rather than current behavior.

## Current README Analysis

### Current Structure
1. **Header & Description** - Single-mode description
2. **Quick Start** - Single-mode examples
3. **User Guide** - Single-mode command documentation
4. **Basic Workflow** - Linear single-mode process
5. **Configuration** - Basic repo location info
6. **Modes** - Two-mode system (but repository-wide)
7. **Installation Options** - (No changes needed)
8. **Commands** - Single-mode command documentation
9. **Developer Guide** - Single manifest schema

### Issues with Current Content
- Describes "two modes" but implies repository-wide selection
- Init examples show mode selection at repository level
- No mention of progressive initialization
- No documentation of lazy initialization
- Single manifest file (`ai-rizz.inf`) documentation
- No mention of dual-mode operations
- Missing three-state glyph system
- No backward compatibility information

## Implementation Plan

### Step 1: Update Header & Description
**Target Section**: Lines 1-8
**Changes Required**:
- Focus on what the tool does, not how it works internally
- Remove feature marketing language
- Show the two primary use cases simply

**New Content**:
```markdown
# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them in your working repositories either:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)

Each rule can be handled independently.
````

### Step 2: Rewrite Quick Start Section
**Target Section**: Lines 10-35
**Changes Required**:
- Focus on practical recipes for common tasks
- Show concrete examples without explaining the magic
- Lead with the most common use case

**New Content**:
````markdown
## Quick Start

Prerequisites:
- git
- POSIX-compatible shell (bash, dash, zsh, etc.)
- Core Unix utilities (find, grep, cat, mktemp, etc.)
- tree (for displaying directory structures)

Installation:
```
git clone https://github.com/yourusername/ai-rizz.git
cd ai-rizz
make install
```

Common recipes:

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
````

### Step 3: Update User Guide Command Syntax
**Target Section**: Lines 37-62
**Changes Required**:
- Add mode flags to `add` commands
- Update `deinit` command with mode selection
- Update `init` command documentation

**New Content**:
````markdown
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
````

### Step 4: Rewrite Basic Workflow Section
**Target Section**: Lines 64-72
**Changes Required**:
- Focus on step-by-step task completion
- Remove conceptual explanations
- Show concrete actions to achieve goals

**New Content**:
````markdown
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
````

### Step 5: Update Modes Section
**Target Section**: Lines 78-82
**Changes Required**:
- Focus on practical differences between modes
- Remove system architecture explanations
- Show what each mode does, not how it works

**New Content**:
````markdown
### Rule Modes

**Local mode** (`--local`):
- Rules stored in `.cursor/rules/local/`
- Git ignores these files automatically
- Personal rules that don't get committed
- Other team members won't see them

**Commit mode** (`--commit`):
- Rules stored in `.cursor/rules/shared/`
- Files are committed to git
- Shared with team
- Other team members get them when they clone/pull

**What `ai-rizz list` shows:**
- **○** Rule available but not installed
- **◐** Rule installed locally only (git-ignored)  
- **●** Rule installed and committed (git-tracked)

**Moving rules between modes:**
```bash
ai-rizz add rule some-rule.mdc --local    # adds to local mode
ai-rizz add rule some-rule.mdc --commit   # moves to commit mode
```
````

### Step 6: Update Commands Section
**Target Section**: Lines 98-180
**Changes Required**:
- Update `init` command to show single-mode setup
- Update `add` commands with mode flags and lazy initialization
- Update `remove` commands with auto-detection
- Update `deinit` command with mode selection
- Add examples of mode transitions

**New Content**:
````markdown
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

**If you have only one mode set up**: 
```bash
ai-rizz add rule foo.mdc              # Uses whatever mode you initialized
```

**If you want to specify the mode**:
```bash
ai-rizz add rule bar.mdc --local      # Local only (git-ignored)
ai-rizz add rule baz.mdc --commit     # Committed (git-tracked)
```

**If you add to a mode you haven't set up yet**:
```bash
# Starting with only local mode
ai-rizz add rule shared.mdc --commit  # Creates commit mode, adds rule there
```

**Moving a rule from one mode to another**:
```bash
ai-rizz add rule existing-rule.mdc --commit  # Moves from local to commit
```

#### Removing Rules and Rulesets

```
ai-rizz remove rule <rule>...
ai-rizz remove ruleset <ruleset>...
```

Removes the rule from whichever mode it's in (local or commit):

```bash
ai-rizz remove rule foo.mdc          # Finds and removes it
ai-rizz remove ruleset code          # Removes entire ruleset
```

#### Listing Rules and Rulesets

```
ai-rizz list
```

Shows what rules are available and their status:

```
○ available-rule.mdc     # Available but not installed
◐ personal-rule.mdc      # Installed locally (git-ignored)
● team-rule.mdc          # Installed and committed (git-tracked)
```

#### Synchronizing

```
ai-rizz sync
```

Pulls latest rules from the source repository and updates your local copies.

#### Deinitializing

```
ai-rizz deinit [--local|-l|--commit|-c|--all|-a] [-y]
```

Remove ai-rizz setup from repository:

```bash
ai-rizz deinit --local               # Remove only local rules/setup
ai-rizz deinit --commit              # Remove only committed rules/setup  
ai-rizz deinit --all                 # Remove everything
ai-rizz deinit                       # Ask which to remove
```

Add `-y` to skip confirmation prompts.
````

### Step 7: Update Developer Guide
**Target Section**: Lines 182-244
**Changes Required**:
- Document dual manifest system
- Update manifest schema
- Add backward compatibility section
- Update testing information for new system

**New Content**:
````markdown
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

### Backward Compatibility

Existing repositories are automatically migrated on first command execution:

#### Local-Mode Repository Migration
**Detection**: `.git/info/exclude` contains `ai-rizz.inf` entry

**Migration Steps**:
1. Rename `ai-rizz.inf` → `ai-rizz.local.inf`
2. Move rules from `.cursor/rules/shared/` → `.cursor/rules/local/`
3. Update `.git/info/exclude` entries
4. Remains local-only (no commit mode created)

#### Commit-Mode Repository Migration
**Detection**: `.git/info/exclude` does NOT contain `ai-rizz.inf` entry

**Migration Steps**:
1. Keep `ai-rizz.inf` unchanged
2. Remains commit-only (no local mode created)

**Key**: Migration preserves single-mode setup; dual-mode only achieved through lazy initialization.

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
```
````

## Implementation Steps Summary

1. **Step 1**: Update header/description (lines 1-8)
2. **Step 2**: Rewrite Quick Start section (lines 10-35)
3. **Step 3**: Update User Guide command syntax (lines 37-62)
4. **Step 4**: Rewrite Basic Workflow section (lines 64-72)
5. **Step 5**: Update Modes section (lines 78-82)
6. **Step 6**: Update Commands section (lines 98-180)
7. **Step 7**: Update Developer Guide (lines 182-244)

## Validation Criteria

After implementation, the README should:
- [ ] Accurately describe progressive initialization ("Nothing → Local → Committed")
- [ ] Document lazy initialization behavior
- [ ] Show per-rule mode selection examples
- [ ] Explain three-state glyph system (○, ◐, ●)
- [ ] Document dual manifest system
- [ ] Include backward compatibility information
- [ ] Show mode-specific command examples
- [ ] Explain conflict resolution behavior
- [ ] Reference future test structure

## Expected Conflicts

This README update will be **intentionally inconsistent** with the current implementation:
- Commands will show mode flags not yet implemented
- Examples will demonstrate lazy initialization not yet coded
- Manifest schema describes dual-file system not yet built
- Migration behavior documents future functionality

**This is acceptable and expected** - the README serves as the specification for the new system to be implemented in subsequent phases. 