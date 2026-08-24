#!/bin/sh
#
# test_prompt_line_edits.test.sh - Interactive prompt line-edit helper tests
#
# Tests edit_prompt_line() and the non-tty path of read_prompt_line():
# printable input, BS/DEL erase, erase on an empty buffer, empty line, and CR.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_prompt_line_edits.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

# ============================================================================
# edit_prompt_line
# ============================================================================

test_edit_prompt_line_printable_then_newline() {
	epl_result=$(printf 'local\n' | edit_prompt_line)
	assertEquals "Printable input should be returned as-is" "local" "${epl_result}"
}

test_edit_prompt_line_backspace_bs() {
	epl_bs=$(printf '\010')
	epl_result=$(printf 'ai%s%slocal\n' "${epl_bs}" "${epl_bs}" | edit_prompt_line)
	assertEquals "BS should delete prior characters" "local" "${epl_result}"
}

test_edit_prompt_line_backspace_del() {
	epl_del=$(printf '\177')
	epl_result=$(printf 'ai%s%slocal\n' "${epl_del}" "${epl_del}" | edit_prompt_line)
	assertEquals "DEL should delete prior characters" "local" "${epl_result}"
}

test_edit_prompt_line_backspace_on_empty() {
	epl_bs=$(printf '\010')
	epl_del=$(printf '\177')
	epl_result=$(printf '%s%sx\n' "${epl_bs}" "${epl_del}" | edit_prompt_line)
	assertEquals "Erase on empty buffer should be a no-op" "x" "${epl_result}"
}

test_edit_prompt_line_empty_line() {
	epl_result=$(printf '\n' | edit_prompt_line)
	assertEquals "Newline-only input should yield an empty line" "" "${epl_result}"
}

test_edit_prompt_line_cr_terminator() {
	epl_result=$(printf 'yes\r' | edit_prompt_line)
	assertEquals "CR should terminate the line like newline" "yes" "${epl_result}"
}

# ============================================================================
# read_prompt_line (pipe / file stdin, no stty)
# ============================================================================

test_read_prompt_line_non_tty_backspace_bs() {
	epl_bs=$(printf '\010')
	printf 'ai%s%slocal\n' "${epl_bs}" "${epl_bs}" > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "read_prompt_line should set rpl_line after BS edits" "local" "${rpl_line}"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
