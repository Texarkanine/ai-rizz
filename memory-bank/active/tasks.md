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
- `make install` / `make uninstall`: with isolated `HOME` and `PREFIX`, invoke zsh completion installer (fenced block present after install, absent after uninstall)

### Test Infrastructure

- Framework: shunit2 via `tests/run_tests.sh --unit`
- Test location: `tests/unit/`
- Conventions: `test_*.test.sh`, helpers invoke shell under test via `zsh -c` with `AI_RIZZ_COMPLETION_TEST=1`, mirror `test_bash_completion.test.sh` patterns; zsh tests **fail** (do not skip) if `zsh` is not on `PATH`
- New test files: `tests/unit/test_zsh_completion.test.sh`, `tests/unit/test_install_zsh_completion.test.sh`, `tests/unit/test_makefile_zsh_install.test.sh`

## Implementation Plan

### 1. Zsh completion helpers — executable

- Files: `completion.zsh`, `tests/unit/test_zsh_completion.test.sh`

1. [x] Stub tests: create `test_zsh_completion.test.sh` with empty test cases for repo-dir resolution, rule-name listing, and list-flag completion.
2. [x] Stub interface: add `completion.zsh` with `#compdef ai-rizz`, stub `_get_repo_dir`, `_ai_rizz_list_rule_names`, `_ai_rizz`, guarded `compdef`.
3. [x] Write tests and run red: implement test helpers (`_list_rule_names`, `_call_get_repo_dir`, `_complete_list_flags`) mirroring bash suite; run `./tests/unit/test_zsh_completion.test.sh` — expect failures.
4. [x] Write code and run green: port portable logic from `completion.bash` into zsh-native functions using function-specific local prefixes (`grd_` for `_get_repo_dir`, `lrn_` for `_ai_rizz_list_rule_names`, `aic_` for `_ai_rizz`); implement `_ai_rizz` case arms for commands, flags, rule/ruleset names; run unit test green.

### 2. Zsh completion installer — executable

- Files: `install-zsh-completion.bash`, `tests/unit/test_install_zsh_completion.test.sh`

1. [x] Stub tests: create installer test file with install/uninstall/idempotency cases (temp `HOME`, temp `completion.zsh` path).
2. [x] Stub interface: add `install-zsh-completion.bash` with usage stub and fence constants.
3. [x] Write tests and run red: assert fenced block content and removal; run test — expect failures.
4. [x] Write code and run green: implement install/uninstall mirroring `install-bash-completion.bash` (target `~/.zshrc`); run test green.

### 3. Makefile install hooks — executable

- Files: `Makefile`, `tests/unit/test_makefile_zsh_install.test.sh`

1. [x] Stub tests: create `test_makefile_zsh_install.test.sh` with cases for `make install` / `make uninstall` using temp `HOME` and `PREFIX` (no writes to operator shell files).
2. [x] Stub interface: no new functions; Makefile `install`/`uninstall` targets unchanged until green step.
3. [x] Write tests and run red: assert zsh fence appears in `$HOME/.zshrc` after `make install` and is removed after `make uninstall`; run test — expect failures.
4. [x] Write code and run green: wire `install-zsh-completion.bash` into `Makefile` `install`/`uninstall`; update messages; run test green.

### 4. Installation docs — prose/policy

- Files: `docs/user-guide/advanced/installation-options.md`
- No tests: prose/policy artifact

1. [x] Document zsh completion (installed via `make install`, `~/.zshrc` fence, `compinit` must run before the sourced block).

### Post-build fixes (operator smoke test)

1. [x] `compinit` bootstrap in installer fence + `completion.zsh` registration helper.
2. [x] `_get_repo_dir` fallback to global cache when project `rules/` missing (worktrees).
3. [x] `-maxdepth 1` for `.mdc`/`.md` in bash+zsh (parity with `cmd_list`; fixes nested reference false positives).
4. [x] Zsh `_ai_rizz` prev-word dispatch aligned with bash `_ai_rizz_completion`.
5. [x] `memory-bank/techContext.md` parity contract documented.

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
- [x] Preflight
- [x] Build
- [x] QA (PASS)
- [x] Reflect

### QA Results

- **Status**: PASS
- **Blocking findings**: None
- **Advisory findings**:
  - `completion.zsh` array expansion with double-quoted `"${(@f)...}"` produces single-element `("")` on empty output; unquoted `(${(f)"..."})` is cleaner for zero matches.
  - `completion.zsh:57` `local aic_cur="${words[CURRENT]}"` declared but not directly referenced in case statement.
  - Unit tests require `zsh` on PATH (fails if absent).
