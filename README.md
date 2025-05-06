# ai-rizz

A command-line tool for managing AI rules and rulesets. Lets you pull rules from one source repository into your working repositories in one of two modes:

* invisibly, ignored by git
* visibly, committed to the repo


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

Basic usage:
```
# Initialize with a rules repository
ai-rizz init https://github.com/example/rules.git --local

# List available rules
ai-rizz list

# Add a ruleset
ai-rizz add ruleset code

# Sync with the source repository
ai-rizz sync
```

## User Guide

```
Usage: ai-rizz <command> [command-specific options]

Available commands:
  init [<source_repo>]     Initialize the repository
  deinit                   Deinitialize the repository
  list                     List available rules and rulesets
  add rule <rule>...       Add rule(s) to the repository
  add ruleset <ruleset>... Add ruleset(s) to the repository
  remove rule <rule>...    Remove rule(s) from the repository
  remove ruleset <ruleset>... Remove ruleset(s) from the repository
  sync                     Sync the repository
  help                     Show this help

Command-specific options:
  init options:
    -d <target_dir>        Target directory (default: .cursor/rules)
    --local, -l            Use local mode (ignore files)
    --commit, -c           Use commit mode (commit files)

  deinit options:
    -y                     Skip confirmation prompts
```

### Basic Workflow

1. `cd` into some repository
2. `ai-rizz init https://github.com/you/your-rules.git ...`
3. `ai-rizz list`
4. `ai-rizz add rule ...`
5. `ai-rizz add ruleset ...`
6. Now you have populated "some repository" with rules for AI
7. Develop!

### Configuration

ai-rizz stores a permanent copy of the source repository in `$HOME/.config/ai-rizz/repo`.

### Modes

ai-rizz operates in two modes:

- **Local mode**: Rules files are excluded from git tracking via `.git/info/exclude`
- **Commit mode**: Rules files are committed to the repository

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

- `<source_repo>`: URL of the source git repository
- `-d <target_dir>`: Target directory (default: `.cursor/rules`)
- `--local, -l`: Use local mode (ignore files)
- `--commit, -c`: Use commit mode (commit files)

Example:

Enable pulling rules from `github.com/example/rules.git`, stored in `.cursor/rules`, and ignored by the local repo's git
People won't see the rules in your commits, and anybody who clones your repo won't see the rules, either.

```
ai-rizz init https://github.com/example/rules.git -d .cursor/rules --local
```

Enable pulling rules from `github.com/example/rules.git`, stored in `.cursor/rules`, and committed to the repo.
People WILL see the rules in your commits, and anyone who clones your repo will get them, too:

```
ai-rizz init https://github.com/example/rules.git -d .cursor/rules --commit
```

#### Listing Rules and Rulesets

```
ai-rizz list
```

Shows available rules and rulesets, and which ones are installed.

#### Adding Rules and Rulesets

```
ai-rizz add rule <rule>...
ai-rizz add ruleset <ruleset>...
```

Example:
```
ai-rizz add rule foo.mdc bar.mdc
ai-rizz add ruleset code giant
```

#### Removing Rules and Rulesets

```
ai-rizz remove rule <rule>...
ai-rizz remove ruleset <ruleset>...
```

Example:
```
ai-rizz remove rule foo.mdc
ai-rizz remove ruleset code
```

#### Synchronizing

```
ai-rizz sync
```

Updates the local copy of the source repository and syncs all rules.

#### Deinitializing

```
ai-rizz deinit [-y]
```

- `-y`: Skip confirmation prompt

Removes the target directory and manifest file.

## Developer Guide

### Makefile

The project includes a simple Makefile for installation and uninstallation. The Makefile supports:

- Installation with customizable prefix: `make PREFIX=/custom/path install`
- Uninstallation: `make uninstall`
- Help: `make help`

### License

MIT 