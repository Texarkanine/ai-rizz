# list

```
ai-rizz list
ai-rizz list -a|--all
```

`ai-rizz list` shows what is installed here: rules, commands, skills, and rulesets, with a glyph for each item's mode. When **nothing is installed yet**, it automatically shows the full source catalog (same as `--all`) so you can see what is available. Once you have installed something, sections with nothing installed are omitted; if the source catalog still has uninstalled items, a single footer reports how many: `N available, not shown`.

`ai-rizz list --all` (or `-a`) shows the full catalog, including uninstalled items (`○`). There is no footer, because nothing is hidden.

## Example Output

=== "Fresh init"

	```
	$ ai-rizz init https://github.com/Texarkanine/.cursor-rules.git --local
	$ ai-rizz list
	Available rules:
	  ○ bash-style.mdc
	  ○ git-safety.mdc

	Available commands:
	  ○ /niko

	Available rulesets:
	  ○ shell
	    ├── bash-style.mdc
	    └── shell-posix-style.mdc
	```

=== "Installed"

	```
	$ ai-rizz list
	Available rules:
	  ● always-tdd.mdc
	  ● git-safety.mdc
	  ◐ github-open-a-pull-request-gh.mdc

	Available commands:
	  ★ /pr-feedback-judge

	5 available, not shown
	```

=== "Catalog"

	```
	$ ai-rizz list --all
	Available rules:
	  ● always-tdd.mdc
	  ○ bash-style.mdc
	  ○ cursor-conversation-transcript.mdc
	  ○ cursor-create-rule.mdc
	  ● git-safety.mdc
	  ◐ github-open-a-pull-request-gh.mdc

	Available commands:
	  ★ /pr-feedback-judge
	  ○ /wiggum-niko-coderabbit-pr

	Available rulesets:
	  ○ meta
	    ├── conversation-transcript.mdc
	    └── create-cursor-rule.mdc
	```

!!! tip "Glyphs"
    `ai-rizz` uses a [set of glyphs](../rule-modes.md#status-display) to indicate the installed mode of a given rule.
