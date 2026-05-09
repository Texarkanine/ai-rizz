# Environment Variable Fallbacks

ai-rizz supports environment variables as fallbacks for CLI arguments. This allows you to set default values for commonly used options without having to specify them on the command line each time.

## Available Environment Variables

| Environment Variable | CLI Equivalent | Description |
|---------------------|----------------|-------------|
| `AI_RIZZ_MANIFEST` | `--manifest`/`--skibidi` | Custom manifest filename |
| `AI_RIZZ_SOURCE_REPO` | `<source_repo>` | Repository URL for rules source |
| `AI_RIZZ_TARGET_DIR` | `-d <target_dir>` | Target directory for rules |
| `AI_RIZZ_RULE_PATH` | `--rule-path <path>` | Path to rules in source repo |
| `AI_RIZZ_RULESET_PATH` | `--ruleset-path <path>` | Path to rulesets in source repo |
| `AI_RIZZ_MODE` | `--local`/`--commit` | Default mode for operations |

## Precedence Rules

The precedence order for option values is:

1. CLI arguments (highest priority)
2. Environment variables
3. Default values or interactive prompts (lowest priority)

If an environment variable is empty, it is ignored and ai-rizz falls back to defaults or prompts.

## Usage Examples

**Setting Default Repository**

Set a default repository URL for init:

```bash
export AI_RIZZ_SOURCE_REPO="https://github.com/example/rules.git"
ai-rizz init --local  # Uses the repo URL from environment
```

**Custom Manifest Name**

Set a custom manifest filename:

```bash
export AI_RIZZ_MANIFEST="cursor-rules.conf"
ai-rizz init https://github.com/example/rules.git --local
# Creates cursor-rules.conf and cursor-rules.local.conf
```
