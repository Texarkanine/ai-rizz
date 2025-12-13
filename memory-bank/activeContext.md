# Memory Bank: Active Context

## Current Focus
PLAN Mode - Plan Refined After Creative Phase: Preserve Structure for File Rules

## Status
Creative phase completed for ruleset rule structure design:
- **Design Decision**: **Finish Support for File Rules in Rulesets (Preserve Structure)** (Option 1) ⭐
- **Rationale**: User needs to ship large rule trees (55+ rules) in rulesets like `.cursor/rules/isolation_rules`
- **Document**: `memory-bank/creative/creative-ruleset-rule-structure.mdc`

Implementation plan refined for 2 bug fixes:
1. **Bug 1**: Commands not removed when ruleset is removed
2. **Bug 2**: File rules in subdirectories are flattened (should preserve structure)

**Task Complexity**: Level 2 (Simple Enhancement - Bug Fixes)

**Key Insights**:
- Bug 1: Remove commands when ruleset removed (no need to check other rulesets - error condition if conflicts)
- Bug 2: Preserve directory structure for file rules, keep symlinks flat
- Symlinked rules: Copy flat (all instances are the same rule)
- File rules: Preserve structure (URI is `ruleset/path/to/rule.mdc`)

## Latest Changes
- Creative phase completed: Design decision to **finish support for file rules in subdirectories** (preserve structure)
- **Key insight**: User needs to ship large rule trees (55+ rules) in rulesets like `.cursor/rules/isolation_rules`
- Implementation plan refined: Preserve structure for file rules, keep symlinks flat
- Plan includes TDD approach: write failing tests first, then implement fixes
- Components to modify:
  - `cmd_remove_ruleset()` - Add command removal logic
  - `copy_entry_to_target()` - Detect symlink vs file, preserve structure for files
  - `sync_manifest_to_directory()` - Update cleanup to handle nested `.mdc` files
  - New function: `remove_ruleset_commands()` - Remove commands when ruleset removed
- Ready for BUILD mode implementation (following TDD workflow)

