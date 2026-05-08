# User Guide

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
    -g, --global           Initialize global mode (shared across repos)
    -l, --local            Initialize local mode (git-ignored)
    -s, --skibidi <file>   Use custom manifest filename

  add options:
    -c, --commit           Add to commit mode (auto-initializes if needed)
    -g, --global           Add to global mode (auto-initializes if needed)
    -l, --local            Add to local mode (auto-initializes if needed)

  deinit options:
    -a, --all              Remove all modes completely
    -c, --commit           Remove commit mode only
    -g, --global           Remove global mode only
    -l, --local            Remove local mode only
    -y                     Skip confirmation prompts
```

## In this section

- [Configuration](configuration.md)
- [Rule Modes](rule-modes.md)
- [Installation Options](installation-options.md)
- [Commands](commands.md)
