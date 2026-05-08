# Progressive Manifest System

ai-rizz uses a dual-manifest system to support per-rule mode selection.

## Manifest Files

**`ai-rizz.skbd`** (Committed Manifest):

- Always git-tracked when it exists
- Contains rules/rulesets intended to be committed
- Located in repository root

**`ai-rizz.local.skbd`** (Local Manifest):

- Automatically added to `.git/info/exclude` (git-ignored) by default
  - When `init`ialized with `--hook-based-ignore`: Not git-ignored, protected by pre-commit hook instead (leaves "dirty" git status)
- Contains rules/rulesets intended to be local-only
- Located in repository root

## Directory Structure

**`.cursor/rules/shared/`** (Committed Directory):

- Always git-tracked when it exists
- Contains rules from committed manifest
- Created when commit mode is initialized

**`.cursor/rules/local/`** (Local Directory):

- Automatically git-ignored via `.git/info/exclude` by default
  - When `init`ialized with `--hook-based-ignore`: Not git-ignored, protected by pre-commit hook (leaves "dirty" git status)
- Contains rules from local manifest
- Created when local mode is initialized

**`~/.cursor/rules/ai-rizz/`** (Global Directory):

- Shared across all repositories
- Contains rules from global manifest (`~/ai-rizz.skbd`)
- Created when global mode is initialized

## Manifest File Schema

Both manifest files use the same format:

```
<source_repo>[TAB]<target_dir>[TAB]<rules_dir>[TAB]<rulesets_dir>
rules/rule1.mdc
rules/rule2.mdc
rulesets/ruleset1
```

- First line: tab-separated values:
    1. source repository URL
    2. target directory in your repository (where ai-rizz will install rules)
    3. rules directory in source repository (where rules are pulled from)
    4. rulesets directory in source repository (where rulesets are pulled from)
- Subsequent lines: installed rules/rulesets (one per line)
- Rule entries: `<rules_dir>/` prefix + filename
- Ruleset entries: `<rulesets_dir>/` prefix + name
