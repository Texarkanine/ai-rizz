# System Patterns

## Test suite taxonomy

Three buckets, driven by [`tests/run_tests.sh`](./tests/run_tests.sh):

1. **`tests/unit/`** — Fast loops: suites that avoid heavy integration scenarios (e.g. pure detection helpers). Still use `tests/common.sh` and may run in a temp directory; the split is by *intent* and cost, not “no disk.”
2. **`tests/integration/*.test.sh`** — Top-level files exercise the **public CLI** (`ai-rizz` as a subprocess).
3. **`tests/integration/functions/*.test.sh`** — **Direct function** tests: source `ai-rizz` and call `cmd_*` / sync paths against real temp repos, git, symlinks, and on-disk deploy results. Discovery is recursive (`find` on `tests/integration`), so nested `functions/` is included in integration runs without extra wiring.

## Entity Type Routing

Each entity has a detection function and a target directory getter:
- Rules (`.mdc`) → `is_command()` returns false → `.cursor/rules/<mode>/`
- Commands (`.md`) → `is_command()` returns true → `.cursor/commands/<mode>/`
- Skills (dirs with `SKILL.md`) → `is_skill()` returns true → `.cursor/skills/<mode>/`
- Rulesets (dirs without `SKILL.md`) → iterate → deploy children to above targets

All routing happens in `copy_entry_to_target()`: file vs directory is branched first, then entity-specific logic.

## Magic Subdirectories in Rulesets

Rulesets can have special subdirectories whose contents are routed differently:
- `commands/` — `.md` files copied flat to `.cursor/commands/<mode>/` (organizational convention; other `.md` outside `skills/` are also commands)
- `skills/` — skill directories (each containing `SKILL.md`) copied to `.cursor/skills/<mode>/` via `cp -rL`. Direct child symlinks are included when they resolve within the repository; out-of-repo symlink targets are skipped for safety. Any `*.md` under `rulesets/<r>/skills/` is excluded from the flat command pass so references and other skill-local markdown are not mistaken for Cursor slash-commands.

## Skill Definition Paths

Skills can be defined in exactly two places:
1. `rules/<skill-name>/SKILL.md` — standalone skill, one level only, no nesting
2. `rulesets/<ruleset-name>/skills/<skill-name>/SKILL.md` — embedded in a ruleset's magic `skills/` subdir

Embedded-skill discovery explicitly includes direct-child symlink entries under `rulesets/<ruleset>/skills/` and validates top-level target boundaries before list/deploy.

## POSIX-Compliant Local Variable Prefixes

All functions use a function-specific prefix for local variables to avoid subshell scope issues. Examples:
- `is_command()` → `ic_` prefix
- `cmd_add_rule()` → `car_` prefix
- `copy_entry_to_target()` → `cett_` prefix

## Dual Manifest + Sync Architecture

Adding an item writes to a manifest file only. `sync_all_modes()` then reads manifests and calls `copy_entry_to_target()` for each entry, rebuilding the target directories. This means sync is the single source of truth for what ends up deployed.

Before sync, target directories (rules, commands, skills) for the mode are cleared and rebuilt from scratch.

## C Locale Enforcement

`ai-rizz` sets `LC_ALL=C` at script top to ensure POSIX character class ranges (`[A-Z]`, `[a-z]`, etc.) use byte-value ordering rather than locale-dependent dictionary collation. Without this, ranges like `[A-Z]` match lowercase letters under UTF-8 locales (e.g. macOS `en_US.UTF-8`), silently breaking entity-type routing for `.md` commands.
