# init / deinit

## init

```
ai-rizz init [<source_repo>] [-d <target_dir>] [--local|-l|--commit|-c|--global|-g] [-f|--manifest|-s|--skibidi <file>]
```

Sets up one [mode](../rule-modes.md) in your repository:

| Option / Argument             | Description                                                        |
|------------------------------|--------------------------------------------------------------------|
| `<source_repo>`              | URL of the source git repository                                   |
| `-d <target_dir>`            | Target directory (default: `.cursor/rules`)                        |
| `--local`, `-l`              | Set up local mode (git-ignored rules)                              |
| `--commit`, `-c`             | Set up commit mode (git-tracked rules)                             |
| `--global`, `-g`             | Set up global mode (rules shared across all repos)                 |
| `-f`, `--manifest <file>`    | Use custom manifest filename instead of default `ai-rizz.skbd`     |
| `-s`, `--skibidi <file>`     | Alias for `--manifest`                                             |

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

## deinit

```
ai-rizz deinit [--local|-l|--commit|-c|--global|-g|--all|-a] [-y]
```

| Option / Flag        | Description                               |
|----------------------|-------------------------------------------|
| `--local`, `-l`      | Remove only local rules/setup              |
| `--commit`, `-c`     | Remove only committed rules/setup          |
| `--global`, `-g`     | Remove only global rules/setup             |
| `--all`, `-a`        | Remove everything                          |
| `-y`                 | Automatically confirm without prompting    |
