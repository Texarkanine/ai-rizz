# Current Task: fix-issue-44-skill-tab-completion

**Complexity:** Level 1

## Fix Summary

- **What broke:** Bash tab completion after `add rule` / `remove rule` only listed `.mdc` / `.md` files, so standalone skills (`rules/<name>/SKILL.md`) never appeared.
- **Why:** Skill support reused `add rule` for install, but `completion.bash` was not updated to discover skill directories.
- **What changed:** Extracted `_ai_rizz_list_rule_names()` to list rules, commands, and standalone skills; wired `rule` completion through it; added unit coverage.

## Files Affected

- `completion.bash` — skill-aware rule-name listing; `_get_repo_dir` project-vs-global selection; test-friendly `complete` gate
- `tests/unit/test_bash_completion.test.sh` — listing + `_get_repo_dir` unit coverage

## QA Results

- **Status:** PASS
- **Findings:** None. Implementation matches brief; no over-engineering, stubs, or doc gaps.

## Follow-up Fix

- **Issue:** Outside a git repo, `_get_repo_dir` used `repos/$(basename "$PWD")/repo` (e.g. stale `repos/mobaxterm`), so global skills were missing from completion.
- **Fix:** Mirror `cmd_list` — project manifests → project cache; otherwise `_ai-rizz.global`.
- **Tests:** `test_get_repo_dir_outside_git_uses_global_cache`, `test_get_repo_dir_with_project_manifest_uses_project_cache`, `test_get_repo_dir_git_without_project_manifest_uses_global_cache`
