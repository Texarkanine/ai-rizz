# Improve Rule/Ruleset Management with Test-Driven Development

This pull request improves the rule and ruleset removal functionality in ai-rizz using test-driven development with shunit2. The changes follow the plan outlined in the fix-the-tests-plan.md document.

## Key Changes

1. **Created a Common Test Helper Library**
   - Added `tests/common.sh` with shared test utilities and helper functions
   - Centralized test environment setup and teardown
   - Added assertion helpers for consistent testing

2. **Created Comprehensive shunit2 Tests**
   - Added `tests/unit/sync_shunit.test.sh` with detailed tests for:
     - Rule/ruleset cleanup during sync
     - Rule removal (preserving rules still needed by rulesets)
     - Ruleset removal (cleaning up orphaned rules)
     - Edge cases like non-existent rules/rulesets

3. **Improved Implementation**
   - Fixed a bug in cmd_sync to handle the case where there are no rulesets in the manifest
   - Verified that the existing implementations of cmd_remove_rule and cmd_remove_ruleset were already properly delegating to cmd_sync

4. **Updated Build System and Documentation**
   - Added a `test` target to the Makefile
   - Updated `run_tests.sh` to handle the new test format
   - Updated the README to document the testing approach with examples

## Testing

All tests are now passing. You can run the tests with:

```
make test
```

Or run individual test files:

```
sh tests/unit/sync_shunit.test.sh
```

## Implementation Approach

The implementation follows the DRY principle by centralizing cleanup logic in the `cmd_sync` function. This ensures that rules are properly retained when still needed and removed when orphaned, regardless of whether they're removed directly or via ruleset removal.

The changes maintain backward compatibility while improving code robustness.

## Future Work

- Consider adding more edge case tests
- Add integration tests for complete workflows
- Consider adding test coverage reporting 