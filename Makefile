# Simple Makefile for ai-rizz

# Installation directories
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall help

help:
	@echo "Use 'make install' to install ai-rizz"
	@echo "Use 'make uninstall' to uninstall ai-rizz"
	@echo ""
	@echo "You can override installation directory with:"
	@echo "  make PREFIX=~/local install    # installs to ~/local/bin" 

install:
	mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/ai-rizz $(BINDIR)/ai-rizz
	@echo "ai-rizz has been installed to $(BINDIR)/ai-rizz"

uninstall:
	rm -f $(BINDIR)/ai-rizz
	@echo "ai-rizz has been uninstalled from $(BINDIR)"
