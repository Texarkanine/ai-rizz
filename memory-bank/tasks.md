# Memory Bank: Tasks

## Current Task
Add targeted and limited support for `commands` subdirectory in rulesets to enable delivery of cursor-memory-bank commands to a "rules" repo.

## Status
- [x] Task definition
- [x] Complexity determination
- [ ] Implementation plan
- [ ] Execution
- [ ] Documentation

## Requirements

### Core Requirements
1. Rulesets can have a special `commands` subdirectory
   - Subdirs work fine in rulesets for RULES currently (can be symlinks or regular dirs)
2. Commands in a ruleset must be committed (per blog post requirement)
   - Rulesets with `commands` subdir must error if trying to add in "local" mode
   - OR accept `/local/` prefix on all commands (creative decision needed)
   - Local commands are out of scope, but need to prevent damaging operations
3. Build a "memory-bank" ruleset with:
   - `commands/` subdir containing command files
   - Subdirs of all non-symlinked rules
   - Only addable in commit mode (memory bank MUST be committed anyway)
4. Commands local to ruleset won't show up in `ai-rizz list` (same as ruleset-local rules)
   - No need for root `commands` folder
   - No need for `ai-rizz add command ...` implementations

### Workflow
```
ai-rizz init --local
ai-rizz add ruleset memory-bank
# ERROR! - helpful message about how sets with commands MUST be committed
ai-rizz init --commit
ai-rizz add ruleset memory-bank
```
This should:
- Copy `rulesets/memory-bank/commands/*` to `.cursor/commands/`
- Populate (committable) rules into `.cursor/rules/shared` per normal

## Complexity Level
**Level 3: Intermediate Feature**

### Complexity Analysis
- **Scope**: Multiple components (ruleset handling, sync logic, error checking)
- **Design Decisions**: Required (how to detect commands, error handling approach)
- **Risk**: Moderate (affects core ruleset functionality)
- **Implementation Effort**: Moderate (days to 1-2 weeks)
- **Components Affected**:
  - `cmd_add_ruleset()` function
  - `sync_manifest_to_directory()` / `copy_entry_to_target()` functions
  - Error handling for local mode restrictions
  - Command file copying logic

