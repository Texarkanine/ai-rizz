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

## Bash Completions

By default, `install` installs bash-completions.

You can control where bash-completions are installed, if the default location doesn't work for you:

```bash
make BASH_COMPLETION_DIR=~/local/share/bash-completion/completions install
```
