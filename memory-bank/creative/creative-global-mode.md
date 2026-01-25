# Creative Phase: Global Mode and Command Support

**Feature**: `--global` mode for ai-rizz + unified command handling
**Status**: EXPLORING
**Date**: 2026-01-25

---

## 🎨🎨🎨 ENTERING CREATIVE PHASE: ARCHITECTURE DESIGN

### Problem Statement

The current ai-rizz architecture has two modes:
- **local**: Git-ignored rules in `.cursor/rules/local/`, manifest `ai-rizz.local.skbd`
- **commit**: Git-tracked rules in `.cursor/rules/shared/`, manifest `ai-rizz.skbd`

Commands are currently:
1. Only supported via rulesets (not individual rule files)
2. Only deployable in commit mode (local mode with commands is rejected)
3. Deployed to `.cursor/commands/` when a ruleset containing `commands/` subdir is synced

**New requirements**:
1. Add `--global` mode managing `~/.cursor/` with manifest `~/ai-rizz.skbd`
2. Allow commands (`*.md`) to sit alongside rules (`*.mdc`) in the source repo
3. Enable individual command management (not just ruleset-bundled)
4. Provide warnings when entities change mode visibility

### Constraints

1. **Backwards Compatibility**: Existing `--local` and `--commit` workflows must continue to work
2. **Minimal Code Duplication**: Reuse existing patterns where possible
3. **Predictable Behavior**: Mode transitions should be intuitive and well-warned
4. **File Extension Convention**: `.mdc` = rules, `.md` = commands (in source repo `rules/` directory)
5. **Cursor Semantics**: Commands in `.cursor/commands/*.md` trigger with `/command-name`

---

## Design Question 1: Can `--global` Fit into the Existing Mode Architecture?

### Current Mode Pattern

```
Mode      | Manifest              | Target Dir                | Git Tracked
----------|----------------------|---------------------------|------------
local     | ai-rizz.local.skbd   | .cursor/rules/local/      | No
commit    | ai-rizz.skbd         | .cursor/rules/shared/     | Yes
```

### Option 1A: Global as True Third Mode (Repository-Independent)

```
Mode      | Manifest              | Target Dir                | Git Tracked | Scope
----------|----------------------|---------------------------|-------------|-------
local     | ai-rizz.local.skbd   | .cursor/rules/local/      | No          | Repo
commit    | ai-rizz.skbd         | .cursor/rules/shared/     | Yes         | Repo
global    | ~/ai-rizz.skbd       | ~/.cursor/rules/          | N/A         | User
```

**Characteristics**:
- Global mode operates INDEPENDENTLY of any repository
- Global manifest lives in home directory, not in repo
- When run outside a repo, only global mode is available
- When run inside a repo, all three modes are available
- Global entities are available in ALL repositories (via Cursor's global config)

**Implementation Impact**:
- `is_mode_active(global)` checks `~/ai-rizz.skbd` existence
- Global mode doesn't require git repository
- Conflict resolution: Global has lowest priority (repo modes override)

**Pros**:
- Clean separation of concerns
- User's global preferences never pollute repos
- Repository cloners don't get user's global stuff

**Cons**:
- Three-way conflict resolution needed
- User must manage global separately from repos

### Option 1B: Global as Pseudo-Mode (Hybrid Approach)

Global mode shares infrastructure but is accessed via different entry point:
- `ai-rizz --global init <repo>` - Initialize global management
- `ai-rizz --global add rule foo` - Add to global
- Running without `--global` in a repo uses local/commit modes

**Pros**:
- Explicit, less confusing
- Fewer accidental mode interactions

**Cons**:
- More typing for users
- Harder to see global status alongside repo status

### Recommendation: Option 1A (True Third Mode)

The third mode fits naturally into the existing architecture. The key insight is that **global mode is repo-independent** - it doesn't participate in the same conflict resolution as local/commit because it operates at a different level (user-wide vs repository-specific).

```
Priority (highest to lowest):
  1. commit (git-tracked in repo)
  2. local  (git-ignored in repo)
  3. global (user-wide, available everywhere)
```

---

## Design Question 2: How Should Commands Integrate?

### Current Command Handling

Commands are:
1. Bundled inside rulesets at `rulesets/<name>/commands/`
2. Only copied when ruleset is added in commit mode
3. Target: `.cursor/commands/` preserving structure

### Option 2A: Commands as First-Class Entities in Rules Directory

```
Source repo structure:
rules/
├── always-tdd.mdc           # Rule
├── bash-style.mdc           # Rule
├── my-command.md            # Command (NEW!)
└── another-command.md       # Command (NEW!)
```

**Detection**: File extension determines type:
- `*.mdc` → Rule → Target: `.cursor/rules/<mode>/`
- `*.md`  → Command → Target: `.cursor/commands/`

**Display in `ai-rizz list`**:
```
Available rules:
  ● always-tdd.mdc
  ◐ bash-style.mdc
  ○ /my-command.md         # Leading slash indicates command

Available rulesets:
  ● niko
    ├── main.mdc
    ├── commands
    │   ├── niko.md
    │   └── niko/
    │       └── creative.md
    └── Core/
```

**Pros**:
- Simple mental model: `rules/` contains both rules and commands
- File extension is natural discriminator
- Easy to add commands without creating rulesets

**Cons**:
- Semantic overload of `rules/` directory
- `ai-rizz add rule my-command` feels weird (it's a command)

### Option 2B: Separate Commands Directory in Source Repo

```
Source repo structure:
rules/
├── always-tdd.mdc
└── bash-style.mdc
commands/                    # NEW directory
├── my-command.md
└── another-command.md
rulesets/
└── niko/
    ├── niko/...
    └── commands/...         # Ruleset-specific commands
```

**Pros**:
- Clear separation
- `ai-rizz add command my-command` makes sense
- Consistent with rulesets having their own `commands/` subdirs

**Cons**:
- Requires new `commands/` directory
- More places to look for things
- Needs new `--commands-path` manifest field

### Option 2C: Commands Stay Ruleset-Only (Current Behavior)

Keep commands only in rulesets. If users want individual commands, they create single-command rulesets.

**Pros**:
- No changes needed to command handling
- Already works

**Cons**:
- Cumbersome for users who want one command
- Forces ruleset creation overhead

### Recommendation: Option 2A (Commands in Rules Directory)

The file extension convention is elegant and already established in Cursor's ecosystem. The `rules/` directory becomes "Cursor entities" containing both rules and commands. The display with `/prefix` for commands makes the distinction clear.

**Key insight**: When calling `ai-rizz add rule my-command.md`, we can detect it's a command and handle it appropriately. The verb "rule" is slightly imprecise but acceptable for UX simplicity.

---

## Design Question 3: Command Mode Handling with Subdirectories

### Design Evolution: Subdirectory Approach

**Key Insight**: Real-world usage (2+ months) shows that command subdirectories like `.cursor/commands/commit/niko/plan.md` (invoked as `/commit/niko/plan`) work fine in practice.

This unlocks a **fully uniform model** where commands follow the exact same patterns as rules:
| Mode   | Rules Target                  | Commands Target                  | Invocation Prefix   |
|--------|-------------------------------|----------------------------------|---------------------|
| local  | `.cursor/rules/local/`        | `.cursor/commands/local/`        | `/local/...`        |
| commit | `.cursor/rules/shared/`       | `.cursor/commands/shared/`       | `/shared/...`       |
| global | `~/.cursor/rules/ai-rizz/`    | `~/.cursor/commands/ai-rizz/`    | `/ai-rizz/...`      |

### Option 3A: Commands in All Modes (Subdir Approach) ✅ SELECTED

Allow `ai-rizz add rule my-command.md` in ANY mode:

- **local**: Command → `.cursor/commands/local/my-command.md` → `/local/my-command`
- **commit**: Command → `.cursor/commands/shared/my-command.md` → `/shared/my-command`
- **global**: Command → `~/.cursor/commands/ai-rizz/my-command.md` → `/ai-rizz/my-command`

**Massive Simplification**:
1. **DELETE** `show_ruleset_commands_error()` - no longer needed
2. **DELETE** special command mode restrictions - commands follow same rules as rules
3. **DELETE** ruleset-with-commands restrictions - same handling for all rulesets
4. **UNIFORM** sync logic - same pattern for rules and commands, different base path
5. **UNIFORM** conflict resolution - identical for all entity types

**Tradeoff**: Command invocations have mode prefix (`/shared/niko/plan` vs `/niko/plan`)

**User-validated**: This has been used successfully for 2+ months at day job.

### Recommendation: Option 3A (Subdir Approach)

The subdir approach makes the ENTIRE system uniform:
- Rules and commands follow identical mode semantics
- No special cases for commands
- No restrictions on rulesets with commands
- Maximum code reuse, minimum special-casing

---

## Design Question 4: Mode Transition Warnings

### Scenarios Requiring Warnings

**Scenario A: Entity Moving FROM Global**

User has `/my-command` globally, then runs:
```bash
$ ai-rizz add rule my-command.md --commit
```

The command will now be in THIS repo but removed from global (to avoid duplication).

**Warning**:
```
⚠️ WARNING: my-command.md was previously globally-available but will now only be available in this repository. (global → commit)
```

**Scenario B: Entity Moving TO Global FROM Commit**

User has `my-command.md` committed in a repo, then runs:
```bash
$ ai-rizz add rule my-command.md --global
```

The command will be removed from THIS repo (other devs lose it) and become global.

**Warning**:
```
⚠️ WARNING: my-command.md will be removed from this repository for other developers. (commit → global)
```

### Implementation Approach

Before adding an entity, check:
1. Is this entity already installed in a different mode?
2. Would adding it cause a mode transition?
3. If yes, print appropriate warning

```shell
check_mode_transition() {
    entity="$1"
    target_mode="$2"
    current_mode=$(get_entity_current_mode "$entity")  # Returns: global|commit|local|none
    
    if [ "$current_mode" = "none" ]; then
        return 0  # No warning needed
    fi
    
    if [ "$current_mode" = "$target_mode" ]; then
        return 0  # Same mode, no warning
    fi
    
    # Mode transition detected
    case "$current_mode→$target_mode" in
        "global→commit"|"global→local")
            warn "⚠️ WARNING: $entity was previously globally-available but will now only be available in this repository. ($current_mode → $target_mode)"
            ;;
        "commit→global")
            warn "⚠️ WARNING: $entity will be removed from this repository for other developers. ($current_mode → $target_mode)"
            ;;
        "local→global")
            warn "⚠️ WARNING: $entity will be removed from this repository and become globally-available. ($current_mode → $target_mode)"
            ;;
        # Other transitions as needed
    esac
}
```

---

## Design Question 5: Ruleset-Bundled Commands + Global Mode Conflict

### The Scenario

User adds ruleset `niko` in commit mode:
```bash
$ ai-rizz add ruleset niko --commit
```

This deploys:
- Rules to `.cursor/rules/shared/`
- Commands to `.cursor/commands/`

Later, user wants `/niko/creative` command globally (in all repos):
```bash
$ ai-rizz add rule niko/creative.md --global
```

**Problem**: The command is already deployed in this repo via the ruleset. What happens?

### Option 5A: Allow Duplication (Repo + Global)

Command exists in BOTH:
- `.cursor/commands/niko/creative.md` (from ruleset)
- `~/.cursor/commands/niko/creative.md` (global copy)

**Behavior**: Cursor loads both, repo copy likely takes precedence.

**Pros**:
- Simple implementation
- User gets what they asked for

**Cons**:
- Duplication is wasteful
- Potential confusion about which version is active
- Updates require syncing both

### Option 5B: Block Adding Ruleset Commands Individually

```bash
$ ai-rizz add rule niko/creative.md --global
Error: niko/creative.md is part of ruleset 'niko' which is committed to this repository.
To make this command global, remove the ruleset and add it globally instead.
```

**Pros**:
- Forces explicit decisions
- No silent duplication

**Cons**:
- Frustrating if user just wants one command global
- Breaks down when rulesets contain many commands

### Option 5C: Warn But Allow (User Decides)

```bash
$ ai-rizz add rule niko/creative.md --global
⚠️ WARNING: niko/creative.md is already deployed in this repository via ruleset 'niko'.
Adding it globally will create a duplicate. The repository version will take precedence in this repo.
Continue? [y/N]
```

**Pros**:
- Informed user choice
- Flexible

**Cons**:
- Interactive prompt (bad for scripting)
- Still has duplication issue

### Option 5D: Source-Level Detection Only

Only detect conflicts for DIRECTLY added entities, not ruleset-bundled ones.

If `niko/creative.md` isn't in ANY manifest directly (it's bundled), treat it as available.
Ruleset commands don't "claim" their individual files for conflict detection.

**Behavior**:
```bash
$ ai-rizz add rule niko/creative.md --global
# No warning - the command isn't directly managed in any manifest
# Copies to ~/.cursor/commands/niko/creative.md
```

**Pros**:
- Simple conflict detection (manifest-only)
- Users can extract commands from rulesets

**Cons**:
- Duplication still possible
- Might be surprising that repo has two copies

### Recommendation: Option 5D (Source-Level Detection Only)

Conflict detection should operate at the **manifest entry level**, not the deployed file level. This is consistent with how rules work:
- If `rulesets/niko` is in manifest, the ruleset is tracked
- Individual files within aren't tracked separately
- User can add individual rules that happen to also be in rulesets

This creates clear semantics:
- **Manifest entry conflict** = same entry in multiple modes → handled by existing conflict resolution
- **File-level duplication** = same file deployed by different entries → allowed, priority rules apply

---

## Design Question 6: Global Glyph and Display

### Proposed Glyphs

```
● = committed (git-tracked in repo)
◐ = local (git-ignored in repo)
★ = global (user-wide)
○ = uninstalled
```

### List Display

```
$ ai-rizz list
Available rules:
  ● always-tdd.mdc              # Committed to this repo
  ◐ bash-style.mdc              # Local to this repo (not tracked)
  ★ my-personal-rule.mdc        # Available everywhere (from ~/.cursor)
  ○ unused-rule.mdc             # Not installed

Available commands:
  ● /niko                       # Committed (from ruleset)
  ★ /my-global-cmd              # Global (available everywhere)
  ○ /unused-cmd                 # Not installed

Available rulesets:
  ● niko
    ├── main.mdc
    └── commands/
        └── niko.md
```

**Notes**:
- Commands displayed with leading `/` to match Cursor invocation
- Priority display: ● > ◐ > ★ (strongest mode wins for display)
- If same entity is in multiple modes, show highest priority glyph

---

## Design Question 7: Global Mode Initialization

### Where Does Global Manifest Live?

**Option**: `~/ai-rizz.skbd`

Format (same as repo manifests):
```
https://github.com/user/cursor-rules.git	.cursor/rules	rules	rulesets
always-tdd.mdc
my-personal-command.md
```

### Initialization Command

```bash
# Initialize global mode
$ ai-rizz init https://github.com/user/cursor-rules.git --global

# Or if already initialized in a repo, extend to global
$ ai-rizz init --global  # Uses same source repo as current repo
```

### Global Mode Without Repository

When run outside any git repository:
```bash
$ cd ~
$ ai-rizz list
# Only shows global entities (no repo-specific modes available)
```

---

## Summary of Recommendations

| Question | Recommendation |
|----------|---------------|
| 1. Mode Architecture | **Option 1A**: True third mode, independent of repo |
| 2. Command Integration | **Option 2A**: Commands as `*.md` in `rules/`, detected by extension |
| 3. Command Mode Handling | **Option 3A**: Subdir approach - commands in ALL modes (uniform with rules) |
| 4. Mode Transition Warnings | Implement warnings for all mode transitions |
| 5. Ruleset Command Conflicts | **Option 5D**: Manifest-level detection only |
| 6. Display | `★` for global, commands prefixed with `/` |
| 7. Initialization | `~/ai-rizz.skbd` for global manifest |

### Final Target Directory Structure

| Mode   | Rules Target                  | Commands Target                  | Invocation   |
|--------|------------------------------|----------------------------------|--------------|
| local  | .cursor/rules/local/         | .cursor/commands/local/          | /local/...   |
| commit | .cursor/rules/shared/        | .cursor/commands/shared/         | /shared/...  |
| global | ~/.cursor/rules/ai-rizz/     | ~/.cursor/commands/ai-rizz/      | /ai-rizz/... |

### Entity Type Mode Support (All Uniform)

| Entity Type | Local | Commit | Global |
|-------------|-------|--------|--------|
| Rule (`*.mdc`) | ✅ | ✅ | ✅ |
| Command (`*.md`) | ✅ | ✅ | ✅ |
| Ruleset (any) | ✅ | ✅ | ✅ |

---

## Implementation Complexity Assessment

### Low Complexity (Reuse Existing Patterns)

1. **Global manifest parsing**: Same format as existing manifests
2. **`is_mode_active(global)`**: Check `~/ai-rizz.skbd` existence
3. **Sync to global**: Same `sync_manifest_to_directory` with `~/.cursor/rules`
4. **Glyph display**: Add `GLOBAL_GLYPH="★"`

### Medium Complexity (Extensions)

1. **Command detection**: Check `.md` extension in `rules/` directory
2. **Command routing**: Route `.md` files to `.cursor/commands/` not `.cursor/rules/`
3. **Mode transition warnings**: Add checks before add operations
4. **Global commands sync**: Target `~/.cursor/commands/`

### Higher Complexity (New Logic)

1. **Three-way mode selection**: When all three modes active, need clear priority
2. **Cross-scope detection**: Checking if entity exists in global from within repo
3. **Global initialization outside repo**: Handle non-repo context
4. **Command listing**: Separate section or mixed with rules?

### Estimated Code Impact

- New functions: ~5-8 functions (~200-300 lines)
- Modified functions: ~10-15 functions
- New test cases: ~20-30 test cases
- Overall: **Medium-sized enhancement**, fits existing architecture well

---

## Open Questions for User Decision

1. **Should `ai-rizz add rule foo.md` automatically detect commands?**
   - Or require `ai-rizz add command foo.md`?
   - Recommendation: Auto-detect by extension to minimize new verbs

2. **Should global mode require explicit `--global` flag for all operations?**
   - Or should it auto-detect when running outside repos?
   - Recommendation: `--global` always required (explicit > implicit)

3. **What about promoting commands?**
   - `ai-rizz promote rule foo.md` - Move from local → commit
   - Should we support `promote --global`?
   - Recommendation: Support all promotion paths

4. **Should `ai-rizz list` show global entities when in a repo?**
   - Or only show repo-specific entities unless `--global` specified?
   - Recommendation: Show all, use glyphs to distinguish

---

## 🎨🎨🎨 EXITING CREATIVE PHASE

**Conclusion**: The `--global` mode fits naturally into ai-rizz's existing architecture. Commands can integrate as `.md` files alongside `.mdc` rules, with restrictions preventing local-mode commands (since Cursor doesn't support local commands). The main complexity is in three-way mode handling and cross-scope detection, but these are tractable extensions of existing patterns.

**Recommended Next Steps**:
1. Validate design decisions with stakeholder
2. Create detailed implementation plan following TDD
3. Implement in phases: (1) Global mode infrastructure, (2) Command support, (3) Mode warnings

