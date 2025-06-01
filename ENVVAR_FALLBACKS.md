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

### Setting Default Repository

Set a default repository URL for init:

```bash
export AI_RIZZ_SOURCE_REPO="https://github.com/example/rules.git"
ai-rizz init --local  # Uses the repo URL from environment
```

### Default Mode Selection

Set a default mode for operations:

```bash
export AI_RIZZ_MODE="local"
ai-rizz init https://github.com/example/rules.git  # Uses local mode
ai-rizz add rule example-rule  # Adds to local mode
```

### Custom Paths

Set custom paths for rules and rulesets:

```bash
export AI_RIZZ_RULE_PATH="my-rules"
export AI_RIZZ_RULESET_PATH="my-rulesets"
ai-rizz init https://github.com/example/rules.git --local
```

### Custom Manifest Name

Set a custom manifest filename:

```bash
export AI_RIZZ_MANIFEST="cursor-rules.conf"
ai-rizz init https://github.com/example/rules.git --local
# Creates cursor-rules.conf and cursor-rules.local.conf
```

### Overriding Environment Variables

CLI arguments always take precedence:

```bash
export AI_RIZZ_MODE="local"
ai-rizz init https://github.com/example/rules.git --commit  # Uses commit mode
```

## Completed Tasks

- [x] Review the ai-rizz codebase to understand command structure
- [x] Identify locations where environment variables should be integrated
- [x] Determine test strategy for environment variable fallbacks
- [x] Create integration test file for environment variable fallbacks
- [x] Test AI_RIZZ_MANIFEST for global --manifest option
- [x] Test AI_RIZZ_SOURCE_REPO for init <source_repo> parameter
- [x] Test AI_RIZZ_TARGET_DIR for init -d <target_dir> parameter
- [x] Test AI_RIZZ_RULE_PATH for init --rule-path <path> parameter
- [x] Test AI_RIZZ_RULESET_PATH for init --ruleset-path <path> parameter
- [x] Test AI_RIZZ_MODE for mode selection in various commands
- [x] Modify ai-rizz to handle environment variable fallbacks
- [x] Update main argument parsing for AI_RIZZ_MANIFEST
- [x] Update cmd_init to check for environment variables
- [x] Update mode selection logic to check AI_RIZZ_MODE
- [x] Ensure all commands handle environment variables consistently

## Implementation Plan

Environment variable fallbacks were implemented with the following principles:
1. CLI arguments take precedence over environment variables
2. Environment variables take precedence over prompts/defaults
3. Empty environment variables are ignored

### Relevant Files

- `ai-rizz` - Main script modified for environment variable support
- `tests/integration/test_envvar_fallbacks.test.sh` - Integration tests for environment variable fallbacks 