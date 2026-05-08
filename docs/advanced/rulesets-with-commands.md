# Rulesets with Commands

Rulesets can include [Cursor Command](https://cursor.com/docs/agent/chat/commands) files (`.md` files). These commands are automatically copied to the mode-specific `.cursor/commands/` directory when the ruleset is added.

**Commands work in all modes**: Local, commit, and global modes all support commands.

## How Commands are Detected

All `.md` files anywhere in a ruleset are treated as commands, except:

- **Uppercase `.md` files** like `README.md`, `CHANGELOG.md`, `LICENSE.md` (these are documentation)

Commands are copied **flat** (no directory structure preserved) to make them accessible as `/command-name` in Cursor.

## Source Repository Structure

Both structures are supported:

```text
rulesets/
└── memory-bank/
    ├── van.md           # command (at root)
    ├── plan.md          # command (at root)
    ├── commands/        # optional subdirectory
    │   └── build.md     # command (in subdir, still copied flat)
    ├── rule1.mdc        # rule
    └── README.md        # ignored (uppercase)
```

## Example Workflow

```bash
# Commands work in any mode
ai-rizz init https://github.com/example/rules.git --local
ai-rizz add ruleset memory-bank --local
# Commands from rulesets/memory-bank/*.md
# are now in .cursor/commands/local/

# Or in commit mode
ai-rizz init https://github.com/example/rules.git --commit
ai-rizz add ruleset memory-bank --commit
# Commands are now in .cursor/commands/shared/

# Or in global mode
ai-rizz init https://github.com/example/rules.git --global
ai-rizz add ruleset memory-bank --global
# Commands are now in ~/.cursor/commands/ai-rizz/
```

## Installed Structure

When a ruleset is added:

- Rules (`.mdc` files) → `.cursor/rules/<mode>/`
- Commands (`.md` files) → `.cursor/commands/<mode>/` (flat)
