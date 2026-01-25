# TASK ARCHIVE: Global Mode + Command Support

## METADATA

| Field | Value |
|-------|-------|
| Task ID | global-mode-command-support |
| Complexity | Level 4 (Architectural) |
| Start Date | 2026-01-25 |
| End Date | 2026-01-25 |
| Branch | `command-support-2` |
| PR | [`#15`](https://github.com/Texarkanine/ai-rizz/pull/15) |
| Final Test Count | 30 (23 unit + 7 integration) |

---

## SUMMARY

Added a third mode (`--global`/`-g`) to ai-rizz and unified command (`*.md`) handling across all modes. This was an 8-phase implementation spanning approximately one day of development.

**Key Deliverables:**
- Global mode with user-wide manifest at `~/ai-rizz.skbd`
- Global rules/commands stored in `~/.cursor/rules/ai-rizz/` and `~/.cursor/commands/ai-rizz/`
- Unified command detection via `*.md` extension
- Commands supported in all three modes (local, commit, global)
- Cache isolation with `GLOBAL_REPO_DIR` (`_ai-rizz.global`)
- Mode transition warnings for cross-mode operations
- Global-only context (works outside git repositories)

---

## REQUIREMENTS

### User Stories
1. As a user, I want global rules that apply everywhere without per-repo setup
2. As a user, I want commands (`.md` files) to work in local mode via subdirectories
3. As a user, I want to see which rules are global vs local/commit in `list` output
4. As a user, I want warnings when moving entities between modes with different source repos

### Technical Requirements
1. Global mode must work outside git repositories
2. Global cache must not conflict with repo-specific caches
3. All existing local/commit functionality must remain intact
4. Commands must support all three modes uniformly

---

## IMPLEMENTATION

### Phase Breakdown

| Phase | Focus | Key Changes |
|-------|-------|-------------|
| 1 | Global Mode Infrastructure | `--global` flag, `~/ai-rizz.skbd`, `GLOBAL_MANIFEST_FILE` |
| 2 | Command Support | `*.md` detection, `.cursor/commands/{local,shared,ai-rizz}/` |
| 3 | List Display | `★` glyph for global, `/` prefix for commands |
| 4 | Mode Transition Warnings | Warnings when source repos differ between modes |
| 5 | Deinit and Cleanup | `--global` for deinit, cleanup logic |
| 6 | Global-Only Context | Global mode outside git repositories |
| 7 | Cache Isolation Bug Fix | `GLOBAL_REPO_DIR`, fixed `_ai-rizz.global` path |
| 8 | Final Bug Fixes | `cmd_remove_rule` global support, test infrastructure |

### Key Design Decisions

1. **Global as True Third Mode**: Global mode is repo-independent, unlike local/commit which require git
2. **Commands via `*.md` Extension**: Uniform detection avoids special-casing
3. **Subdirectory Approach for Commands**: `/local/`, `/shared/`, `/ai-rizz/` directories enable all modes
4. **`★` Glyph for Global**: Visual distinction from local (`●`) and commit (`✓`)
5. **Gated Cross-Mode Operations**: Manifest-level conflict detection only
6. **Fixed Global Cache Path**: `_ai-rizz.global` cannot conflict with git repo names

### Files Changed

| File | Lines Changed | Description |
|------|--------------|-------------|
| `ai-rizz` | ~700 | Global mode support, command handling, cache isolation |
| `tests/common.sh` | ~50 | HOME isolation for test infrastructure |
| `README.md` | ~100 | Documentation for global mode |
| `tests/unit/*.test.sh` | ~400 | 8 new test files for new functionality |

### New Test Suites

- `test_cache_isolation.test.sh` - 12 tests for GLOBAL_REPO_DIR isolation
- `test_command_entity_detection.test.sh` - Command detection tests
- `test_command_modes.test.sh` - Commands in all modes
- `test_command_sync.test.sh` - Command sync operations
- `test_global_mode_detection.test.sh` - Global mode detection
- `test_global_mode_init.test.sh` - Global mode initialization
- `test_global_only_context.test.sh` - Operations outside git repos
- `test_mode_transition_warnings.test.sh` - Cross-mode warnings

---

## TESTING

### Test Strategy
- TDD approach: tests written before implementation
- Each phase independently testable
- Integration tests for cross-mode operations

### Final Test Results
- **Unit Tests**: 23/23 pass
- **Integration Tests**: 7/7 pass
- **Total**: 30/30 pass

### Key Test Scenarios Covered
1. Global mode initialization inside/outside git repos
2. Command detection and sync in all modes
3. Cache isolation between global and local/commit
4. Mode transition warnings with different source repos
5. Global mode rule add/remove/list cycle
6. Deinit with `--global` flag

---

## LESSONS LEARNED

### Technical Lessons

1. **Audit Shared State When Adding Modes**: The `REPO_DIR` assumption was deeply embedded. When adding new dimensions, systematically review all cached/shared state.

2. **Read from Source When Comparing**: When comparing values that may be cached, read from source (manifest files) rather than relying on potentially-stale cached variables.

3. **Test Infrastructure Must Evolve**: As the system grows, test infrastructure needs corresponding updates. HOME isolation became critical for global mode tests.

4. **Fixed Paths for Global State**: Global/user-wide features should use deterministic paths that don't depend on current directory or context.

### Process Lessons

1. **Challenge Assumptions Early**: The "commands can't have local mode" assumption was wrong. User's 2+ months real-world validation enabled massive simplification.

2. **Creative Phase Pays Off**: The structured creative phase for cache isolation led to a well-reasoned solution (Option 2E).

3. **Bug Discovery is Success**: Finding bugs during testing (not production) validates investment in comprehensive tests.

4. **Design Evolution is Healthy**: `creative-ruleset-command-modes.md` was SUPERSEDED mid-exploration when better insights emerged.

### Recommendations for Future

1. **State Audit Checklist**: When adding modes, create explicit checklist of global variables, cached metadata, path functions, and test assumptions.

2. **Earlier Integration Testing**: Add cross-mode scenario tests earlier in development.

3. **Test Template Updates**: Standard test template should always include HOME isolation.

---

## REFERENCES

### Creative Phase Documents
- `creative-global-mode.md` - Initial global mode design
- `creative-repo-cache-isolation.md` - Cache isolation solution (Option 2E)
- `creative-ruleset-command-modes.md` - Command modes (SUPERSEDED)

### Reflection Documents
- `reflection-global-mode-command-support.md` - Phases 1-7 reflection
- `reflection-phase-8-bug-fixes.md` - Phase 8 final cleanup
- `reflection-cmd-list-global-repo-dir.md` - List display updates

### Related PRs
- PR #15: Global Mode + Command Support

---

## METRICS

| Metric | Value |
|--------|-------|
| Total phases | 8 |
| Implementation time | ~1 day |
| Creative phase documents | 3 |
| Reflection documents | 3 |
| New test files | 8+ |
| Final test count | 30 (23 unit + 7 integration) |
| Lines changed in ai-rizz | ~700 |
| Dead code removed | 175 lines |
| Design options evaluated | 15+ (across 3 creative docs) |
| Bugs caught before merge | 5 |
