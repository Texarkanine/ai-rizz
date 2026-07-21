# Rule Modes

## Local mode (`--local`)
- Rules stored in `.cursor/rules/local/`
- Files not committed to git
- Personal rules that don't get committed

## Commit mode (`--commit`)
- Rules stored in `.cursor/rules/shared/`
- Files are committed to git
- Other developers get them when they clone/pull

## Global mode (`--global`)
- Rules stored in `~/.cursor/rules/ai-rizz/`
- Available in all repositories on this machine
- Manifest stored at `~/ai-rizz.skbd`
- Not present in the repository at all

## Choosing a mode

Inside a git repository, unflagged commands auto-select when exactly one of local or commit is initialized. Global is always opt-in: pass `--global` (or set `AI_RIZZ_MODE=global`). If neither local nor commit is initialized, the command errors instead of silently using global.

Outside a git repository, global-only setups auto-select global.

## Status Display

| Symbol | Meaning                                         |
|--------|-------------------------------------------------|
| `○`    | Rule available but not installed                |
| `◐`   | Rule installed locally only (git-ignored)       |
| `●`    | Rule installed and committed (git-tracked)      |
| `★ `  | Rule installed globally (all repositories)      |

## Moving Rules Between Modes

```bash
ai-rizz add rule some-rule.mdc --local    # adds to local mode
ai-rizz add rule some-rule.mdc --commit   # moves to commit mode
```

## See Also

- [Rule and Ruleset Constraints](advanced/constraints.md) - more-advanced interactions between rules, rulesets, and modes.
