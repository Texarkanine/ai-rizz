# Rule Authoring Guide

If you want to *write* rules for AI harnesses in a way that `ai-rizz` can understand and deploy, this section is for you.

## Rule Repositories

`ai-rizz` expects to be pointed to a git repository that contains at least two directories, one for [rules](rules.md) and one for [rulesets](rulesets.md).

Normally, you'll call these `rules` and `rulesets`, respectively:

```
$ tree -L 1
.
├── rules
└── rulesets
```

However, you can configure these paths when you [initialize `ai-rizz`](../user-guide/commands/init-deinit.md) with `--rule-path` and `--ruleset-path` or the `AI_RIZZ_RULE_PATH` and `AI_RIZZ_RULESET_PATH` [environment variables](../user-guide/advanced/environment-variables.md).

See [Texarkanine/.cursor-rules](https://github.com/Texarkanine/.cursor-rules.git) for a reference example.
