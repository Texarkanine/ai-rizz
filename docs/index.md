# ai-rizz

A command-line tool for managing AI rules and rulesets. Pull rules from a source repository and use them:

* Locally only (git-ignored, for personal use)
* Committed (git-tracked, shared with team)
* Globally (shared across all repositories)

Each rule can be handled independently. Rule repositories may also choose to bundle rules into "rulesets" for easier management of related rules.

Check out my rules in [Texarkanine/.cursor-rules](https://github.com/Texarkanine/.cursor-rules.git) for examples.

## Where to next

- [User Guide: Getting Started](user-guide/getting-started.md) — prerequisites, install, first recipes
- [User Guide: Commands](user-guide/commands/index.md) — how to use it
- [Rule Authoring Guide](rule-authoring/index.md) — how to make your own repository of rules for `ai-rizz` to pull from
- [Developer Guide](developer-guide/index.md) — how `ai-rizz` works internally, so you can hack on it
