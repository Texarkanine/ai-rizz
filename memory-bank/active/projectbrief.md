# Project Brief: ruleset-skills-cmd-routing

* **Task ID:** ruleset-skills-cmd-routing
* **Complexity:** Level 2

## Story

When a ruleset embeds skills under `rulesets/<r>/skills/<name>/` (including AgentSkills-style `references/**/*.md`), ai-rizz was copying every `*.md` under the ruleset flat into `.cursor/commands/`, so reference docs appeared as slash-commands in addition to the correct paths under `.cursor/skills/`. The CLI should exclude any path under the ruleset's `skills/` tree from the flat command pass so only true commands get that treatment.

## Done when

- `copy_entry_to_target` skips `skills/**` for the ruleset-wide `*.md` flattening step.
- Regression test proves reference markdown stays under the skill tree and not in commands.
- Full test suite passes.
