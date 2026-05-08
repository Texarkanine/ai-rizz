# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)
* Globally (shared across all repositories)

Each rule can be handled independently. Rule repositories may also choose to bundle rules into "rulesets" for easier management of related rules.

Check out my rules in [texarkanine/.cursor-rules](https://github.com/texarkanine/.cursor-rules.git) for examples.

> **📚 Full documentation:** <https://texarkanine.github.io/ai-rizz/>

## Why ai-rizz?

- **One tool, three modes** - keep one-off, personal, or experimental rules local (git-ignored), share project-level rules in commit mode, and reuse a global ruleset across every repo on your machine.
- **Per-rule control** - promote, demote, or move any individual rule between modes with a single command.
- **Rulesets, with commands** - bundle related rules (and Cursor `/commands`) into a ruleset and add the whole thing in one shot.
- **Just a Shell Script** - no node, no npm, no python - if you have a filesystem and a shell, you can use it to manage these *text files*!

## Quick Start

### Prerequisites

- git

### Installation

```bash
git clone https://github.com/texarkanine/ai-rizz.git
cd ai-rizz
make install
```

### First recipe

```bash
# Personal rules only (git-ignored):
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
ai-rizz add rule my-personal-rule.mdc
ai-rizz list
```

Other modes:

```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --commit   # team-shared
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --global   # all repos
```

> ## ⚠️ `.gitignore` and `.cursorignore`
> Some builds of Cursor [ignore all files ignored by git](https://forum.cursor.com/t/cursor-2-1-50-ignores-rules-in-git-info-exclude-on-mac-not-on-windows-wsl/145695/4).
> If your local rules aren't being applied, see the [`--hook-based-ignore` `init` option](https://texarkanine.github.io/ai-rizz/user-guide/commands/#--hook-based-ignore-local-mode) in the docs.

## Learn more

The full documentation lives at **<https://texarkanine.github.io/ai-rizz/>** and covers:

- [Getting Started](https://texarkanine.github.io/ai-rizz/getting-started/) - install, prerequisites, common recipes
- [User Guide](https://texarkanine.github.io/ai-rizz/user-guide/) - configuration, modes, full command reference
- [Advanced Usage](https://texarkanine.github.io/ai-rizz/advanced/) - constraints, rulesets with commands, integrity, env vars
- [Developer Guide](https://texarkanine.github.io/ai-rizz/developer-guide/) - manifest internals, conflict resolution, testing

The docs site is the canonical source; the markdown sources are in [`docs/`](./docs/).
