# Project Brief: Global Sync Fix

## User Story

As a user with global rules installed via ai-rizz, I want `ai-rizz sync` to pull upstream changes into my global rules/commands/skills — the same way it already works for project local/commit modes — so I don't have to remove and re-add items to get updates.

## Requirements

1. **Default `ai-rizz sync`**: When global mode is initialized, call `sync_global_repo()` before deploying manifest entries (matching `list`/`add` behavior).
2. **`ai-rizz sync --global`**: Sync only global mode — pull the global source repo and redeploy the global manifest, without touching local/commit modes or the project rules cache.
3. Update help text to document the new flag.

## Root Cause

`cmd_sync` only calls `git_sync("${SOURCE_REPO}")` for the project cache. It never calls `sync_global_repo()`, so `GLOBAL_REPO_DIR` stays stale while `sync_all_modes()` redeploys from that stale cache.
