# Getting Started

## Prerequisites

- [git](https://git-scm.com/)
- [make](https://www.gnu.org/software/make/)

## Installation

Install the tool:

```
git clone https://github.com/Texarkanine/ai-rizz.git
cd ai-rizz
make install
```

!!! tip
	See [Installation Options](../user-guide/advanced/installation-options.md) for additional options.

## Now Try One Path

After installation, pick exactly one mode to start with. You can add the other modes later.

All examples below use the public reference repo at `Texarkanine/.cursor-rules`. If you use a different source repo, replace the URL and item names with entries from your `ai-rizz list` output.

### Personal Project Rules

If you just want to customize your own workflows, in this one repository, and don't want anyone else to be affected, use `local` mode. This will pull customizations in but ensure they don't get committed:

```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --local
ai-rizz list
ai-rizz add rule git-safety
ai-rizz list
```

### Shared Project Rules

If you want to customize the workflows for everyone who works with this repository, use `commit` mode. This will pull customizations in as normal files under `git` control:

```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --commit
ai-rizz list
ai-rizz add ruleset shell --commit
ai-rizz list
```

### Personal Global Rules

If you want to customize the way AI agents behave on your machine, regardless of which repository you're working with, use `global` mode. This will pull customizations into your home directory. Nothing will get committed to any of your projects' repositories.

```bash
ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --global
ai-rizz list
ai-rizz add ruleset script-it --global
ai-rizz list
```

## Next Steps

- See [Rule Modes](../user-guide/rule-modes.md) for a deeper explanation of how local/commit/global interact.
- See [add / remove](../user-guide/commands/add-remove.md) for mixed-mode workflows (for example: mostly local, with a few commit-shared rules).
TODO: better