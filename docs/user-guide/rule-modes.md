# Rule Modes

## Local mode (`--local`)
- Rules stored in `.cursor/rules/local/`
- Files not committed to git
  - Default: ignored by git (via `.git/info/exclude`)
  - When `init`ialized with `--hook-based-ignore`: Not ignored by git, protected by pre-commit hook (leaves "dirty" git status)
- Personal rules that don't get committed

## Commit mode (`--commit`)
- Rules stored in `.cursor/rules/shared/`
- Files are committed to git
- Other developers get them when they clone/pull

## Global mode (`--global`)
- Rules stored in `~/.cursor/rules/ai-rizz/`
- Available in all repositories on this machine
- Manifest stored at `~/ai-rizz.skbd`

## Status Display

What `ai-rizz list` shows:

- **○** Rule available but not installed
- **◐** Rule installed locally only (git-ignored)
- **●** Rule installed and committed (git-tracked)
- **★** Rule installed globally (all repositories)

## Moving Rules Between Modes

```bash
ai-rizz add rule some-rule.mdc --local    # adds to local mode
ai-rizz add rule some-rule.mdc --commit   # moves to commit mode
```
