# Simple Makefile for ai-rizz

# Installation directories
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
BASH_COMPLETION_DIR ?= $(PREFIX)/share/bash-completion/completions

.PHONY: install uninstall help test

help:
	@echo "Use 'make install' to install ai-rizz"
	@echo "Use 'make uninstall' to uninstall ai-rizz"
	@echo "Use 'make test' to run tests"
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
