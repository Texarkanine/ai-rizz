# add / remove

## Adding

If you only have one [mode](../rule-modes.md) active, and you do not specify a mode when adding a rule or ruleset, they will be added to the one initialized mode.

Otherwise, you must specify a mode.

Adding to a non-existent mode creates it automatically.

Re-adding an existing rule moves it between modes if necessary.

### add rule

```
ai-rizz add rule <rule>... [--local|-l|--commit|-c|--global|-g]
```

```bash
ai-rizz add rule foo.mdc              # Uses your current mode if only one mode active
ai-rizz add rule bar.mdc --local      # Force local (git-ignored)
ai-rizz add rule baz.mdc --commit     # Force commit (git-tracked)
ai-rizz add rule qux.mdc --global     # Force global (all repos)
```

### add ruleset

```bash
ai-rizz add ruleset <ruleset>... [--local|-l|--commit|-c|--global|-g]
```

## Removing

```
ai-rizz remove rule <rule>...
ai-rizz remove ruleset <ruleset>...
```

```bash
ai-rizz remove rule foo.mdc          # Finds and removes it
ai-rizz remove ruleset code          # Removes entire ruleset
```

### remove rule

### remove ruleset
