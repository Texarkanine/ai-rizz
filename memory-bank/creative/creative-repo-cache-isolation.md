# Creative Phase: Repository Cache Isolation

**Issue**: Global mode cache collision and mixed source repo conflicts
**Status**: EXPLORING
**Date**: 2026-01-25

---

## 🎨🎨🎨 ENTERING CREATIVE PHASE: ARCHITECTURE DESIGN

### Problem Statement

Two related issues have been identified:

**Problem 1: Global mode cache naming collision**

When running `ai-rizz init --global` outside a git repository:
- `get_repo_dir()` falls back to `basename $(pwd)`
- Running in `/home/alice` → cache name `alice`
- Running in `/home/bob` → cache name `bob`
- Running in `~/documents/git` → cache name `git`

These are ALL supposed to be the SAME global mode, but they get different caches.
Different users on the same machine would also collide if they share $HOME structure.

**Problem 2: Mixed source repos between modes**

Current design allows:
- Global mode → source repo X (e.g., `github.com/company/shared-rules`)
- Local mode → source repo Y (e.g., `github.com/myteam/project-rules`)

But `REPO_DIR` is set ONCE at startup and used for ALL operations:
- `ai-rizz list` uses `REPO_DIR` to find available rules
- `ai-rizz add rule foo.mdc --global` looks in `REPO_DIR` for `rules/foo.mdc`
- If local mode is active, `REPO_DIR` points to local's cache (repo Y)
- Trying to add from global's repo (X) will fail silently or find wrong file

### Current Architecture

```
$HOME/.config/ai-rizz/repos/
├── project-a/           # Cache for project-a (git repo name)
│   └── repo/            # Cloned source repository
├── project-b/           # Cache for project-b
│   └── repo/
└── somedir/             # Cache for non-git directory named "somedir"
    └── repo/            # ← Problem: This is PWD-dependent!

$HOME/ai-rizz.skbd       # Global manifest (points to source repo X)
$HOME/.cursor/rules/ai-rizz/     # Global rules target
$HOME/.cursor/commands/ai-rizz/  # Global commands target
```

**The Flaw**: `REPO_DIR` is a SINGLE global variable set at startup, but we now have
potentially THREE different source repos (local, commit, global) that need their own caches.

---

## Design Question 1: How should global mode's cache be named?

### Option 1A: Fixed directory name for global mode

```
$HOME/.config/ai-rizz/repos/
├── _ai-rizz.global/     # Fixed name, never conflicts with git repo names
│   └── repo/            # Global mode's source repo clone
├── project-a/           # Per-project caches (unchanged)
│   └── repo/
```

**Detection**: If mode is `global`, use `_ai-rizz.global` as project name.

**Pros**:
- Simple, deterministic
- Never collides with git repo names (can't start with `_` and contain `.`)
- Same cache regardless of where you run from

**Cons**:
- Requires special-casing in `get_repo_dir()` or a new function
- Must thread mode information through to cache lookup

### Option 1B: Derive from manifest location

Since global manifest is always `~/ai-rizz.skbd`, derive cache name from that:

```
Cache name: hash(~/ai-rizz.skbd) → "global-a1b2c3d4"
```

**Pros**:
- Automatically unique per manifest location
- No special naming conventions needed

**Cons**:
- Hash is opaque, hard to debug
- Still need to know which manifest we're working with

### Option 1C: Use manifest's source repo URL as cache key

```
Source repo: https://github.com/company/cursor-rules.git
Cache path: ~/.config/ai-rizz/repos/github.com_company_cursor-rules/repo/
```

**Pros**:
- Natural mapping: same source repo → same cache
- Human-readable
- Works for any mode

**Cons**:
- URL sanitization needed (slashes, special chars)
- Long paths possible
- Cache name must be derived AFTER reading manifest

### Recommendation: Option 1A (Fixed directory name)

Use `_ai-rizz.global` for simplicity. It's clear, debuggable, and never collides.

---

## Design Question 2: How should we handle mixed source repos?

### The Core Problem

```
# User's state:
Global manifest (~/ai-rizz.skbd):     source = github.com/company/shared-rules
Local manifest (ai-rizz.local.skbd):  source = github.com/myteam/project-rules

# User runs:
ai-rizz add rule awesome.mdc --global

# Current behavior:
- REPO_DIR points to local's cache (project-rules clone)
- Looks for rules/awesome.mdc in project-rules
- If it exists in project-rules but NOT shared-rules: WRONG RULE ADDED
- If it only exists in shared-rules: FAILS TO FIND
```

### Option 2A: Enforce same source repo across all modes (RESTRICTIVE)

**Rule**: All active modes MUST use the same source repository.

When initializing a mode, check if other modes exist:
- If yes, and different source repo → ERROR

```bash
$ ai-rizz init github.com/other/repo --local
Error: Cannot initialize with different source repository.
Global mode is already initialized with: github.com/company/shared-rules

To use a different source repository:
  1. Deinitialize global mode: ai-rizz deinit --global
  2. Then reinitialize: ai-rizz init github.com/other/repo --local
```

**Pros**:
- Simple mental model
- No cache isolation needed
- Single `REPO_DIR` works fine

**Cons**:
- Very restrictive
- Can't have company-wide global rules + project-specific local rules
- Defeats a key use case for global mode

### Option 2B: Per-mode cache directories (FLEXIBLE)

Each mode gets its own cache directory derived from its manifest's source repo:

```
$HOME/.config/ai-rizz/repos/
├── _global/                          # Global mode cache
│   └── github.com_company_shared-rules/
│       └── repo/
├── project-a/                        # Local/commit cache for project-a
│   └── github.com_myteam_project-rules/
│       └── repo/
```

**Implementation**:
1. Add `get_repo_dir_for_mode(mode)` function
2. When operating on a mode, use that mode's cache
3. `git_sync()` takes mode parameter to know which cache

**Pros**:
- Full flexibility
- Each mode independently managed
- Correct isolation

**Cons**:
- More complex implementation
- Multiple repos synced independently
- Larger disk usage

### Option 2C: Gate operations when repos differ (PRAGMATIC)

Allow different source repos, but gate operations:

1. **Listing**: Show all rules, indicate which repo each comes from
2. **Adding**: Only allow adding from the ACTIVE mode's repo
   - `ai-rizz add rule foo --global` → Must exist in global's repo
   - `ai-rizz add rule foo --local` → Must exist in local's repo
3. **Error clearly** when trying to add from wrong repo

```bash
$ ai-rizz list
Available rules (from github.com/company/shared-rules):
  ★ company-rule.mdc

Available rules (from github.com/myteam/project-rules):
  ● project-rule.mdc

$ ai-rizz add rule company-rule.mdc --local
Error: company-rule.mdc not found in local source repository.
This rule exists in the global repository (github.com/company/shared-rules).
Use --global to add it globally: ai-rizz add rule company-rule.mdc --global
```

**Pros**:
- Clear errors guide users
- Flexibility maintained
- Users understand what they're doing

**Cons**:
- Still need per-mode caches for this to work
- Listing becomes complex (multiple repos)

### Option 2D: Global mode inherits from current context (IMPLICIT)

Global mode doesn't have its OWN source repo. Instead:
- If in a repo with local/commit mode → global uses that same source repo
- If not in any repo → global mode unavailable

**Pros**:
- Simple, no mixed repo problem

**Cons**:
- Defeats purpose of "global mode works outside git repos"
- Global rules become repo-dependent
- Not a real "global" mode

### Option 2E: Gated Cross-Mode Operations (SELECTED) ✅

**Key Insight**: Local ↔ Commit transitions within a repo are a CORE FEATURE that must be preserved. Both modes share the same source repo by design. The only "different repo" scenario is global vs local/commit.

**Rule**: 
- Local/commit modes share the project's cache (UNCHANGED - this is good)
- Global mode gets its own fixed cache (`_ai-rizz.global`)
- When global and local/commit have DIFFERENT source repos:
  - Gate cross-mode operations
  - Must specify correct mode for each rule based on which repo it exists in
- When global and local/commit have the SAME source repo:
  - Full flexibility, all transitions allowed (existing behavior)

**Behavior with DIFFERENT source repos (global=X, local=Y)**:
```bash
# Rule `foo.mdc` exists only in global's repo (X)
# Rule `bar.mdc` exists only in local's repo (Y)

~/repo $ ai-rizz add rule foo --global     # ✅ OK - exists in X
~/repo $ ai-rizz add rule foo --local      # ❌ ERROR - not in Y
~/repo $ ai-rizz add rule bar --local      # ✅ OK - exists in Y  
~/repo $ ai-rizz add rule bar --global     # ❌ ERROR - not in X
~/repo $ ai-rizz add rule foo              # ❌ ERROR - ambiguous, specify mode
```

**Behavior with SAME source repos (global=X, local=X)**:
```bash
~/repo $ ai-rizz add rule foo --global     # ✅ OK
~/repo $ ai-rizz add rule foo --local      # ✅ OK
~/repo $ ai-rizz add rule foo              # Smart selection as today
```

**Pros**:
- Preserves local ↔ commit transitions (core feature)
- Clear error messages guide users
- Much simpler than full per-mode cache isolation
- Only need `GLOBAL_REPO_DIR`, not per-mode everything

**Cons**:
- Can't seamlessly move rules between global and local when repos differ
- But this is correct behavior - those are different rule sets!

---

## SELECTED SOLUTION: Option 2E (Gated Cross-Mode Operations)

### Implementation Approach

1. **Global mode uses fixed cache name**: `_ai-rizz.global`
   - `get_global_repo_dir()` returns `${CONFIG_DIR}/repos/_ai-rizz.global/repo`
   - This is deterministic regardless of where you run from

2. **Track `GLOBAL_REPO_DIR` separately**:
   ```shell
   REPO_DIR=""         # For local/commit (unchanged)
   GLOBAL_REPO_DIR=""  # For global mode
   ```

3. **Sync global repo independently**:
   - When global mode is active, sync global's source repo to `GLOBAL_REPO_DIR`
   - When local/commit active, sync to `REPO_DIR` (unchanged)

4. **Gate cross-mode operations**:
   ```shell
   # In cmd_add_rule() / cmd_add_ruleset():
   if repos_differ && target_mode == "global"; then
       # Must look in GLOBAL_REPO_DIR
       if rule not in GLOBAL_REPO_DIR; then
           error "Rule not in global repo, use --local/--commit"
       fi
   elif repos_differ && target_mode in ["local", "commit"]; then
       # Must look in REPO_DIR
       if rule not in REPO_DIR; then
           error "Rule not in local repo, use --global"
       fi
   fi
   ```

5. **Listing shows from correct repos**:
   - When both global and local/commit active with DIFFERENT repos:
     - Show rules from REPO_DIR (local/commit's repo)
     - Show global-installed rules with ★ but note they're from different repo
   - When repos are the SAME:
     - Current behavior (unified view)

---

## Key Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| Global cache naming | `_ai-rizz.global` | Fixed, predictable, never collides |
| Local ↔ Commit transitions | Preserve (shared cache) | Core feature, must not break |
| Mixed source repos | Gate cross-mode ops | Correct behavior, clear errors |
| Listing with mixed repos | Show local's repo, indicate global items | Practical UX |
| Adding from wrong repo | Error with helpful guidance | User learns the model |

---

## Implementation Complexity

**Changes Required** (MUCH smaller than Option 2B):

1. `get_global_repo_dir()` - New function returning `_ai-rizz.global` path
2. `GLOBAL_REPO_DIR` variable - Track global's cache separately
3. `git_sync()` for global - Sync global's repo to `GLOBAL_REPO_DIR`
4. `repos_differ()` helper - Compare source repos between global and local/commit
5. Gate in `cmd_add_rule()` / `cmd_add_ruleset()` - Check rule exists in target mode's repo
6. Update `cmd_list()` - Handle display when repos differ
7. Tests - Add tests for gating behavior

**Estimated Scope**: Small-medium refactor, ~100-150 lines changed

**What stays UNCHANGED**:
- `REPO_DIR` for local/commit (core feature preserved)
- `copy_entry_to_target()` and sync logic
- Local ↔ commit conflict resolution
- Most existing tests

---

## 🎨🎨🎨 EXITING CREATIVE PHASE

**Conclusion**: The gated cross-mode operations approach (Option 2E) is the correct solution.
It fixes the global cache naming issue while preserving the valuable local ↔ commit transition
feature. Cross-mode operations between global and local/commit are gated when source repos
differ, which is correct behavior since they represent different rule sets.

**Salvage Assessment**: Nearly all existing work is preserved. We're adding a gating layer,
not refactoring the core architecture. The only significant change is tracking `GLOBAL_REPO_DIR`
separately and syncing global's repo independently.

**Next Steps**:
1. Implement `get_global_repo_dir()` with fixed `_ai-rizz.global` name
2. Add `GLOBAL_REPO_DIR` tracking and sync
3. Add `repos_differ()` helper
4. Add gating logic to add operations
5. Update listing for mixed repo case
6. Add tests for new behavior
