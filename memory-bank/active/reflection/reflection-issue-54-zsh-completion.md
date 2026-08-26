---
task_id: issue-54-zsh-completion
date: 2026-08-26
complexity_level: 2
---

# Reflection: Zsh tab completion for ai-rizz

## Summary

Shipped native zsh tab completion (#54) with installer, Makefile hooks, docs, and unit tests. Operator smoke test passed after fixing `compinit` bootstrap, discovery parity with `cmd_list`, and cache fallback for worktrees.

## Requirements vs Outcome

All planned deliverables landed. Post-plan fixes were required for interactive zsh (no `compinit` in operator `.zshrc`) and catalog accuracy (recursive `.md` find offered nested skill references). Bash completion received the same discovery fix for parity.

## Plan Accuracy

Level 2 plan was mostly right. Preflight correctly blocked missing Makefile test-first steps. Smoke test surfaced issues the plan's pre-mortem anticipated (`compinit`, catalog drift) plus worktree cache basename mismatch.

## Build & QA Observations

Build iterated outside strict phase gates (Composer session); re-entering Niko closed Build with commit, QA PASS (3 advisories), and this reflect. QA advisories addressed: empty-array `compadd` idiom and unused local removed.

## Insights

### Technical
- Completion discovery must mirror `cmd_list` exactly: top-level `rules/*.mdc`, `rules/*.md`, and `rules/<skill>/SKILL.md` only — never recursive `.md` under skill trees.
- Zsh shells without `compinit` in `.zshrc` need installer + runtime bootstrap before `compdef` works.

### Process
- Bash/zsh completion files need an explicit lockstep contract in `techContext.md` and parallel unit tests; otherwise drift is inevitable.

### Million-Dollar Question

A single `completion-lib.sh` sourced by both shells would be the DRY foundation, but the current duplicated files with cross-references and mirrored tests are acceptable for Level 2 scope and keep shell-specific dispatch local.
