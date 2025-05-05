# ai-rizz command-line tool design document

## design

### source_repo

Somewhere there will be a source repository with this directory structure:

```
├── rules
│   ├── bar.mdc
│   ├── baz.mdc
│   ├── fee.mdc
│   ├── fie.mdc
│   ├── foo.mdc
│   └── fum.mdc
└── rulesets
    ├── code
    │   ├── bar.mdc -> ../../rules/bar.mdc
    │   └── foo.mdc -> ../../rules/foo.mdc
    └── giant
        ├── fee.mdc -> ../../rules/fee.mdc
        └── fie.mdc -> ../../rules/fie.mdc
```

* rules are single `*.mdc` files, in `rules/`
* rulesets are directories of symlinks to rules files, each ruleset is a directory in `rulesets/`

### manifest

The manifest tracks the source repository and the rules and rulesets pulled from it.
The manifest file `ai-rizz.inf` lives in the repository root.

The first line of the manifest is the source repo's git clone url, and the directory (target directory) in this repository that the script operates in. They are separated by a tab character.
Subsequent lines are coordinates in the repository, e.g.

`ai-rizz.inf`

```
https://github.com/texarkanine/.cursor-rules.git	.cursor/rules/
rules/fie.mdc
rulesets/code
rulesets/giant
```

## interface

### `ai-rizz init <source_repo> [-d <target_directory>] [--local|-l|--commit|-c]`

* prompts user to specify source github repository if not specified by CLI flag
* prompts user to choose "local" mode or "commit" mode, if not specified by CLI flag.
* in `commit` mode, rules will be copied to and committed to the repository
* in `local` mode
    * `.git/info/exclude` will be amended to include `target_directory/`
    * `ai-rizz.inf` will be added to `.git/info/exclude`
In both modes, the following setup must take place:
    * manifest `ai-rizz.inf` will be created in the repository root
    * `source_repo` & `target_directory` must be written to the manifest.

### `ai-rizz deinit [-y]`

* depending on the mode (as determined by whether there's an entry in `.git/info/exclude`), undo the changes init did:
* in `commit` mode
    (nothing special)
* in `local` mode
    1. remove the entry from `.git/info/exclude`
* in both modes:
    1. delete the `target_directory` recursively and verbosely
* if `-y` was not specified, script should print what WOULD be deleted, and prompt user for confirmation.
* if `-y` WAS specified, script should just do it.

### `ai-rizz list`

* updates the local copy of the source repository
* lists available rulesets and rules from the `source_repo`
* indicates which remote rules and rulesets are present in the local manifest.
* if any manifest entries don't exist in the remote repo:
    * prints a warning
    * removes those lines from the manifest

### `ai-rizz add rule <rules> [<rule>[ <rule> ...]]

Add one or more rules from `source_repo` to the manifest, then copy those rules into `target_directory/shared`

### `ai-rizz add ruleset <ruleset> [<ruleset>[ <ruleset> ...]]

Add one or more ruleset from `source_repo` to the manifest, then copy the rules in that ruleset into `target_directory/shared`

### `ai-rizz remove rule <rules> [<rule>[ <rule> ...]]

Remove one or more rules from `target_directory/shared`, and also from the manifest.

### `ai-rizz remove ruleset <ruleset> [<ruleset>[ <ruleset> ...]]

Remove all rules associated with one or more rulesets from `target_directory/shared`, then remove the rulesets from the manifest

### `ai-rizz sync`

Update the local copy of the source repository, then copy all rules specified by the manifest into `target_directory/shared`.

* If there is no `ai-rizz.inf` manifest in the repository root, this is an error.
* This may be happening on a new machine, so it may be necessary to clone the source_repo into the right directory in the user's home first; see "implementation notes"
* if any manifest entries don't exist in the remote repo:
    * prints a warning
    * removes those lines from the manifest

## implementation notes

On `init` and `sync`, if needed:
* `$HOME/.config/ai-rizz/` will be created
* the source_repo will be cloned to `$HOME/.config/ai-rizz/`

On `list` and `sync`:
* the source_repo will be updated (`git pull`)

The "mode" of operation can be determined by whether the local repository has an entry for ai-rizz in `.git/info/exclude`; if it does, it's `local` mode. Otherwise, it's `commit` mode.

## design requirements

1. the shell script MUST be POSIX-compliant
2. It's preferable to rely on common *NIX command-line utilities, beyond POSIX shell builtins
3. Operations should be idempotent where possible
4. Invalid manifest entries should be removed with a warning
5. Git operations should be trusted to work; user can retry if they fail
6. Permissions for file operations in user's home directory and repository should be assumed
