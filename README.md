# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)
* Globally (shared across all repositories)

Each rule can be handled independently. Rule repositories may also choose to bundle rules into "rulesets" for easier management of related rules.

Check out my rules in [Texarkanine/.cursor-rules](https://github.com/Texarkanine/.cursor-rules.git) for examples.

> **📚 Full documentation:** <https://texarkanine.github.io/ai-rizz/>

## Why ai-rizz?

- **One tool, three modes** - keep one-off, personal, or experimental rules local (git-ignored), share project-level rules in commit mode, and reuse a global ruleset across every repo on your machine.
- **Per-rule control** - promote, demote, or move any individual rule between modes with a single command.
- **Rulesets, with commands** - bundle related rules (and Cursor `/commands`) into a ruleset and add the whole thing in one shot.
- **Just a Shell Script** - no node, no npm, no python - if you have a filesystem and a shell, you can use it to manage these *text files*!

## Quick Start

- [Getting Started](https://texarkanine.github.io/ai-rizz/user-guide/getting-started/) - install, prerequisites, common recipes

## Learn more

The full documentation lives at **<https://texarkanine.github.io/ai-rizz/>** and covers:

- [User Guide](https://texarkanine.github.io/ai-rizz/user-guide/) - configuration, modes, full command reference
- [Rule Authoring Guide](https://texarkanine.github.io/ai-rizz/rule-authoring/) - how to make your own repository of rules for `ai-rizz` to pull from
- [Developer Guide](https://texarkanine.github.io/ai-rizz/developer-guide/) - manifest internals, conflict resolution, testing
