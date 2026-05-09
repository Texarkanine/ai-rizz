# Commands

| Command                          | Subcommand(s)     | Description                                  |
|----------------------------------|-------------------|----------------------------------------------|
| [init](init-deinit.md#init)      |                   | Initialize `ai-rizz` in a repository         |
| [deinit](init-deinit.md#deinit)  |                   | Remove `ai-rizz` from a repository           |
| [add](add-remove.md#adding)      | `rule`, `ruleset` | Add rule(s) to the repository                |
| [remove](add-remove.md#removing) | `rule`, `ruleset` | Remove rule(s) from the repository           |
| [list](list.md)                  |                   | List the available rules and rulesets        |
| [sync](sync.md)                  |                   | Pull updates to the rules and rulesets       |

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
                           Default is pre-commit hook (recommended for Cursor)
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