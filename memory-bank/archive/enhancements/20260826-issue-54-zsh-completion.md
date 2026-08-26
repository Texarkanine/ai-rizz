---
task_id: issue-54-zsh-completion
complexity_level: 2
date: 2026-08-26
status: completed
---

# TASK ARCHIVE: Zsh tab completion for ai-rizz

## SUMMARY

Shipped native zsh tab completion for [#54](https://github.com/Texarkanine/ai-rizz/issues/54). `make install` writes a fenced `~/.zshrc` block when `zsh` is on `PATH` (and bash likewise). Operator smoke-tested on macOS. Draft PR [#55](https://github.com/Texarkanine/ai-rizz/pull/55).

## REQUIREMENTS

- Zsh completion parity with bash: commands, flags, `add`/`remove` types, dynamic rule/ruleset names from the same catalog as `cmd_list`.
- Install/uninstall via `make install` / `make uninstall` (fenced `~/.zshrc`).
- Unit tests for helpers and representative completion arms; fail if `zsh` is missing (do not skip).
- Installation docs mention zsh.
- Do not regress bash completion.

## IMPLEMENTATION

- **`completion.zsh`:** `#compdef`; `_get_repo_dir` / `_ai_rizz_list_rule_names` lockstep with `completion.bash` (top-level `rules/*.mdc`, `rules/*.md`, `rules/<skill>/SKILL.md` only); `_ai_rizz` dispatches on `words[CURRENT-1]` like bash `prev`. Bootstraps `compinit`/`compdef` when the operator `.zshrc` has none.
- **`install-zsh-completion.sh`:** POSIX installer (`.sh`, not `.bash`); fence runs `compinit -C` then sources `completion.zsh`.
- **`Makefile`:** install a shell's fence only if that shell is on `PATH`; uninstall still clears both fences.
- **`completion.bash`:** same `-maxdepth 1` discovery and project-cache fallback when `rules/` is missing (worktrees).
- **CI:** provision `zsh` in the unit job; exclude `*.zsh` from ShellCheck (CI ShellCheck has no zsh dialect).
- **Persistent bank:** `techContext.md` records the bash/zsh lockstep contract.

## TESTING

- Unit 7/7: `test_zsh_completion.test.sh`, `test_install_zsh_completion.test.sh`, `test_makefile_zsh_install.test.sh`, plus bash nested-md / cache-fallback cases.
- Operator: `ai-rizz <TAB>`, `list <TAB>`, `add rule <TAB>` after `exec zsh`; catalog matches `list -a` (no nested skill markdown).
- `/niko-qa` PASS (0 blocking). Advisories: empty-array `compadd` idiom and unused `aic_cur` fixed in reflect; CI `zsh` provisioned after first red run.
- Integration 21/34 matched `main` baseline on this machine (pre-existing symlink/env failures).

## LESSONS LEARNED

Inlined from ephemeral reflection:

- Discovery must match `cmd_list`: never recurse `.md` under skill trees (`personality-prompts` was `prompt-authoring/references/personality-prompts.md`).
- Zsh without `compinit` in `.zshrc` never registers `compdef`; installer + runtime bootstrap is required.
- Bash and zsh completion files need an explicit lockstep contract and parallel unit tests or they drift.
- A shared `completion-lib.sh` would be the DRY foundation; duplicated files with mirrored tests were enough for Level 2.

## PROCESS IMPROVEMENTS

Build iterated outside Niko phase gates (Composer). Re-enter with commit → QA subagent → reflect before calling the task done. Preflight correctly blocked unlabeled Makefile executable steps.

## TECHNICAL IMPROVEMENTS

Optional later: one shared discovery script sourced by both shells. Not required for this ship.

## NEXT STEPS

None. Merge [PR #55](https://github.com/Texarkanine/ai-rizz/pull/55) when ready.
