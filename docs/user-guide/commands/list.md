# list

```
ai-rizz list
```

Lists the available rules and rulesets, along with a glyph indicating the installation status of each.

## Example Output

```
$ ai-rizz list
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