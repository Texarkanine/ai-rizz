# Current Task: fix-issue-44-skill-tab-completion

**Complexity:** Level 1

## Fix Summary

- **What broke:** Bash tab completion after `add rule` / `remove rule` only listed `.mdc` / `.md` files, so standalone skills (`rules/<name>/SKILL.md`) never appeared.
- **Why:** Skill support reused `add rule` for install, but `completion.bash` was not updated to discover skill directories.
- **What changed:** Extracted `_ai_rizz_list_rule_names()` to list rules, commands, and standalone skills; wired `rule` completion through it; added unit coverage.

## Files Affected

- `completion.bash` — skill-aware rule-name listing + test-friendly `complete` registration gate
- `tests/unit/test_bash_completion.test.sh` — new unit suite for listing behavior
