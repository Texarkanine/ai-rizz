# Creative Phase: Ruleset Command Mode Restrictions

**Feature**: Reconsidering the "commit-only for rulesets with commands" rule
**Status**: EXPLORING
**Date**: 2026-01-25
**Depends On**: `creative-global-mode.md`

---

## 🎨🎨🎨 ENTERING CREATIVE PHASE: POLICY DESIGN

### Problem Statement

**Current Rule** (in `show_ruleset_commands_error`):
```
Rulesets containing a `commands/` subdirectory MUST be added in commit mode.
```

**Origin**: This rule was created specifically because of the Niko ruleset:
- Niko contains commands (`/niko`, `/niko/plan`, `/niko/creative`, etc.)
- Niko's commands emit files into `memory-bank/` in the repository
- If Niko were local/global, the memory-bank files would be committed to git, but collaborators who clone the repo wouldn't have Niko installed, leading to confusion

**The Question**: Now that we're adding `--global` mode with transition warnings, should we:
1. Keep the blanket restriction (commit-only)?
2. Relax it to allow global mode?
3. Remove it entirely (allow all modes)?
4. Make it per-ruleset configurable?

### Constraints

1. **Backwards compatibility**: Existing Niko users shouldn't suddenly break
2. **User safety**: Don't let users easily shoot themselves in the foot
3. **Flexibility**: Not all rulesets have Niko's "emits committed files" characteristic
4. **Simplicity**: Prefer simple rules over complex per-ruleset configuration

---

## Analysis: Why Was the Rule Created?

### The Niko-Specific Problem

```
Scenario: User adds Niko in LOCAL mode
├── User runs /niko/plan
├── Niko creates memory-bank/tasks.md, memory-bank/progress.md
├── User commits these files to git
├── Collaborator clones repo
├── Collaborator sees memory-bank/ but has no Niko
├── Collaborator is confused: "What are these files? How do I use them?"
└── BAD OUTCOME: Committed artifacts without committed tooling
```

### Key Insight: The Problem Isn't Commands, It's File Emission

The rule "rulesets with commands must be commit" conflates two things:
1. **Commands exist in a ruleset** (structural fact)
2. **Commands emit files into the repository** (behavioral characteristic)

Not all commands emit files! A command could:
- Just run analysis and print output
- Modify only ignored files (`.gitignore`d paths)
- Only affect user-global state (`~/.cursor/`)

### Examples of Hypothetical Rulesets

| Ruleset | Has Commands | Emits Repo Files | Should Require Commit? |
|---------|--------------|------------------|------------------------|
| niko | Yes | Yes (memory-bank/) | Yes - others need the ruleset to understand the files |
| code-reviewer | Yes | No (just prints) | No - fine in any mode |
| formatter-helper | Yes | No (modifies ignored files) | No - fine in any mode |
| test-generator | Yes | Yes (test files) | Maybe - test files are self-explanatory |

---

## Design Options

### Option A: Keep the Blanket Restriction (Status Quo + Global)

Extend the current rule to:
```
Rulesets with commands/ can ONLY be added in commit mode.
Global mode is treated like local for this restriction.
```

**Behavior**:
```bash
$ ai-rizz add ruleset niko --local
Error: Ruleset 'niko' contains commands and must be added in commit mode.

$ ai-rizz add ruleset niko --global
Error: Ruleset 'niko' contains commands and must be added in commit mode.

$ ai-rizz add ruleset niko --commit
Success.
```

**Pros**:
- Simplest to implement
- Maximum safety
- Clear rule

**Cons**:
- Overly restrictive for rulesets that don't emit repo files
- Prevents legitimate use cases (personal tooling rulesets)
- Doesn't leverage global mode's strengths

### Option B: Allow Global, Block Local

```
Rulesets with commands/ can be added in commit OR global mode.
Local mode remains blocked.
```

**Rationale**:
- **Commit**: Commands available to all collaborators, files they emit are understood
- **Global**: Commands only available to this user, files they emit are user's responsibility
- **Local**: Weird middle ground - repo-specific but not shared, confusing

**Behavior**:
```bash
$ ai-rizz add ruleset niko --local
Error: Rulesets with commands cannot be added in local mode.
Use --commit (shared with team) or --global (personal, all repos).

$ ai-rizz add ruleset niko --global
⚠️ WARNING: Ruleset 'niko' contains commands that may emit files into repositories.
These files will be visible to collaborators who don't have Niko installed.
Continue? [Y/n]
# Or just a warning, no prompt

$ ai-rizz add ruleset niko --commit
Success.
```

**Pros**:
- Enables global tooling use case
- Warning informs user of potential issue
- Blocks the truly confusing case (local)

**Cons**:
- Slightly more complexity
- Users might still get confused with global + emitted files

### Option C: Remove the Restriction Entirely

Allow rulesets with commands in ANY mode, with appropriate warnings.

**Behavior**:
```bash
$ ai-rizz add ruleset niko --local
⚠️ WARNING: Ruleset 'niko' contains commands that may emit files into this repository.
These files will be visible to collaborators who don't have Niko installed locally.
Added ruleset: niko (local)

$ ai-rizz add ruleset niko --global  
⚠️ WARNING: Ruleset 'niko' contains commands that may emit files into repositories.
These files will be visible to collaborators who don't have Niko installed.
Added ruleset: niko (global)

$ ai-rizz add ruleset niko --commit
Added ruleset: niko (commit)
```

**Pros**:
- Maximum flexibility
- Treats users as capable of understanding warnings
- Consistent with "rules can be in any mode" behavior

**Cons**:
- Users might ignore warnings and create confusion
- Niko specifically REALLY should be committed

### Option D: Per-Ruleset Configuration

Allow rulesets to declare their mode requirements in a config file:

```yaml
# rulesets/niko/ruleset.yaml
name: niko
requires_commit: true
reason: "Niko emits memory-bank files that should be understood by all collaborators."
```

**Behavior**:
```bash
$ ai-rizz add ruleset niko --local
Error: Ruleset 'niko' requires commit mode.
Reason: Niko emits memory-bank files that should be understood by all collaborators.
```

For rulesets without config, allow any mode.

**Pros**:
- Precise control per ruleset
- Self-documenting
- Rule author controls behavior

**Cons**:
- More complexity in ai-rizz
- Requires updating existing rulesets
- Overkill for current use case (only Niko)

### Option E: Documentation-Only Approach

Remove the code restriction. Add clear documentation to Niko's README:

```markdown
## Installation

Niko SHOULD be installed in commit mode so all collaborators have access:

    ai-rizz add ruleset niko --commit

Installing in local or global mode will cause memory-bank files to appear
in your repository without the tooling to manage them being available to
other developers.
```

**Pros**:
- Simplest code change (remove restriction)
- Respects user autonomy
- README is the right place for usage guidance

**Cons**:
- Users don't read READMEs
- No runtime protection

---

## Decision Framework

### Questions to Guide the Choice

1. **How often will users want rulesets with commands in non-commit mode?**
   - Rarely: Keep restriction (Option A)
   - Sometimes: Warning-based approach (Option B or C)
   - Often: Remove restriction (Option E)

2. **How bad is the failure mode?**
   - Confusing but recoverable: Warnings are sufficient
   - Data loss or breakage: Hard restriction needed

3. **Is Niko special, or representative of future rulesets?**
   - Niko is special: Per-ruleset config (Option D)
   - All command-rulesets are similar: General rule (A, B, or C)

### Assessment

| Question | Answer | Implication |
|----------|--------|-------------|
| Frequency of non-commit desire | Moderate (personal tooling) | Allow with warnings |
| Failure mode severity | Confusing, not catastrophic | Warnings sufficient |
| Niko special? | Yes, but not worth special code | Document in README |

---

## SUPERSEDED: Subdir Approach Eliminates All Restrictions

**UPDATE**: After further discussion, we're adopting the **subdirectory approach** for commands:

```
Mode      | Commands Target                | Invocation
----------|-------------------------------|------------------
local     | .cursor/commands/local/       | /local/...
commit    | .cursor/commands/shared/      | /shared/...
global    | ~/.cursor/commands/ai-rizz/   | /ai-rizz/...
```

This makes the ENTIRE exploration above **obsolete**. With subdirectories:

1. **Commands can be in ANY mode** - just like rules
2. **Rulesets with commands can be in ANY mode** - no special restrictions
3. **DELETE `show_ruleset_commands_error()`** - no longer needed
4. **DELETE all command/ruleset mode restrictions** - fully uniform model

---

## Revised Summary

| Entity Type | Local | Commit | Global |
|-------------|-------|--------|--------|
| Rule (`*.mdc`) | ✅ | ✅ | ✅ |
| Command (`*.md`) | ✅ | ✅ | ✅ |
| Ruleset (any) | ✅ | ✅ | ✅ |

**No special cases. No restrictions. Fully uniform.**

---

## 🎨🎨🎨 EXITING CREATIVE PHASE

**Conclusion**: The subdirectory approach for commands (validated by 2+ months real-world usage) eliminates ALL the complexity we were trying to manage. Commands become just another entity type with a different target directory but identical mode semantics.

**Changes from Current Behavior**:
1. **DELETE** `show_ruleset_commands_error()` entirely
2. **DELETE** check for commands in local mode
3. **ADD** commands subdir structure: `.cursor/commands/{local,shared}/`
4. **ADD** global commands to `~/.cursor/commands/ai-rizz/`
5. **UPDATE** command invocations have mode prefix: `/shared/niko/plan`, `/ai-rizz/my-cmd`

**Documentation**: Update Niko README to note the new invocation: `/shared/niko/plan` (or `/ai-rizz/niko/plan` if global)

