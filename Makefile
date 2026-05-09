# Simple Makefile for ai-rizz

# Installation directories
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
BASH_COMPLETION_DIR ?= $(PREFIX)/share/bash-completion/completions

.PHONY: install uninstall help test docs docs-build

help:
	@echo "Use 'make install' to install ai-rizz"
	@echo "Use 'make uninstall' to uninstall ai-rizz"
	@echo "Use 'make test' to run tests"
	@echo "Use 'make docs' to preview the docs site locally"
	@echo "Use 'make docs-build' to run the same strict build CI runs"
	@echo ""
	@echo "You can override installation directory with:"
	@echo "  make PREFIX=/usr/local install    # installs system-wide (requires sudo)" 

install:
	@echo "Installing ai-rizz script..."
	@mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/ai-rizz $(BINDIR)/ai-rizz
	@./install-bash-completion.bash install
	@echo "Installation complete. Run 'source ~/.bashrc' or restart your shell to enable completion."

uninstall:
	rm -f $(BINDIR)/ai-rizz
	@./install-bash-completion.bash uninstall
	@echo "ai-rizz has been uninstalled from $(BINDIR)"
	@echo "Bash completion block has been removed from ~/.bash_completion"

test: test-unit test-integration

test-unit:
	@sh tests/run_tests.sh --unit

test-integration:
	@sh tests/run_tests.sh --integration

# Local docs preview. Requires `uv` (https://github.com/astral-sh/uv).
docs:
	uv run properdocs serve

# Strict docs build (matches what CI runs). Requires `uv`.
docs-build:
	uv sync --group docs --frozen
	uv run properdocs build --strict
