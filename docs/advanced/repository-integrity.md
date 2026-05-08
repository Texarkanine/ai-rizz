# Repository Integrity

## Source Repository Consistency

Local and commit modes must use the same source repository. If they differ, `ai-rizz` will complain and ask you to resolve it.

Global mode can use a different source repository, allowing you to share one set of rules globally while using project-specific rules locally.

## Conflict Resolution

When both modes contain the same rule/ruleset:

- **Commit mode wins**: Committed rules take precedence
- **Automatic cleanup**: Conflicting local entries are silently removed
