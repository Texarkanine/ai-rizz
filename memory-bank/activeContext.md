# Memory Bank: Active Context

## Current Focus

**Task**: Make Hook-Based Ignore the Default Local Mode
**Phase**: Planning Complete → Ready for BUILD
**Branch**: `local-mode-fix`

## Working On

Planning complete. Ready to begin TDD implementation.

## Recent Decisions

- Assessed as Level 2 complexity (Simple Enhancement)
- Hook-based mode will become default due to Cursor Windows compatibility issues
- Legacy git-exclude behavior preserved via new `--git-exclude-ignore` flag
- `--hook-based-ignore` kept as no-op for backwards compatibility
- No creative phases needed - straightforward flag/default swap

## Key Implementation Details

**Files to Modify:**
1. `ai-rizz` - Main script (~6 locations)
2. `tests/unit/test_hook_based_local_mode.test.sh` - Update/add tests
3. `tests/unit/test_initialization.test.sh` - Update assertions

**Critical Changes:**
- Line ~2491: `ci_hook_based=false` → `ci_hook_based=true`
- Add `--git-exclude-ignore` flag parsing
- Update help text (line ~4588)

## Next Steps

1. Write failing tests first (TDD)
2. Implement code changes
3. Verify all tests pass
4. Run full test suite

---

## Context Template

When working on a task, populate this section:

```markdown
**Task**: <task name>
**Phase**: <current phase>
**Branch**: `<branch-name>`

## Working On

<current focus>

## Recent Decisions

<recent decisions>

## Next Steps

<immediate next steps>
```
