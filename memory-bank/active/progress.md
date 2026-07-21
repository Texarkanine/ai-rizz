# Progress

Fix bash tab completion so skills are offered the same way rules and rulesets already are ([issue #44](https://github.com/Texarkanine/ai-rizz/issues/44)).

**Complexity:** Level 1

## 2026-07-21 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Clarified intent with operator (fix skill tab completion per #44)
    - Classified as Level 1: isolated bug in `completion.bash`
* Decisions made
    - Level 1 workflow: skip plan/creative/preflight/reflect/archive; go straight to build then QA
* Insights
    - Skills use `add rule`, not a separate type; completion must list skill dirs under `rules/`

## 2026-07-21 - BUILD - COMPLETE

* Work completed
    - Extracted `_ai_rizz_list_rule_names` and included `rules/<name>/SKILL.md` names
    - Added unit suite `tests/unit/test_bash_completion.test.sh`
    - Full test suite passed
* Decisions made
    - No `skill` completion type — match CLI (`add rule` / `remove rule`)
    - Gate `complete -F` behind `AI_RIZZ_COMPLETION_TEST` for sourcable tests
* Insights
    - Negative listing tests need a positive baseline assert so empty stubs cannot pass

## 2026-07-21 - QA - COMPLETE

* Work completed
    - Semantic review against project brief and system patterns
    - Wrote `.qa-validation-status` = PASS
* Decisions made
    - No QA fixes required
* Insights
    - Extracting `_ai_rizz_list_rule_names` was the right testability tradeoff for a bash completion script

## 2026-07-21 - BUILD - FOLLOW-UP COMPLETE

* Work completed
    - Fixed `_get_repo_dir` to use `_ai-rizz.global` outside git / global-only (was basename(PWD))
    - Added three unit tests for repo-dir selection
* Decisions made
    - Match `cmd_list`: project manifests → project cache; else global cache
* Insights
    - Stale `repos/mobaxterm` cache explained missing skills at `~`
