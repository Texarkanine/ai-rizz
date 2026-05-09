# Manifest Files

`ai-rizz` uses a dual-manifest system to support per-rule mode selection within a repository.

**Global** mode installations are supported by a third manifest file, located in the user's home directory.

## Locations

### Commit Mode

`./ai-rizz.skbd`

- Always git-tracked when it exists
- Contains rules/rulesets intended to be committed
- Located in repository root

### Local Mode

`./ai-rizz.local.skbd`

- Not committed to git
- Contains rules/rulesets intended to be local-only
- Located in repository root

### Global Mode

`~/ai-rizz.skbd`

- Contains rules/rulesets intended to be globally available
- Located in user's home directory

## Schema

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
