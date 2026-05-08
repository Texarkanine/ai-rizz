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
    See [Installation Options](advanced/installation-options.md) for additional options.

## TODO:

what now?

---

## Common Recipes

Add some rules to your repository:

**Personal rules only (git-ignored):**
```bash
ai-rizz init https://github.com/texarkanine/.cursor-rules.git --local
ai-rizz add rule my-personal-rule.mdc
ai-rizz list
```

**Project rules (committed to repo):**
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
