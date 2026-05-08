# Commands

## Initialization

```
ai-rizz init [<source_repo>] [-d <target_dir>] [--local|-l|--commit|-c|--global|-g] [-f|--manifest|-s|--skibidi <file>]
```

Sets up one mode in your repository:

- `<source_repo>`: URL of the source git repository
- `-d <target_dir>`: Target directory (default: `.cursor/rules`)
- `--local, -l`: Set up local mode (git-ignored rules)
- `--commit, -c`: Set up commit mode (git-tracked rules)
- `--global, -g`: Set up global mode (rules shared across all repos)
- `-f, --manifest <file>`: Use custom manifest filename instead of default `ai-rizz.skbd`
- `-s, --skibidi <file>`: Alias for `--manifest`

If you don't specify a mode, ai-rizz will ask which you want.

### Examples

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

### `--hook-based-ignore` Local Mode

Some builds of Cursor [ignore all files ignored by git](https://forum.cursor.com/t/cursor-2-1-50-ignores-rules-in-git-info-exclude-on-mac-not-on-windows-wsl/145695/4).
If you find that local rules aren't being applied (quick test: can you [@Mention](https://cursor.com/docs/context/mentions) the files?), you can use:

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

## Adding Rules and Rulesets

```
ai-rizz add rule <rule>... [--local|-l|--commit|-c|--global|-g]
ai-rizz add ruleset <ruleset>... [--local|-l|--commit|-c|--global|-g]
```

```bash
ai-rizz add rule foo.mdc              # Uses your current mode if only one mode active
ai-rizz add rule bar.mdc --local      # Force local (git-ignored)
ai-rizz add rule baz.mdc --commit     # Force commit (git-tracked)
ai-rizz add rule qux.mdc --global     # Force global (all repos)
```

**Note**: Adding to a non-existent mode creates it automatically. Re-adding an existing rule moves it between modes.

## Removing Rules and Rulesets

```
ai-rizz remove rule <rule>...
ai-rizz remove ruleset <ruleset>...
```

```bash
ai-rizz remove rule foo.mdc          # Finds and removes it
ai-rizz remove ruleset code          # Removes entire ruleset
```

## Listing Rules and Rulesets

```
ai-rizz list
```

```
○ available-rule.mdc     # Available but not installed
◐ personal-rule.mdc      # Installed locally (git-ignored)
● team-rule.mdc          # Installed and committed (git-tracked)
★ global-rule.mdc        # Installed globally (all repos)

Available rulesets:
○ shell
  ├── commands
  │   ├── setup.sh
  │   └── cleanup.sh
  ├── bash-style.mdc
  └── posix-style.mdc
```

Note: Rulesets with a `commands/` subdirectory will show the directory expanded in the list output. Commands themselves are copied to `.cursor/commands/` and don't appear separately in the list.

## Synchronizing

```
ai-rizz sync
```

Pulls latest rules from source repository and updates your local copies.

## Deinitializing

```
ai-rizz deinit [--local|-l|--commit|-c|--global|-g|--all|-a] [-y]
```

```bash
ai-rizz deinit --local               # Remove only local rules/setup
ai-rizz deinit --commit              # Remove only committed rules/setup
ai-rizz deinit --global              # Remove only global rules/setup
ai-rizz deinit --all                 # Remove everything
ai-rizz deinit                       # Interactive: ask which to remove
```
