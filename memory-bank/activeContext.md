# Memory Bank: Active Context

## Current Focus

**Task**: Add `--global` mode and unified command support to ai-rizz
**Phase**: Planning Complete - Ready for Implementation
**Branch**: `command-support-2`

## Recent Decisions

### Design Decisions (from Creative Phase)

1. **Global Mode**: True third mode, repo-independent
   - Manifest: `~/ai-rizz.skbd`
   - Rules: `~/.cursor/rules/ai-rizz/`
   - Commands: `~/.cursor/commands/ai-rizz/`

2. **Command Handling**: Subdirectory approach (uniform with rules)
   - Local: `.cursor/commands/local/` → `/local/...`
   - Commit: `.cursor/commands/shared/` → `/shared/...`
   - Global: `~/.cursor/commands/ai-rizz/` → `/ai-rizz/...`

3. **No More Restrictions**: DELETE `show_ruleset_commands_error()`
   - Commands can be in ANY mode
   - Rulesets with commands can be in ANY mode
   - Fully uniform entity handling

4. **Mode Transition Warnings**: Implemented for scope changes
   - `global → commit`: "was globally-available, now repo-only"
   - `commit → global`: "will be removed from repo for other devs"

5. **Display**: 
   - `★` for global mode
   - `/` prefix for commands
   - Priority: `●` > `◐` > `★`

## Key Files Modified

- `memory-bank/creative/creative-global-mode.md` - Design exploration
- `memory-bank/creative/creative-ruleset-command-modes.md` - Policy decisions
- `memory-bank/tasks.md` - Implementation plan

## Implementation Order

1. Phase 1: Global Mode Infrastructure
2. Phase 2: Command Support Infrastructure  
3. Phase 3: List Display Updates
4. Phase 4: Mode Transition Warnings
5. Phase 5: Deinit and Cleanup
6. Phase 6: Integration and Edge Cases

## Next Immediate Step

**Create test stubs for Phase 1** following TDD:
- `test_global_mode_init.test.sh`
- `test_global_mode_detection.test.sh`

Then implement Phase 1 constants, mode detection, and initialization.

## Open Questions

None - all design questions resolved in creative phase.

## Blockers

None.