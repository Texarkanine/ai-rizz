# Current Task: issue-grouping-recommendation

**Complexity:** Level 1

## Findings

### Issues reviewed
- [#40](https://github.com/Texarkanine/ai-rizz/issues/40) — bug: global-only init + `add rule` in a non-init'd repo writes invalid `ai-rizz.skbd` (no metadata line)
- [#41](https://github.com/Texarkanine/ai-rizz/issues/41) — enhancement: with local XOR commit init'd, still prompted because global is counted as active; want explicit `--global` only
- [#42](https://github.com/Texarkanine/ai-rizz/issues/42) — enhancement: `deinit --all` also wipes global; want `--both` (local+commit) and remove/guard `--all`

### Shared code surface
- `#40` / `#41`: `select_mode()` (~L2237) counts `is_mode_active global` alongside local/commit; `cmd_add_rule` / `cmd_add_ruleset` call it after `ensure_initialized_and_valid`
- `#42`: `cmd_deinit()` (~L2975) `--all` sets `cd_remove_local/commit/global=true`; interactive prompt offers `all`

### Recommendation
- **One push: #40 + #41**
- **Separate: #42**

## Why #40 + #41 together
Same product rule: inside a git repo, global must be opt-in via `--global`; repo auto-select should consider only local/commit. Implementing #41's "exclude global from the single-mode count" also stops the #40 path (auto-picking global in a bare repo) and pairs naturally with a hard error / no-write when no repo mode is init'd. Defense-in-depth for the invalid-manifest write can live in the same change set (`add_manifest_entry_to_file` creates files via `>>` without a header if missing).

## Why #42 alone
Different command (`deinit`), different UX (destructive wipe vs add-time mode selection). No dependency on `select_mode`. Shipping it with #40/#41 inflates review surface and mixes a flag rename/footgun fix with mode-selection policy.
