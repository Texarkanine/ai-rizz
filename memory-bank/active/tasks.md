# Task: Zsh tab completion for ai-rizz

* Task ID: issue-54-zsh-completion
* Complexity: Level 2
* Type: Bug fix / simple enhancement

Fix [#54](https://github.com/Texarkanine/ai-rizz/issues/54): add native zsh tab completion for `ai-rizz`, matching bash completion behavior, with install/uninstall hooks and unit tests.

## Test Plan (TDD)

### Behaviors to Verify

- `_get_repo_dir` (zsh): outside git → global cache `_ai-rizz.global/repo`
- `_get_repo_dir` (zsh): git repo with project manifest → project cache `repos/<basename>/repo`
- `_get_repo_dir` (zsh): git repo without project manifests → global cache
- `_ai_rizz_list_rule_names` (zsh): lists standalone skills, symlinked SKILL.md, rules, commands; excludes non-skill dirs and nested skill paths
- `_ai_rizz` completion (zsh): after `list`, offers `-a` and `--all`
- `install-zsh-completion.bash install`: adds fenced block to `~/.zshrc` with absolute path to `completion.zsh`
- `install-zsh-completion.bash uninstall`: removes fenced block idempotently
- `make install` / `make uninstall`: invoke zsh completion installer alongside bash (no regression in existing targets)

### Test Infrastructure

- Framework: shunit2 via `tests/run_tests.sh --unit`
- Test location: `tests/unit/`
- Conventions: `test_*.test.sh`, helpers invoke shell under test via `zsh -c` with `AI_RIZZ_COMPLETION_TEST=1`, mirror `test_bash_completion.test.sh` patterns
- New test files: `tests/unit/test_zsh_completion.test.sh`, `tests/unit/test_install_zsh_completion.test.sh`

## Implementation Plan

### 1. Zsh completion helpers — executable

- Files: `completion.zsh`, `tests/unit/test_zsh_completion.test.sh`

1. Stub tests: create `test_zsh_completion.test.sh` with empty test cases for repo-dir resolution, rule-name listing, and list-flag completion.
2. Stub interface: add `completion.zsh` with `#compdef ai-rizz`, stub `_get_repo_dir`, `_ai_rizz_list_rule_names`, `_ai_rizz`, guarded `compdef`.
3. Write tests and run red: implement test helpers (`_list_rule_names`, `_call_get_repo_dir`, `_complete_list_flags`) mirroring bash suite; run `./tests/unit/test_zsh_completion.test.sh` — expect failures.
4. Write code and run green: port portable logic from `completion.bash` into zsh-native functions; implement `_ai_rizz` case arms for commands, flags, rule/ruleset names; run unit test green.

### 2. Zsh completion installer — executable

- Files: `install-zsh-completion.bash`, `tests/unit/test_install_zsh_completion.test.sh`

1. Stub tests: create installer test file with install/uninstall/idempotency cases (temp `HOME`, temp `completion.zsh` path).
2. Stub interface: add `install-zsh-completion.bash` with usage stub and fence constants.
3. Write tests and run red: assert fenced block content and removal; run test — expect failures.
4. Write code and run green: implement install/uninstall mirroring `install-bash-completion.bash` (target `~/.zshrc`); run test green.

### 3. Makefile and docs — prose/policy

- Files: `Makefile`, `docs/user-guide/advanced/installation-options.md`
- No tests: prose/policy artifact

1. Call `install-zsh-completion.bash` from `install` and `uninstall` targets; update install/uninstall messages for zsh.
2. Document zsh completion in installation options (sourcing via `make install`, `~/.zshrc` fence, `compinit` prerequisite note).

## Technology Validation

No new technology — validation not required. Zsh completion uses built-in `compdef` / `compadd` (standard on macOS zsh). Probe confirmed bashcompinit shim is unsuitable (`compdef` not found under emulation).

## Dependencies

- Existing `completion.bash` behavior as reference implementation
- shunit2 test runner (already in repo)
- zsh available on developer/CI machines for unit tests

## Challenges & Mitigations

- **Zsh word indexing differs from bash `prev`/`cur`:** Mirror bash arms using `words[CURRENT-1]` and explicit `CURRENT` checks; cover with list-flag completion test.
- **`compinit` may not have run before sourced block:** Guard `compdef` with `$+functions[compdef]`; document that typical `.zshrc` runs `compinit` before appended fence.
- **Duplicated repo-listing logic:** Accept duplication between bash and zsh files to keep scope minimal; keep algorithms identical to bash for parity.

## Pre-Mortem

- **Completion works in tests but not interactively on macOS:** Likely `compinit` ordering or fence not sourced — mitigated by installer appending to `.zshrc` and docs note; operator manual test before archive.
- **CI lacks zsh:** Add zsh presence check at top of zsh unit tests with clear skip/fail message; verify `make test` environment has zsh (macOS dev machine does).
- **Drift from bash completion on future changes:** Already covered by parallel test suites listing the same scenarios.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
