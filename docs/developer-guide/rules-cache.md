# Rules Cache

`ai-rizz` serves rules from a single source repository, for each repository you use it in. It stores copies of source repositories in `$HOME/.config/ai-rizz/repos/PROJECT-NAME/repo/` where PROJECT-NAME is the current directory name. This allows different projects to use different source repositories without conflicts.

Global [mode](../user-guide/rule-modes.md) uses a separate cache at `$HOME/.config/ai-rizz/repos/_ai-rizz.global/repo/` shared across all repositories.
