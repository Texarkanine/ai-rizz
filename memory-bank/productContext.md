# Product Context

## Target Audience

Developers who use AI assistants (primarily Cursor) and want to manage shared or personal AI rule configurations across projects. Teams who want to standardize AI assistant behavior via versioned rule repositories.

## Use Cases

- **Personal rules**: Add AI rules to a project git-ignored (local mode), for personal workflows
- **Team rules**: Add AI rules committed to the repo (commit mode), for shared team behavior
- **Global rules**: Add AI rules across all projects (global mode), for universal behaviors
- **Ruleset management**: Bundle related rules into rulesets for one-command installation
- **Skills**: Install reusable AI skill directories (e.g., multi-step workflow guides) to `.cursor/skills/`
- **Listing**: View all available rules/commands/skills with their installation status

## Key Benefits

- Single CLI to manage Cursor AI rules from a remote source repo
- Three modes (local/commit/global) for fine-grained control over which rules are shared
- Automatic conflict resolution when rules move between modes
- Rulesets bundle rules + commands + skills together for easy installation
- Skills support reusable AI workflow directories (SKILL.md-based)

## Success Criteria

- Skills are correctly detected from `rules/<name>`, `rulesets/skills/<name>`, `rulesets/<ruleset>/skills/<name>`, and `rulesets/<name>` (symlink)
- Skills are deployed to `.cursor/skills/<mode>/` as whole directories
- Skills are listed in the `list` output with a trailing `/` suffix and correct status glyph
- Skills inside rulesets (via `skills/` subdirectory) are deployed when the ruleset is added
- All existing behaviors (rules, commands, rulesets) are unaffected

## Key Constraints

- POSIX-compliant shell script (no bash-isms)
- TDD: all changes require tests written first
- No test output filtering; read full test output
- NEVER test in the project directory (use tests or temp dirs)
