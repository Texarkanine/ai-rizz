#!/bin/sh
#
# test_makefile_zsh_install.test.sh - Makefile zsh completion install hook tests
#
# Verifies make install/uninstall wire zsh completion into ~/.zshrc using isolated HOME/PREFIX.

# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

_PROJECT_ROOT=""
if [ -n "${AI_RIZZ_PATH}" ]; then
	_PROJECT_ROOT="$(cd "$(dirname "${AI_RIZZ_PATH}")" && pwd)"
elif [ -d "./tests" ]; then
	_PROJECT_ROOT="$(pwd)"
elif [ -d "$(dirname "$0")/../.." ]; then
	_PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
else
	echo "ERROR: Cannot determine project root" >&2
	exit 1
fi

_FENCE_START="# >>> ai-rizz zsh completion >>>"

_make() {
	(
		cd "${_PROJECT_ROOT}" || exit 1
		HOME="${HOME}" PREFIX="${PREFIX}" BINDIR="${BINDIR}" make "$@"
	)
}

setUp() {
	_ORIGINAL_HOME="${HOME}"
	TEST_DIR="$(mktemp -d)"
	HOME="${TEST_DIR}/home"
	PREFIX="${TEST_DIR}/prefix"
	BINDIR="${PREFIX}/bin"
	export HOME PREFIX BINDIR
	mkdir -p "${HOME}" "${BINDIR}"
	touch "${HOME}/.zshrc"
}

tearDown() {
	HOME="${_ORIGINAL_HOME}"
	export HOME
	rm -rf "${TEST_DIR}"
}

test_make_install_adds_zsh_completion_fence() {
	_make install >/dev/null 2>&1

	assertTrue "make install should succeed" $?
	grep -q "${_FENCE_START}" "${HOME}/.zshrc" || \
		fail "make install should add zsh completion fence to ~/.zshrc"
	return 0
}

test_make_uninstall_removes_zsh_completion_fence() {
	_make install >/dev/null 2>&1
	_make uninstall >/dev/null 2>&1

	grep -q "${_FENCE_START}" "${HOME}/.zshrc" && \
		fail "make uninstall should remove zsh completion fence from ~/.zshrc"
	return 0
}

# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
