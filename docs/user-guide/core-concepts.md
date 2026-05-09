# Core Concepts

## What is a Rule?

A "Rule" is a unit of AI Agent customization. It could be any of the following:

- Cursor Rule
- Cursor Slash Command
- Cursor Skill

## What is a Ruleset?

A "Ruleset" is a collection of rules. Rulesets group related rules together so they can be installed and managed as a single unit.

## What is a Mode?

A "Mode" is the way that a rule or ruleset is installed:

- Local (in the repo directory, ignored by git)
- Commit (in the repo directory, committed to git)
- Global (in the home directory, shared across all repos)

See [Rule Modes](rule-modes.md) for more details.

## Hook-Based Git Ignore

Cursor ignores files that are ignored by git. They are not indexed, they are not `@mention`-able via context pills, and they are mostly invisible to the Agents. [This is a flawed design](https://blog.cani.ne.jp/2026/02/22/gitignore-is-not-agentignore.html) and means we cannot just use `.gitignore` to add rules in `local` mode.

To solve this, `ai-rizz` installs a [git pre-commit hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) to strip local rules from every commit. This means that local rules are visible to the Agents, but not committed to the repository. It also means your `git status` will be perpetually "dirty" if you use any local configuration:

```
$ git st
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        .cursor/rules/local/
        ai-rizz.local.skbd

nothing added to commit but untracked files present (use "git add" to track)
```

In my experience, most coding agents correctly ignore these - but if you have any tooling that's strict about requiring a clean `git status`, it might cause a conflict.

!!! tip "No Cursor? No Hook!"
    If you are using a harness that does *not* map all git-ignored files to agent-ignored files - such as Claude Code - you can initialize with `--git-exclude-ignore`, e.g.
    ```bash
    ai-rizz init --local --git-exclude-ignore
    ```

    this will use the [.git/info/exclude file](https://git-scm.com/docs/gitignore#_gitignore) to ignore local rules. This will allow you to have a clean `git status` even with rules installed in `local` mode.
