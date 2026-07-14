#!/bin/sh
#
# test_docs_theme_tokens.test.sh - ProperDocs paper/ember theme contract suite
#
# Asserts that ai-rizz docs chrome uses the Texarkanine paper/ember Material
# theme: custom primary/accent in properdocs.yaml, extra_css wired, and the
# expected light/dark CSS tokens in docs/stylesheets/extra.css.
#
# When ../slobac is present locally, also cmp's the stylesheet against the
# upstream source. CI relies on the in-repo token asserts only.
#
# Dependencies: shunit2, common test utilities
# Usage: sh test_docs_theme_tokens.test.sh

# Load common test utilities
# shellcheck disable=SC1091
. "$(dirname "$0")/../common.sh"

# Resolve repo paths before setUp cds into a temp dir.
TDTT_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
TDTT_REPO_ROOT="$(CDPATH= cd -- "${TDTT_TEST_DIR}/../.." && pwd)"
TDTT_PROPERDOCS_YAML="${TDTT_REPO_ROOT}/properdocs.yaml"
TDTT_EXTRA_CSS="${TDTT_REPO_ROOT}/docs/stylesheets/extra.css"
TDTT_SLOBAC_CSS="${TDTT_REPO_ROOT}/../slobac/skills/slobac-audit/references/docs/stylesheets/extra.css"

# Extract the body of [data-md-color-scheme="$1"] { ... } from CSS on stdin/file.
# Args: $1 scheme name, $2 css file path
# Prints the block body (without braces) to stdout.
tdtt_scheme_block() {
	tdtt_sb_scheme="$1"
	tdtt_sb_file="$2"
	tdtt_sb_needle="[data-md-color-scheme=\"${tdtt_sb_scheme}\"]"

	# Prefer awk for brace matching; fail clearly if selector missing.
	awk -v needle="${tdtt_sb_needle}" '
		index($0, needle) {
			found = 1
			# Find opening brace on this or following lines
			line = $0
			while (index(line, "{") == 0) {
				if ((getline line) <= 0) {
					exit 1
				}
			}
			depth = 0
			# Emit from after first { to matching }
			start = index(line, "{")
			for (i = start; i <= length(line); i++) {
				ch = substr(line, i, 1)
				if (ch == "{") {
					depth++
					if (depth == 1) continue
				} else if (ch == "}") {
					depth--
					if (depth == 0) exit 0
				}
				if (depth >= 1) printf "%s", ch
			}
			printf "\n"
			while ((getline line) > 0) {
				for (i = 1; i <= length(line); i++) {
					ch = substr(line, i, 1)
					if (ch == "{") {
						depth++
					} else if (ch == "}") {
						depth--
						if (depth == 0) exit 0
					}
					if (depth >= 1) printf "%s", ch
				}
				printf "\n"
			}
			exit 1
		}
		END {
			if (!found) exit 1
		}
	' "${tdtt_sb_file}"
}

# Assert CSS variable name:value appears in scheme block (whitespace-insensitive).
# Args: $1 block text, $2 var name, $3 expected value
tdtt_assert_var() {
	tdtt_av_block="$1"
	tdtt_av_name="$2"
	tdtt_av_value="$3"
	tdtt_av_compact="$(printf '%s' "${tdtt_av_block}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
	tdtt_av_expect="$(printf '%s:%s' "${tdtt_av_name}" "${tdtt_av_value}" | tr '[:upper:]' '[:lower:]')"

	case "${tdtt_av_compact}" in
	*"${tdtt_av_expect}"*) ;;
	*)
		fail "expected ${tdtt_av_name}: ${tdtt_av_value} in scheme block"
		;;
	esac
	return 0
}

test_palette_uses_custom_primary_and_accent() {
	assertTrue "properdocs.yaml must exist" "[ -f \"${TDTT_PROPERDOCS_YAML}\" ]"

	# No leftover indigo palette entries.
	if grep -E '^[[:space:]]*primary:[[:space:]]*indigo[[:space:]]*$' "${TDTT_PROPERDOCS_YAML}" >/dev/null 2>&1; then
		fail "properdocs.yaml still has primary: indigo"
	fi
	if grep -E '^[[:space:]]*accent:[[:space:]]*indigo[[:space:]]*$' "${TDTT_PROPERDOCS_YAML}" >/dev/null 2>&1; then
		fail "properdocs.yaml still has accent: indigo"
	fi

	tdtt_custom_primary="$(grep -cE '^[[:space:]]*primary:[[:space:]]*custom[[:space:]]*$' "${TDTT_PROPERDOCS_YAML}" || true)"
	tdtt_custom_accent="$(grep -cE '^[[:space:]]*accent:[[:space:]]*custom[[:space:]]*$' "${TDTT_PROPERDOCS_YAML}" || true)"
	assertTrue "expected >=2 primary: custom entries (got ${tdtt_custom_primary})" "[ \"${tdtt_custom_primary}\" -ge 2 ]"
	assertTrue "expected >=2 accent: custom entries (got ${tdtt_custom_accent})" "[ \"${tdtt_custom_accent}\" -ge 2 ]"
	return 0
}

test_palette_retains_light_and_dark_toggles() {
	assertTrue "properdocs.yaml must exist" "[ -f \"${TDTT_PROPERDOCS_YAML}\" ]"
	assertTrue "missing scheme: default" "grep -qE '^[[:space:]]*scheme:[[:space:]]*default[[:space:]]*$' \"${TDTT_PROPERDOCS_YAML}\""
	assertTrue "missing scheme: slate" "grep -qE '^[[:space:]]*scheme:[[:space:]]*slate[[:space:]]*$' \"${TDTT_PROPERDOCS_YAML}\""
	assertTrue "missing toggle:" "grep -q 'toggle:' \"${TDTT_PROPERDOCS_YAML}\""
	assertTrue "missing light toggle icon" "grep -q 'material/brightness-7' \"${TDTT_PROPERDOCS_YAML}\""
	assertTrue "missing dark toggle icon" "grep -q 'material/brightness-4' \"${TDTT_PROPERDOCS_YAML}\""
	return 0
}

test_extra_css_registers_stylesheets_extra() {
	assertTrue "properdocs.yaml must exist" "[ -f \"${TDTT_PROPERDOCS_YAML}\" ]"
	assertTrue "missing extra_css:" "grep -q '^extra_css:' \"${TDTT_PROPERDOCS_YAML}\""
	assertTrue "missing stylesheets/extra.css under extra_css" "grep -q 'stylesheets/extra.css' \"${TDTT_PROPERDOCS_YAML}\""
	return 0
}

test_extra_css_file_exists_and_nonempty() {
	assertTrue "missing theme stylesheet: ${TDTT_EXTRA_CSS}" "[ -f \"${TDTT_EXTRA_CSS}\" ]"
	assertTrue "theme stylesheet must not be empty" "[ -s \"${TDTT_EXTRA_CSS}\" ]"
	return 0
}

test_light_scheme_paper_tokens() {
	assertTrue "missing theme stylesheet: ${TDTT_EXTRA_CSS}" "[ -f \"${TDTT_EXTRA_CSS}\" ]"
	tdtt_block="$(tdtt_scheme_block default "${TDTT_EXTRA_CSS}")" || fail "missing default scheme block"
	tdtt_assert_var "${tdtt_block}" "--md-default-bg-color" "#f6f0e4"
	tdtt_assert_var "${tdtt_block}" "--md-default-fg-color" "#1f1a14"
	tdtt_assert_var "${tdtt_block}" "--md-primary-fg-color" "#b45309"
	tdtt_assert_var "${tdtt_block}" "--md-accent-fg-color" "#c2410c"
	tdtt_assert_var "${tdtt_block}" "--md-code-bg-color" "#ebe4d4"
	tdtt_assert_var "${tdtt_block}" "--md-footer-bg-color" "#2a241c"
	return 0
}

test_dark_scheme_ember_tokens() {
	assertTrue "missing theme stylesheet: ${TDTT_EXTRA_CSS}" "[ -f \"${TDTT_EXTRA_CSS}\" ]"
	tdtt_block="$(tdtt_scheme_block slate "${TDTT_EXTRA_CSS}")" || fail "missing slate scheme block"
	tdtt_assert_var "${tdtt_block}" "--md-default-bg-color" "#1c1914"
	tdtt_assert_var "${tdtt_block}" "--md-default-fg-color" "#f0e6d4"
	tdtt_assert_var "${tdtt_block}" "--md-primary-fg-color" "#de8131"
	tdtt_assert_var "${tdtt_block}" "--md-accent-fg-color" "#fb923c"
	tdtt_assert_var "${tdtt_block}" "--md-typeset-a-color" "#fb923c"
	tdtt_assert_var "${tdtt_block}" "--md-code-bg-color" "#2a251c"
	tdtt_assert_var "${tdtt_block}" "--md-footer-bg-color" "#12100c"
	return 0
}

test_extra_css_matches_slobac_when_present() {
	# Local-only parity check; skip when sibling checkout is absent (CI).
	if [ ! -f "${TDTT_SLOBAC_CSS}" ]; then
		startSkipping
		endSkipping
		return 0
	fi
	assertTrue "missing theme stylesheet: ${TDTT_EXTRA_CSS}" "[ -f \"${TDTT_EXTRA_CSS}\" ]"
	assertTrue "extra.css must match ../slobac source byte-for-byte" \
		"cmp -s \"${TDTT_EXTRA_CSS}\" \"${TDTT_SLOBAC_CSS}\""
	return 0
}

# Load and run shunit2
# shellcheck disable=SC1090
. "$(dirname "$0")/../../shunit2"
