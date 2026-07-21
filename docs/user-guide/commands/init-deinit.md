# init / deinit

## init

```
ai-rizz init [<source_repo>] [-d <target_dir>] [--local|-l|--commit|-c|--global|-g] [-f|--manifest|-s|--skibidi <file>] [--git-exclude-ignore] [--hook-based-ignore] [--rule-path <path>] [--ruleset-path <path>]
```

Sets up one [mode](../rule-modes.md) in your repository:

| Option / Argument                    | Required? | Description                                                        |
|--------------------------------------|-----------|--------------------------------------------------------------------|
| `<source_repo>`                      | ✅       | URL of the source git repository                                   |
| `-d <target_dir>`                    |           | Target directory (default: `.cursor/rules`)                        |
| `--local` <br> `-l`                  |           | Set up local mode (git-ignored rules)                              |
| `--commit` <br> `-c`                 |           | Set up commit mode (git-tracked rules)                             |
| `--global` <br> `-g`                 |           | Set up global mode (rules shared across all repos)                 |
| `-f <file>` <br> `--manifest <file>` |           | Use custom manifest filename instead of default `ai-rizz.skbd`     |
| `-s <file>` <br> `--skibidi <file>`  |           | Alias for `--manifest`                                             |
| `--git-exclude-ignore`               |           | Local mode: use `.git/info/exclude` ignore behavior (legacy mode)  |
| `--rule-path <path>`                 |           | Path in source repository for standalone rules                     |
| `--ruleset-path <path>`              |           | Path in source repository for rulesets                             |

If you don't specify a mode, ai-rizz will ask which you want.

### Examples

**Local-only setup (git-ignored rules):**
```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --local
```

**Local mode with hook-based ignore:**
```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --local --hook-based-ignore
```
Note: This leaves files untracked (visible in `git status`) but prevents them from being committed.

**Commit-only setup (git-tracked rules):**
```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --commit
```

**Custom manifest filename:**
```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --local -f cursor-rules.conf
```

## deinit

```
ai-rizz deinit [--local|-l|--commit|-c|--global|-g|--both|-b] [-y]
```

| Option / Flag        | Description                               |
|----------------------|-------------------------------------------|
| `--local`, `-l`      | Remove only local rules/setup              |
| `--commit`, `-c`     | Remove only committed rules/setup          |
| `--global`, `-g`     | Remove only global rules/setup             |
| `--both`, `-b`       | Remove local and commit only (not global)  |
| `-y`                 | Automatically confirm without prompting    |
