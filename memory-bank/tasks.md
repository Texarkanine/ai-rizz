# Task: Short-circuit mode selection for single ruleset with commands

## Problem
When adding a single ruleset that contains a `commands/` directory, users currently get an error if they specify `--local` or don't specify a mode. Since rulesets with commands can ONLY be added in commit mode, we should automatically use commit mode and warn the user if they explicitly provided `--local`.

## Current Flow
1. Parse arguments (including mode flags)
2. `ensure_initialized_and_valid`
3. `select_mode` (uses parsed mode or auto-detects)
4. Loop through rulesets
5. For each ruleset, check if it has commands/ and reject if mode is local

## Desired Flow
1. Parse arguments (including mode flags)
2. `ensure_initialized_and_valid` (needed to access REPO_DIR)
3. **NEW**: If exactly one ruleset AND it has commands/:
   - If original mode was "local", warn user
   - Override mode to "commit"
4. `select_mode` (uses overridden mode)
5. Loop through rulesets (commands check now unnecessary for single ruleset case)

## Implementation Plan

### Step 1: Track original mode
- Store the original mode before any overrides: `cars_original_mode="${cars_mode}"`

### Step 2: Add short-circuit logic
After `ensure_initialized_and_valid` and before `select_mode`:
- Count rulesets: Check if `cars_rulesets` contains exactly one ruleset
- If single ruleset:
  - Check if ruleset exists in repo (use `check_repository_item` or direct check)
  - Check if it has `commands/` subdirectory
  - If yes:
    - If `cars_original_mode` was "local", warn user
    - Set `cars_mode="commit"`

### Step 3: Remove redundant check
- The check at line 2994-2998 can remain for multiple rulesets case
- Or we can keep it as a safety check (won't trigger for single ruleset case)

### Step 4: Add warning function
- Create a warning message when we auto-switch from local to commit mode

## Test Cases
1. Single ruleset with commands, no mode specified → auto-commit mode
2. Single ruleset with commands, `--local` specified → warn + auto-commit mode
3. Single ruleset with commands, `--commit` specified → commit mode (no change)
4. Multiple rulesets, one has commands → normal flow (check in loop)
5. Single ruleset without commands → normal flow

## Files to Modify
- `ai-rizz`: `cmd_add_ruleset()` function

---

## Implementation Status: ✅ Complete

## Reflection Status: ✅ Complete

## Archive Status: ✅ Complete

**Archive**: `memory-bank/archive/enhancements/20251213-mode-shortcircuit.md`
