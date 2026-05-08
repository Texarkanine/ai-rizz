# Getting Started

This section covers prerequisites, installation, and common recipes for getting started with ai-rizz quickly.

## Prerequisites

- git

## Installation

Install the tool:

```
git clone https://github.com/texarkanine/ai-rizz.git
cd ai-rizz
make install
```

## Common Recipes

Add some rules to your repository:

**Personal rules only (git-ignored):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
ai-rizz add rule my-personal-rule.mdc
ai-rizz list
```

**Team rules (committed to repo):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --commit
ai-rizz add rule team-shared-rule.mdc
ai-rizz list
```

**Mix of both:**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
ai-rizz add rule personal-rule.mdc          # goes to local
ai-rizz add rule shared-rule.mdc --commit   # creates commit mode
ai-rizz list                                # shows: ○ ◐ ●
```

**Global rules (shared across all repos):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --global
ai-rizz add rule always-use-this.mdc --global
ai-rizz list                                # shows: ★ for global rules
```

> ## ⚠️ `.gitignore` and `.cursorignore`
> Some builds of Cursor [ignore all files ignored by git](https://forum.cursor.com/t/cursor-2-1-50-ignores-rules-in-git-info-exclude-on-mac-not-on-windows-wsl/145695/4).
> If you find that local rules aren't being applied (quick test: can you [@Mention](https://cursor.com/docs/context/mentions) the files?), see the [--hook-based-ignore `init` option](#--hook-based-ignore-local-mode).

