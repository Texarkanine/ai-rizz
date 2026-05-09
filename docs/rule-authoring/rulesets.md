# Rulesets

A Ruleset is a collection of one or more Rules. Create [symlinks](https://man7.org/linux/man-pages/man1/ln.1.html) to rules in the `rules` directory.

This allows you to easily use the same rule in multiple rulesets, and allows `ai-rizz` to deduplicate any such rules when it installs them. This deduplication is important because you do not want multiple copies of the same rule wasting space in your Agent's context windows.

If you're using the recommended ruleset repository shape, just use

```bash
cd rulesets/<your-ruleset>
ln -s ../../rules/<your-rule>
ln -s ../../rules/<other-rule>
```

to populate a ruleset.

Some basic rulesets might look like this:

```
rulesets
├── script-it
│   ├── how-to-script-it-instead.mdc -> ../../rules/how-to-script-it-instead.mdc
│   └── script-it-instead.mdc -> ../../rules/script-it-instead.mdc
└── shell
    ├── README.md
    ├── bash-style.mdc -> ../../rules/bash-style.mdc
    ├── shell-posix-style.mdc -> ../../rules/shell-posix-style.mdc
    └── shell-tdd.mdc -> ../../rules/shell-tdd.mdc
```

## Rules

Cursor Rules with the `.mdc` extension can be placed anywhere in a Ruleset's directory.

* If they are in the root of the ruleset directory, they will show up in `ai-rizz list`.
* If they are in a subdirectory, they will
	1. be installed to that subdirectory within the target installation directory
	2. not show up in `ai-rizz list` - only the directory that contains them will.

=== "Rule"

	```
	rules
	├── local-rule.mdc
	└── extra.mdc
	```

=== "Ruleset"

	```
	rulesets
	└── example
		├── local-rule.mdc -> ../../rules/local-rule.mdc
		└── more-rules
	       └── extra.mdc -> ../../../rules/extra.mdc
	```

=== "ai-rizz list"

	```
	Available rulesets:
	○ example
	  ├── local-rule.mdc
	  └── more-rules
	```

=== "Installed Structure"

	```
	.cursor/rules/<mode>/
	├── local-rule.mdc
	└── more-rules
	   └── extra.mdc
	```

This allows you to have many "helper" rules that the end-user doesn't see. You'd use this if those rules didn't help the user understand what the ruleset was for.

## Skills

Skills **must** be placed in the `skills/` subdirectory of the ruleset. Skills may not nest.

Direct child symlinks under `rulesets/<ruleset>/skills/` are supported. If a symlink resolves to an in-repository skill directory containing `SKILL.md`, `ai-rizz list` shows it in the ruleset tree and install/sync deploys it into `.cursor/skills/<mode>/`.

For safety, symlinks resolving outside the source repository are skipped.

=== "Skill"

	```
	rules
	└── magic-skill
	    └── SKILL.md
	```

=== "Ruleset"

	```
	rulesets
	└── example
	    └── skills
	        └── magic-skill -> ../../../rules/magic-skill
	```

=== "ai-rizz list"

	```
	Available rulesets:
	○ example
	  └── skills
	      └── magic-skill
	```

=== "Installed Structure"

	```
	.cursor/skills/<mode>/
	└── magic-skill
	    └── SKILL.md
	```

Any and all additional files in a Skill's directory (`references/`, `scripts/`, etc.) will be installed by `ai-rizz`, even though they don't show up in `ai-rizz list`.

Skills may not nest. Skills will install "flat" to the target installation directory - usually `.cursor/skills/<mode>/`.

## Commands

!!! warning "Deprecated"
	Cursor has deprecated Commands in favor of Skills with the `disable-model-invocation: true` frontmatter field.
	`ai-rizz` still supports Commands, but you should not create new ones.

Commands **must** be placed in the `commands/` subdirectory of the ruleset. Only `*.md` files under that directory are installed as slash commands. Other `.md` files elsewhere in the ruleset are not treated as commands.

=== "Command"

	```
	rules
	└── magic-command.md
	```

=== "Ruleset"

	```
	rulesets
	└── example
		└── commands
			└── magic-command.md -> ../../../rules/magic-command.md
	```

=== "ai-rizz list"

	```
	Available rulesets:
	○ example
	  └── commands
	      └── magic-command.md
	```

=== "Installed Structure"

	```
	.cursor/commands/<mode>/
	└── magic-command.md
	```

## Ruleset-Local Rules

Anywhere you could **symlink** a rule in a ruleset, you can also just place the file(s) for a Rule, Skill, or Command.

These will install normally, but - because they aren't in `rules/`,

1. Cannot be installed individually with `ai-rizz add rule`
2. Cannot be included in other rulesets

You would use this if you had a resource that really, truly, only ever made sense within the context of the one ruleset.

For example, this ruleset will install 2 rules, 1 command, and 1 skill, even though there isn't a single symlink:

```
rulesets/example
├── commands
│   └── magic-command.md
├── local-rule.mdc
├── more-rules
│   └── extra.mdc
└── skills
    └── magic-skill
        └── SKILL.md
```

## Documentation Files

Files with names in ALL-UPPERCASE (such as `README.md`) are ignored by `ai-rizz`; this allows you to put a `README.md`, `LICENSE`, `CHANGELOG.md`, or other such documentation files in your ruleset without them being pulled in when people add the ruleset.

For example, this ruleset will install 3 rules but *not* the `README.md`:

```
rulesets
└── shell
    ├── README.md
    ├── bash-style.mdc -> ../../rules/bash-style.mdc
    ├── shell-posix-style.mdc -> ../../rules/shell-posix-style.mdc
    └── shell-tdd.mdc -> ../../rules/shell-tdd.mdc
```

## Symlink Security

When `ai-rizz` follows symlinks during deployment, it validates that symlink targets resolve inside the source repository.

Symlinks that resolve outside the repo are skipped.
