#!/bin/sh
#
# test_install_zsh_completion.test.sh - Zsh completion installer tests
#
# Tests install-zsh-completion.bash install/uninstall/idempotency against a temp HOME.

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

_INSTALLER="${_PROJECT_ROOT}/install-zsh-completion.bash"
_FENCE_START="# >>> ai-rizz zsh completion >>>"
_FENCE_END="# <<< ai-rizz zsh completion <<<"

_run_installer() {
	(
		cd "${_PROJECT_ROOT}" || exit 1
		sh "${_INSTALLER}" "$1"
	)
}

test_install_adds_fenced_block_to_zshrc() {
	touch "${HOME}/.zshrc"
	_run_installer install

	assertTrue "installer should succeed" $?
	grep -qx "${_FENCE_START}" "${HOME}/.zshrc" || fail "missing fence start"
	grep -qx "${_FENCE_END}" "${HOME}/.zshrc" || fail "missing fence end"
	grep -q "${_PROJECT_ROOT}/completion.zsh" "${HOME}/.zshrc" || \
		fail "zshrc should source completion.zsh with absolute path"
	grep -q 'compinit -C' "${HOME}/.zshrc" || \
		fail "zshrc fence should run compinit before sourcing completion.zsh"
	return 0
}

test_install_is_idempotent() {
	touch "${HOME}/.zshrc"
	_run_installer install
	_run_installer install

	count="$(grep -c "${_FENCE_START}" "${HOME}/.zshrc" || true)"
	assertEquals "fence start should appear once" "1" "${count}"
	return 0
}

test_uninstall_removes_fenced_block() {
	touch "${HOME}/.zshrc"
	_run_installer install
	_run_installer uninstall

	grep -q "${_FENCE_START}" "${HOME}/.zshrc" && fail "fence start should be removed"
	grep -q "${_FENCE_END}" "${HOME}/.zshrc" && fail "fence end should be removed"
	return 0
}

# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
