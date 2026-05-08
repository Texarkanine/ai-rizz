# Rule and Ruleset Constraints

ai-rizz enforces certain constraints to maintain data integrity and prevent conflicts between local and committed modes. Understanding these constraints helps you work effectively with complex rule management scenarios.

## Example Repository Structure

For the examples below, assume your source repository has this structure:

```
rules/
├── personal-productivity.mdc
├── code-review.mdc
└── documentation.mdc

rulesets/
├── shell/
│   ├── bash-style.mdc
│   ├── posix-style.mdc
│   └── shell-tdd.mdc
└── python/
    ├── pep8-style.mdc
    ├── type-hints.mdc
    └── testing.mdc
```

## Upgrade/Downgrade Rules

**Upgrade (Individual → Ruleset)**: ✅ Always allowed

*Scenario*: You have `bash-style.mdc` installed individually, then add the `shell` ruleset:

```bash
# Starting state: individual rule installed
ai-rizz add rule bash-style.mdc --local
ai-rizz list
# Shows: ◐ bash-style.mdc

# Add the ruleset containing that rule
ai-rizz add ruleset shell --local
ai-rizz list
# Shows: ◐ shell (contains bash-style.mdc, posix-style.mdc, shell-tdd.mdc)
# The individual bash-style.mdc entry is automatically removed
```

**Downgrade (Ruleset → Individual)**: ⚠️ Conditionally blocked

*Scenario*: You have the `shell` ruleset committed, then try to add just `bash-style.mdc` locally:

```bash
# Starting state: ruleset committed
ai-rizz add ruleset shell --commit
ai-rizz list
# Shows: ● shell (contains bash-style.mdc, posix-style.mdc, shell-tdd.mdc)

# Try to add individual rule locally - BLOCKED
ai-rizz add rule bash-style.mdc --local
# Error: Cannot add individual rule 'bash-style.mdc' to local mode:
# it's part of committed ruleset 'rulesets/shell'.
# Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
```

*Why blocked*: Prevents fragmenting committed rulesets, which could lead to incomplete team configurations.

## Valid Operations

**Same-mode operations**: ✅ Always allowed

```bash
# Add individual rules from our example repository
ai-rizz add rule personal-productivity.mdc --local    # Add to local mode
ai-rizz add rule code-review.mdc --commit             # Add to commit mode

# Add rulesets from our example repository
ai-rizz add ruleset python --local                    # Add ruleset to local mode
ai-rizz add ruleset shell --commit                    # Add ruleset to commit mode
```

**Cross-mode migrations**: ✅ Always allowed

```bash
# Moving individual rules between modes
ai-rizz add rule documentation.mdc --local           # Rule in local mode
ai-rizz add rule documentation.mdc --commit          # Now in commit mode

# Moving rulesets between modes
ai-rizz add ruleset python --commit                  # Ruleset in commit mode
ai-rizz add ruleset python --local                   # Now in local mode
```

**Ruleset upgrades**: ✅ Always allowed

```bash
# Individual rule gets absorbed into ruleset
ai-rizz add rule bash-style.mdc --local              # Individual rule
ai-rizz add ruleset shell --local                    # Ruleset contains bash-style.mdc
# Result: Only the ruleset remains, individual bash-style.mdc entry removed
```

## Blocked Operations

**Downgrade from committed ruleset**: ❌ Blocked

```bash
# Set up: shell ruleset committed (contains bash-style.mdc, posix-style.mdc, shell-tdd.mdc)
ai-rizz add ruleset shell --commit
ai-rizz list
# Shows: ● shell

# Try to extract individual rule to local mode - BLOCKED
ai-rizz add rule bash-style.mdc --local       # ❌ BLOCKED
# Error: Cannot add individual rule 'bash-style.mdc' to local mode:
# it's part of committed ruleset 'rulesets/shell'.
# Use 'ai-rizz add-ruleset shell --local' to move the entire ruleset.
```

**Why this is blocked**: Prevents fragmenting committed rulesets, which could lead to:

- Incomplete rulesets in commit mode (team missing some rules)
- Confusion about which rules are shared vs. personal
- Merge conflicts when team members have different rule subsets

## Workarounds for Complex Scenarios

**Scenario**: You want only `bash-style.mdc` from the committed `shell` ruleset in local mode

**Solution 1**: Move entire ruleset to local mode, then remove unwanted rules

```bash
ai-rizz add ruleset shell --local           # Move whole ruleset to local
ai-rizz remove rule posix-style.mdc         # Remove unwanted rules
ai-rizz remove rule shell-tdd.mdc           # Remove unwanted rules
# Result: Only bash-style.mdc remains in local mode
```

**Solution 2**: Remove ruleset and add individual rules separately

```bash
ai-rizz remove ruleset shell                # Remove committed ruleset
ai-rizz add rule bash-style.mdc --local     # Add desired rule locally
ai-rizz add rule posix-style.mdc --commit   # Re-add others to commit mode
ai-rizz add rule shell-tdd.mdc --commit     # Re-add others to commit mode
```

**Scenario**: Team wants to adopt your local `python` ruleset

**Solution**: Promote local ruleset to commit mode

```bash
ai-rizz add ruleset python --commit         # Moves to commit mode
git add ai-rizz.skbd .cursor/rules/shared/   # Stage for commit
git commit -m "Add team Python ruleset"    # Share with team
```

## Ruleset-Local Rules

Rulesets may contain `.mdc` *files* in addition to symlinks to rules in the `rules/` directory.

Such "ruleset-local rules" will:

1. be installed alongside symlinked rules normally
2. show up in `ai-rizz list` output as part of the ruleset
3. **not** show up in `ai-rizz` "rules" list
4. **not** be able to be installed or removed individually
