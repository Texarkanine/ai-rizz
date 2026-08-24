#!/bin/sh
#
# test_prompt_line_edits.test.sh - Interactive prompt line-edit helper tests
#
# Tests the non-tty path of read_prompt_line(): printable input, BS/DEL
# erase, erase on an empty buffer, empty line, and CR. Result is rpl_line.
# Stdin is a file so the function runs in the current shell (not a pipe
# subshell) and rpl_line is visible to the test.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_prompt_line_edits.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Source the actual implementation from ai-rizz
source_ai_rizz

test_read_prompt_line_printable_then_newline() {
	printf 'local\n' > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "Printable input should be returned as-is" "local" "${rpl_line}"
}

test_read_prompt_line_backspace_bs() {
	printf 'ai\010\010local\n' > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "BS should delete prior characters" "local" "${rpl_line}"
}

test_read_prompt_line_backspace_del() {
	printf 'ai\177\177local\n' > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "DEL should delete prior characters" "local" "${rpl_line}"
}

test_read_prompt_line_backspace_on_empty() {
	printf '\010\177x\n' > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "Erase on empty buffer should be a no-op" "x" "${rpl_line}"
}

test_read_prompt_line_empty_line() {
	printf '\n' > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "Newline-only input should yield an empty line" "" "${rpl_line}"
}

test_read_prompt_line_cr_terminator() {
	printf 'yes\r' > "${TEST_DIR}/prompt_input"
	read_prompt_line < "${TEST_DIR}/prompt_input"
	assertEquals "CR should terminate the line like newline" "yes" "${rpl_line}"
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
