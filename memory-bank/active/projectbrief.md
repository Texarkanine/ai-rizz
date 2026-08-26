# Project Brief

## User Story

After `ai-rizz init`, when nothing is installed yet, plain `ai-rizz list` should show the full source catalog (same as `--all`) so new users can discover what to install. Once at least one item is installed, default `list` remains inventory-only with the `N available, not shown` footer.

## Requirements

- Empty inventory (all active manifests have no entries): default `list` matches `list --all` output — full catalog with `○` glyphs, no footer.
- Non-empty inventory: existing inventory-only default unchanged; footer when catalog rows are hidden.
- Explicit `-a`/`--all` unchanged.
- Empty **source** catalog (no rules/commands/rulesets in repo): still prints nothing.
- Tests: function suite + CLI integration case for fresh init.
- Docs: `list` command page and getting-started examples use plain `list` after init.
- Update `memory-bank/systemPatterns.md` list-view contract.

## Task ID

`list-empty-inventory-catalog`
