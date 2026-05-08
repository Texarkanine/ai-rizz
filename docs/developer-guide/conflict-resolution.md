# Conflict Resolution

## Rule Mode Conflicts

When a rule exists in one mode and user adds it to another:

1. Rule is moved from current mode to target mode
2. Immediate sync updates file locations and git tracking
3. For rulesets: all constituent rules move together

## Duplicate Entries

If manual editing creates duplicates in both manifests:

1. Committed mode takes precedence
2. Local entry silently removed during sync
3. No warning shown (automatic cleanup)
