# list

```
ai-rizz list
ai-rizz list -a|--all
```

`ai-rizz list` shows what is installed here: rules, commands, skills, and rulesets, with a glyph for each item's mode. Sections with nothing installed are omitted. If the source catalog has items that are not installed, a single footer reports how many: `N available, not shown`.

`ai-rizz list --all` (or `-a`) shows the full catalog, including uninstalled items (`○`). There is no footer, because nothing is hidden.

## Example Output

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
