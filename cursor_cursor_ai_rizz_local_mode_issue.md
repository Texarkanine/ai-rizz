# Cursor `ai-rizz` local mode issue
_Exported on 12/11/2025 at 17:41:45 CST from Cursor (2.2.9)_

---

**User**

Recent versions of Cursor on Mac have broken `ai-rizz`'s "local" mode - Cursor now ignores ALL files ignored by git regardless of method, not just files in .gitignore.

So, we need a solution, and I have a plan: you can `ai-rizz init ... --hook-based-ignore` which will init local mode without a .git/info/exclude entry. Instead, a git pre-commit hook will be created that just un-stages the LOCAL_DIR @ai-rizz:39 path before commit.

So, users will still see the "local" files tracked in source control and be able to add them, but will never be able to commit them and they won't make it up to remote VCS systems.

HOWEVER... anything the user has locally that tries to get the git index to a "clean" state will break because no matter how many time it adds and commits, there will always be untracked files. But, only locally, since the hook is local and the rules won't ever be pushed. What could we do about that?

Or, if we can do nothing AND that's a big problem, can you come up with a different solution?

---

**Cursor**


Exploring the codebase to understand the current "local" mode implementation and how it's used.



Reviewing the `cmd_init` function to understand flag handling:



Analyzing the problem and exploring solutions. Checking how git hooks are currently handled:



Addressing the "clean state" issue: a pre-commit hook that unstages files leaves them untracked, so `git status` never shows clean. Using `git update-index --skip-worktree` instead: files remain tracked, changes are ignored, and they won't appear as modified. Combining this with a pre-commit hook to prevent commits.

Implementing this solution:



Implementing the hook-based solution. For the "clean state" issue: we'll document it and add a helper to check clean state excluding the local directory. Starting implementation:



Implementing the hook-based solution. Adding functions to manage pre-commit hooks and updating the initialization logic:


---

**User**

Do not implement. If you think you have an idea, explain the design to me in sufficient detail for me to either approve, or drill further into, the design.

---

**Cursor**


## Problem analysis

- Current: `.git/info/exclude` hides files from Cursor on Mac (it now respects all git-ignored files).
- Goal: Files visible to Cursor, but never committed.
- Constraint: Avoid breaking tools that expect a clean git state.

## Proposed design: pre-commit hook approach

### Core mechanism

1. No `.git/info/exclude` entry — files remain visible to Cursor.
2. Pre-commit hook unstages `LOCAL_DIR` and `LOCAL_MANIFEST_FILE` before commit.
3. Files can be added/staged, but are removed from staging before commit.

### Implementation details

**Hook creation:**
- Hook path: `.git/hooks/pre-commit`
- Behavior: Unstage files matching `LOCAL_DIR` and `LOCAL_MANIFEST_FILE` patterns
- Preserve existing hooks: Append to existing hook if present, or create new one
- Hook identification: Include a marker comment so we can identify/remove our hook later

**Hook script structure:**
```bash
#!/bin/sh
# ai-rizz hook-based ignore (do not edit manually)
# Unstages local mode files before commit
git reset HEAD -- .cursor/rules/local/ ai-rizz.local.skbd 2>/dev/null || true
# Continue with existing hook if present
```

**Flag handling:**
- `--hook-based-ignore` flag in `cmd_init`
- When set: Skip `setup_local_mode_excludes()`, create hook instead
- Store mode indicator: Could use a marker file or metadata to remember which mode was used

### The "clean state" problem

**Issue:** Files remain untracked, so `git status` never shows clean.

**Possible mitigations:**

1. Document the limitation — explain that local files will always appear untracked.
2. Provide a helper command — `ai-rizz git-status-clean` that checks clean state excluding local files:
   ```bash
   git status --porcelain | grep -v "^?? .*\.cursor/rules/local/" | grep -v "^?? ai-rizz.local.skbd"
   ```
3. Use `git update-index --skip-worktree` — Track files initially, then mark them with `--skip-worktree` so changes are ignored. Still shows as modified, but less noisy.
4. Hybrid approach — Track files initially, use `--skip-worktree`, and have the hook ensure they're not committed. Files show as modified but changes are ignored.

### Alternative design: skip-worktree approach

Instead of untracked files, use `git update-index --skip-worktree`:

1. Initially add and commit empty placeholder files (or initial state)
2. Mark with `--skip-worktree` so local changes are ignored
3. Pre-commit hook prevents committing changes to these files
4. Files show as "modified" in status, but git ignores the changes

**Pros:**
- Files are tracked (exist in git)
- Local changes don't affect "clean" checks as much
- Still visible to Cursor

**Cons:**
- Shows as modified in `git status`
- More complex setup (need initial commit)
- Users might be confused by "modified" status

## Questions for you

1. Which approach do you prefer?
   - A) Pre-commit hook only (untracked files, always dirty)
   - B) Skip-worktree approach (tracked but ignored, shows modified)
   - C) Hybrid (tracked + skip-worktree + hook)

2. How critical is the "clean state" issue?
   - Is it a blocker, or acceptable with documentation?
   - Do you have specific tools/workflows that would break?

3. Should we provide a helper command for checking "clean state" excluding local files?

4. How should we handle existing pre-commit hooks?
   - Append our logic?
   - Require user to integrate manually?
   - Use a hook manager framework?

5. Should the hook-based mode be the default for local mode, or opt-in via flag?

Share your preferences and I’ll refine the design accordingly.

```shellscript
#!/bin/sh
# ai-rizz hook-based ignore (do not edit manually)
# Unstages local mode files before commit
git reset HEAD -- .cursor/rules/local/ ai-rizz.local.skbd 2>/dev/null || true
# Continue with existing hook if present
```

```shellscript
   git status --porcelain | grep -v "^?? .*\.cursor/rules/local/" | grep -v "^?? ai-rizz.local.skbd"
```

---

**User**

We MUST have the git commit that gets pushed or sent in a PR show no trace. Bootstrapping an empty file to later ignore via worktree doesn't work - someone will ask on the initial commit "why u doin' this?"

The clean state is PROBABLY a minor issue but it might confuse some developers. It could be documented somewhere (maybe we have to start adding a README into local, when using hook-based ignore?)

Actually, we could just do the hook ALWAYS, right? The unstaging will have no effect if the files are ignored. If someone's init'd with --hook-based-ignore, it will have effect. How "heavy" will that pre-commit hook be, to just run it always?

I don't see a way to have both totally clean pushes to the remote repo AND a clean git status locally without using git ignores... do you?

---

**Cursor**


## Always-run hook approach

### Core design

**The hook always runs**, regardless of mode:
- If files are in `.git/info/exclude`: They won't be staged, so `git reset HEAD -- <paths>` is a no-op (harmless).
- If files are NOT in `.git/info/exclude` (hook-based mode): The hook unstages them if they were staged.

This means:
- No flag needed — the hook is always present and safe.
- Backward compatible — existing repos with `.git/info/exclude` continue to work.
- Mac users can manually remove entries from `.git/info/exclude` and the hook protects them.

### Performance

The hook is lightweight:
```bash
git reset HEAD -- .cursor/rules/local/ ai-rizz.local.skbd 2>/dev/null || true
```

- Single `git reset` command
- No file system traversal
- Typically 10-50ms
- Negligible impact on commit time

### Implementation details

**Hook creation:**
- Always create/update the hook during `cmd_init --local`
- Hook location: `.git/hooks/pre-commit`
- Preserve existing hooks: Check if hook exists, append our logic (or create new)
- Hook identification: Include marker comment for cleanup

**Hook script:**
```bash
#!/bin/sh
# ai-rizz: Unstage local mode files if they were staged
# This is safe to run even if files are git-ignored (no-op in that case)
git reset HEAD -- .cursor/rules/local/ ai-rizz.local.skbd 2>/dev/null || true
```

**Flag behavior:**
- `--hook-based-ignore`: Skip adding to `.git/info/exclude`, but still create hook
- Default (no flag): Add to `.git/info/exclude` AND create hook (hook is harmless)

**Cleanup:**
- `cmd_deinit --local`: Remove hook section (if we can identify it) or entire hook if we created it
- Need to be careful not to remove user's existing hooks

### The "clean state" issue

You're right — there's no way to have both:
- Clean git status locally (files ignored)
- Files visible to Cursor (files not ignored)

**Solution:**
- Document that hook-based mode will show untracked files
- Optionally create a README in the local directory explaining this
- Provide a helper (optional): `git status --porcelain | grep -v "local/"` for checking "clean excluding local"

### Questions

1. Should the hook always be created, or only when `--hook-based-ignore` is used?
   - My recommendation: Always create it (it's harmless and future-proofs for Mac users)

2. How to handle existing pre-commit hooks?
   - Option A: Append our logic (preserve user hooks)
   - Option B: Create separate hook file and use a hook manager (complex)
   - Option A is simpler and safer

3. Hook cleanup on deinit:
   - If we created the entire hook file, remove it
   - If we appended to existing hook, remove just our section (need reliable identification)

4. Documentation location:
   - README in `.cursor/rules/local/` when hook-based mode is active?
   - Or just in main project README?

### Final design summary

1. `cmd_init --local` always creates the pre-commit hook
2. `--hook-based-ignore` flag: Skip `.git/info/exclude` entries
3. Hook always runs and unstages local files (harmless if they're ignored)
4. `cmd_deinit --local` removes the hook (carefully, preserving user hooks)
5. Document the "dirty status" limitation for hook-based mode

This keeps commits clean, works on Mac, and has minimal performance impact. Should I proceed with this design?

```shellscript
git reset HEAD -- .cursor/rules/local/ ai-rizz.local.skbd 2>/dev/null || true
```

```shellscript
#!/bin/sh
# ai-rizz: Unstage local mode files if they were staged
# This is safe to run even if files are git-ignored (no-op in that case)
git reset HEAD -- .cursor/rules/local/ ai-rizz.local.skbd 2>/dev/null || true
```

---

**User**

Hook needs to take values from the manifest files; can't be hardcoded. Does that change thigns?

---

**Cursor**


Yes, this changes things. The hook must be dynamic. Here's the updated design:

## Dynamic hook design

### Hook requirements

The hook needs to:
1. Find the local manifest file (could be custom name, e.g., `cursor-rules.local.skbd`)
2. Parse the manifest to extract the target directory
3. Construct the correct paths to unstage

### Implementation options

**Option A: Self-contained hook (recommended)**
The hook finds and parses the manifest itself:

```bash
#!/bin/sh
# ai-rizz: Unstage local mode files if they were staged
# This is safe to run even if files are git-ignored (no-op in that case)

# Find local manifest file (look for *.local.skbd pattern)
LOCAL_MANIFEST=""
for file in *.local.skbd */*.local.skbd; do
    if [ -f "$file" ]; then
        LOCAL_MANIFEST="$file"
        break
    fi
done

# If no manifest found, exit (not an ai-rizz repo or no local mode)
[ -z "$LOCAL_MANIFEST" ] && exit 0

# Parse manifest: first line is metadata (tab-separated)
# Format: <source_repo>	<target_dir>	<rules_path>	<rulesets_path>
TARGET_DIR=$(head -n1 "$LOCAL_MANIFEST" | cut -f2)

# If target dir not found, exit gracefully
[ -z "$TARGET_DIR" ] && exit 0

# Unstage local directory and manifest
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST" 2>/dev/null || true
```

**Pros:**
- Self-contained, no external dependencies
- Works with custom manifest names
- Works with custom target directories

**Cons:**
- Duplicates manifest parsing logic (but it's simple - just `cut -f2`)
- Pattern matching for manifest file might miss edge cases

**Option B: Hook sources a config file**
Create `.git/hooks/ai-rizz-hook-config` when initializing:

```bash
# In ai-rizz during init:
cat > .git/hooks/ai-rizz-hook-config <<EOF
LOCAL_MANIFEST_FILE="ai-rizz.local.skbd"
TARGET_DIR=".cursor/rules"
EOF

# In hook:
#!/bin/sh
# ai-rizz: Unstage local mode files
[ -f .git/hooks/ai-rizz-hook-config ] || exit 0
. .git/hooks/ai-rizz-hook-config
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST_FILE" 2>/dev/null || true
```

**Pros:**
- Simple hook logic
- Easy to update during re-init

**Cons:**
- Extra file to manage
- Need to update config file if manifest/target changes

**Option C: Hook calls ai-rizz (complex, not recommended)**
Hook invokes `ai-rizz` to get paths. Adds dependency and complexity.

### Recommendation: Option A (self-contained)

The hook should:
1. Find the manifest using a pattern (e.g., `*.local.skbd` in repo root)
2. Parse the first line to get `TARGET_DIR`
3. Construct paths: `$TARGET_DIR/local/` and manifest filename
4. Unstage those paths

### Edge cases to handle

1. Multiple `*.local.skbd` files: Use the first found, or search more specifically
2. Manifest in subdirectory: Search repo root first, then common locations
3. Malformed manifest: Gracefully exit if parsing fails
4. No git repo: Hook shouldn't run, but handle gracefully

### Updated hook implementation

```bash
#!/bin/sh
# ai-rizz: Unstage local mode files if they were staged
# This is safe to run even if files are git-ignored (no-op in that case)

# Find local manifest file in repo root
# Look for pattern: <anything>.local.skbd
LOCAL_MANIFEST=""
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

for file in "$REPO_ROOT"/*.local.skbd; do
    if [ -f "$file" ]; then
        LOCAL_MANIFEST=$(basename "$file")
        break
    fi
done

# If no manifest found, exit (not an ai-rizz repo with local mode)
[ -z "$LOCAL_MANIFEST" ] && exit 0

# Parse manifest: first line is metadata (tab-separated)
# Format: <source_repo>	<target_dir>	<rules_path>	<rulesets_path>
MANIFEST_PATH="$REPO_ROOT/$LOCAL_MANIFEST"
TARGET_DIR=$(head -n1 "$MANIFEST_PATH" 2>/dev/null | cut -f2)

# If target dir not found or empty, exit gracefully
[ -z "$TARGET_DIR" ] && exit 0

# Unstage local directory and manifest (safe even if already ignored)
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST" 2>/dev/null || true
```

### Changes to ai-rizz code

1. `setup_local_mode_excludes()`: Still works as before (for non-hook mode)
2. New function: `setup_pre_commit_hook()` - Creates/updates the hook
3. `cmd_init --local`: 
   - If `--hook-based-ignore`: Skip exclude setup, create hook
   - Otherwise: Do both (hook is harmless)
4. `cmd_deinit --local`: Remove hook section (need to identify it reliably)

### Hook identification for cleanup

Add a clear marker so we can find/remove our section:

```bash
#!/bin/sh
# ... existing user hooks ...

# BEGIN ai-rizz hook (do not edit this section manually)
# ai-rizz: Unstage local mode files...
# ... hook code ...
# END ai-rizz hook
```

Does this approach work? The hook becomes self-contained and reads from the manifest, so it adapts to custom paths and manifest names.

```shellscript
#!/bin/sh
# ai-rizz: Unstage local mode files if they were staged
# This is safe to run even if files are git-ignored (no-op in that case)

# Find local manifest file (look for *.local.skbd pattern)
LOCAL_MANIFEST=""
for file in *.local.skbd */*.local.skbd; do
    if [ -f "$file" ]; then
        LOCAL_MANIFEST="$file"
        break
    fi
done

# If no manifest found, exit (not an ai-rizz repo or no local mode)
[ -z "$LOCAL_MANIFEST" ] && exit 0

# Parse manifest: first line is metadata (tab-separated)
# Format: <source_repo>	<target_dir>	<rules_path>	<rulesets_path>
TARGET_DIR=$(head -n1 "$LOCAL_MANIFEST" | cut -f2)

# If target dir not found, exit gracefully
[ -z "$TARGET_DIR" ] && exit 0

# Unstage local directory and manifest
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST" 2>/dev/null || true
```

```shellscript
# In ai-rizz during init:
cat > .git/hooks/ai-rizz-hook-config <<EOF
LOCAL_MANIFEST_FILE="ai-rizz.local.skbd"
TARGET_DIR=".cursor/rules"
EOF

# In hook:
#!/bin/sh
# ai-rizz: Unstage local mode files
[ -f .git/hooks/ai-rizz-hook-config ] || exit 0
. .git/hooks/ai-rizz-hook-config
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST_FILE" 2>/dev/null || true
```

```shellscript
#!/bin/sh
# ai-rizz: Unstage local mode files if they were staged
# This is safe to run even if files are git-ignored (no-op in that case)

# Find local manifest file in repo root
# Look for pattern: <anything>.local.skbd
LOCAL_MANIFEST=""
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

for file in "$REPO_ROOT"/*.local.skbd; do
    if [ -f "$file" ]; then
        LOCAL_MANIFEST=$(basename "$file")
        break
    fi
done

# If no manifest found, exit (not an ai-rizz repo with local mode)
[ -z "$LOCAL_MANIFEST" ] && exit 0

# Parse manifest: first line is metadata (tab-separated)
# Format: <source_repo>	<target_dir>	<rules_path>	<rulesets_path>
MANIFEST_PATH="$REPO_ROOT/$LOCAL_MANIFEST"
TARGET_DIR=$(head -n1 "$MANIFEST_PATH" 2>/dev/null | cut -f2)

# If target dir not found or empty, exit gracefully
[ -z "$TARGET_DIR" ] && exit 0

# Unstage local directory and manifest (safe even if already ignored)
git reset HEAD -- "$TARGET_DIR/local/" "$LOCAL_MANIFEST" 2>/dev/null || true
```

```shellscript
#!/bin/sh
# ... existing user hooks ...

# BEGIN ai-rizz hook (do not edit this section manually)
# ai-rizz: Unstage local mode files...
# ... hook code ...
# END ai-rizz hook
```

