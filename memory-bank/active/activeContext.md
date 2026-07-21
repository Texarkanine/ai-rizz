# Active Context

## Current Task: fix-issue-44-skill-tab-completion
**Phase:** QA - COMPLETE (follow-up build also complete)

## What Was Done
- Initial fix: skill dirs listed after `add rule` / `remove rule` via `_ai_rizz_list_rule_names`
- Follow-up: `_get_repo_dir` uses `_ai-rizz.global` outside git / global-only (was `basename(PWD)` → stale `repos/mobaxterm`)
- Operator verified depth/`find` understanding; confirmed skills missing at `~` vs present in-repo
- Full `make test` passed after follow-up; committed as `b85cbf6`

## Next Step
- Level 1 wrap-up cleanup when satisfied: remove `memory-bank/active/` and commit, or open PR for #44
