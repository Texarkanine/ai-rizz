# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)
* Globally (shared across all repositories)

Each rule can be handled independently. Rule repositories may also choose to bundle rules into "rulesets" for easier management of related rules.

Check out my rules in [texarkanine/.cursor-rules](https://github.com/texarkanine/.cursor-rules.git) for examples.


## Usage

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
  sync                     Sync the rules
  help                     Show this help

General options:
  -f, --manifest <file>  Alias for --skibidi
  -s, --skibidi <file>   Use custom manifest filename

Mode options (available for init, add, remove, deinit):
  -c, --commit           Use commit mode (git-tracked, shared with team)
  -l, --local            Use local mode (git-ignored, personal)
  -g, --global           Use global mode (user-wide, ~/.cursor/)

Command-specific options:
  init options:
    -d <target_dir>        Target directory
    --git-exclude-ignore   local mode: use .git/info/exclude (legacy mode)
                           Default is pre-commit hook (recommended for Cursor on Windows)
    --rule-path <path>     Source repository rules path
    --ruleset-path <path>  Source repository rulesets path

  deinit options:
    -y                     Skip confirmation prompts

Modes:
  commit  Rules are git-tracked and shared with other developers.
  local   Rules are git-ignored and only available to you in this repo.
  global  Rules are stored in ~/.cursor/ and available in all repositories.
          Global mode can be used outside of git repositories.

Glyphs in 'list' output:
  ●  Committed (git-tracked in this repository)
  ◐  Local (git-ignored in this repository)
  ★  Global (user-wide, available everywhere)
  ○  Not installed

```

## Where to next

- [Getting Started](getting-started.md) — prerequisites, install, first recipes
- [Advanced Usage](advanced/index.md) — constraints, rulesets with commands, integrity, env vars
- [Developer Guide](developer-guide/index.md) — manifest internals, conflict resolution, testing
