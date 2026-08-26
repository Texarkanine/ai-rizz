# Project Brief: Zsh tab completion for ai-rizz

**Issue:** [#54 — Tab completions don't work in zsh](https://github.com/Texarkanine/ai-rizz/issues/54)

## User story

As a zsh user on macOS (and elsewhere), I want `ai-rizz` tab completion for commands, flags, rules, and rulesets so I get the same discoverability bash users already have.

## Requirements

- Ship native zsh completion with parity to existing `completion.bash` behavior (commands, entity types, flags, dynamic rule/ruleset names from the same repo cache logic as bash).
- Install/uninstall zsh completion via `make install` / `make uninstall`, using the same fenced-block pattern as `install-bash-completion.bash` (target: `~/.zshrc`).
- Unit tests for zsh completion helpers and representative completion arms (mirror bash completion test coverage where applicable).
- Update user-facing installation docs to mention zsh completion.
- Do not regress bash completion or existing tests.

## Out of scope

- Rewriting bash completion or extracting a shared library (unless needed for correctness).
- Interactive/manual zsh verification is operator-assisted; automated unit tests are the gate.

## Testing context

Operator runs zsh on macOS and can manually verify tab completion when asked.
