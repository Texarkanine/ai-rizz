# Rules

`ai-rizz` is built with [Cursor](https://cursor.com) in mind, and recognizes the following kinds of AI agent customizations:

## Agent Skills

[Agent Skills](https://agentskills.io) are an open standard that [Cursor supports](https://cursor.com/docs/skills).

They are a folder with a `SKILL.md` file in it, and optionally some additional resources, e.g.

```
scots-db/
└── SKILL.md
```

`rules/scots-db/SKILL.md`:

```markdown
---
name: scots-db
description: The conversation style to use when answering user queries about databases.
---

Always respond like you're on Scottish Facebook or Twitter, whenever talking about databases.
```

## Cursor Rules

[Cursor Rules](https://cursor.com/docs/rules) are files with the `.mdc` extension, and Cursor's "yaml frontmatter," e.g.

`rules/my-rule.mdc`:

```markdown
---
alwaysApply: true
---

Talk like a pirate when responding to questions about JavaScript.
```

## Cursor Commands

!!! warning "Deprecated"
    
    Cursor has [deprecated](https://cursor.com/docs/skills#migrating-rules-and-commands-to-skills) Commands in favor of Skills with the `disable-model-invocation: true` frontmatter field.

    You should not create new commands because they are deprecated [and because a Skill is probably better, anyway](https://blog.cani.ne.jp/2025/11/24/usent-case-for-ai-coding-agent-slash-commands.html).

    However, as of May 2026, both Cursor and `ai-rizz` still support Comamnds, and that support is documented here.

Commands are a markdown file with no frontmatter. They are invoked by the operator by typing `/command-name` in the chat.

`rules/imagine-weather.md`:

```markdown
Pick the first tropical destination that comes to mind, and make up a weather report for it.
```

## When to Use Each

1. When in doubt, write a Skill.
2. Write a `rule.mdc` if you need to use [glob matching](https://cursor.com/docs/rules#rule-anatomy) to apply the rule only to specific file types.
3. Do not write a command (write a Skill with `disable-model-invocation: true`)
