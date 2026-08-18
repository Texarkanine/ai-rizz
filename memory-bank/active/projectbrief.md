# Project Brief

## User Story

As the operator of ai-rizz, I want `ai-rizz list` to show only what is installed on this project so I can inspect inventory without scanning the source-repo catalog.

## Use-Case(s)

### Use-Case 1

I already know the catalog. I run `ai-rizz list` to see what is installed here (mode glyphs included). Uninstalled catalog entries are omitted. Sections with nothing installed do not print a header. One footer reports how many catalog items were hidden: `N available, not shown`.

### Use-Case 2

I want the catalog (first-run, picking something to add). I run `ai-rizz list -a` or `ai-rizz list --all` and get today's full listing, including uninstalled items and their glyphs. No footer, because nothing is hidden.

## Requirements

1. `ai-rizz list` (no flags) lists installed items only: rules, commands, standalone skills, and rulesets, with existing mode glyphs (`●` / `◐` / `★`).
2. A section header (`Available rules:`, `Available commands:`, `Available skills:`, `Available rulesets:`) is printed only when that section has at least one installed member.
3. Uninstalled rulesets are omitted entirely, including their trees. Installed rulesets still show their trees as today.
4. One cumulative footer across all types, printed only in the default view when at least one catalog item was hidden: `N available, not shown`. `N` is the count of omitted top-level glyph-bearing rows (standalone rules, commands, skills, and rulesets). Tree children of a ruleset are not extra counts.
5. `ai-rizz list -a` and `ai-rizz list --all` restore the current catalog view (all items, all glyphs, all section headers that have any catalog members). No footer.
6. Flags, not a `list installed` / `list all` subcommand. Unknown list arguments error.
7. Help text and user docs follow the new default. Getting-started discovery steps use `list --all`.

## Constraints

1. POSIX-compliant `ai-rizz` script (no bash-isms in the main tool).
2. TDD: tests first; `make test` at the end; do not test in the project directory.
3. Existing list tests that assert catalog/uninstalled behavior must keep covering that behavior via `--all`, not be deleted.
4. `cmd_list` remains the list implementation; do not split into a second command.

## Acceptance Criteria

1. After init with a nonempty catalog and nothing installed, `ai-rizz list` prints no section headers and prints a single footer `N available, not shown` where `N` matches the number of top-level catalog items.
2. After installing a subset, `ai-rizz list` shows only those items (correct glyphs), omits empty-of-installed sections, and the footer `N` equals the remaining uninstalled top-level items.
3. `ai-rizz list --all` and `ai-rizz list -a` match today's catalog listing (uninstalled glyphs included, no footer).
4. Unknown flags/args to `list` fail with an actionable error.
5. Docs and `ai-rizz help` describe inventory as the default and `--all` as the catalog.
