# Installation Options

Install to a custom location:

```bash
make BINDIR=~/local install
```

Uninstall:

```bash
make uninstall
```

!!! warning "Custom Directories"
	If you provided custom directories for installation, you must provide the same custom directories for uninstallation, e.g.
	```bash
	make BINDIR=~/local uninstall
	```

## Shell Completions

`install` sets up tab completion for each shell that is on `PATH` (`bash` and/or `zsh`):

- **Bash:** adds a fenced block to `~/.bash_completion` that sources `completion.bash`.
- **Zsh:** adds a fenced block to `~/.zshrc` that sources `completion.zsh`. The fence runs `compinit` before sourcing.

`uninstall` removes both fences if they are present.

You can control where bash-completions are installed, if the default location doesn't work for you:

```bash
make BASH_COMPLETION_DIR=~/local/share/bash-completion/completions install
```
