#!/bin/sh
# Test runner script for ai-rizz

# Exit on error
set -e

# Store the original directory
ORIG_DIR="$(pwd)"
TIMEOUT_SECONDS=15

# Get the project root directory (parent of the tests directory)
get_project_root() {
	# Detect where this script is running from and find project root
	script_dir="$(dirname "$0")"
	
	# If in tests directory, go up one level
	if [ "$(basename "$script_dir")" = "tests" ]; then
		cd "$script_dir/.." || exit 1
	elif [ -d "./tests" ]; then
		# Already in project root
		:
	else
		echo "Error: Cannot determine project root directory" >&2
		exit 1
	fi
	
	# Return the absolute path to project root
	pwd
}

# Find test files based on type selection
find_tests() {
	test_files=""
	
	if [ "$RUN_UNIT_TESTS" = "true" ]; then
		unit_tests=$(find "$PROJECT_ROOT/tests/unit" -name "*.test.sh" 2>/dev/null | sort)
		test_files="$test_files $unit_tests"
	fi
	
	if [ "$RUN_INTEGRATION_TESTS" = "true" ]; then
		integration_tests=$(find "$PROJECT_ROOT/tests/integration" -name "*.test.sh" 2>/dev/null | sort)
		test_files="$test_files $integration_tests"
	fi
	
	# Remove leading/trailing spaces and output
	echo "$test_files" | tr ' ' '\n' | grep -v '^$' | sort
}

# Enhanced test execution with verbosity control
run_test() {
	test_file="$1"
	test_name="${test_file#$PROJECT_ROOT/tests/}"
	
	# Run from project root for consistency
	cd "$PROJECT_ROOT" || exit 1
	
	# Set environment for test execution
	AI_RIZZ_PATH="$PROJECT_ROOT/ai-rizz"
	export AI_RIZZ_PATH
	
	if [ "$VERBOSE_TESTS" = "true" ]; then
		# Verbose mode: show all output
		echo "==== Running test: $test_name ===="
		if timeout $TIMEOUT_SECONDS sh "$test_file"; then
			echo "==== PASS: $test_name ===="
			return 0
		else
			exit_code=$?
			if [ $exit_code -eq 124 ]; then
				echo "==== TIMEOUT: $test_name (hung waiting for input) ===="
			else
				echo "==== FAIL: $test_name ===="
			fi
			return 1
		fi
	else
		# Quiet mode: capture output, show only on failure
		printf "%-50s " "$test_name"
		
		if output=$(timeout $TIMEOUT_SECONDS sh "$test_file" 2>&1); then
			echo "✓ PASS"
			return 0
		else
			exit_code=$?
			if [ $exit_code -eq 124 ]; then
				echo "✗ TIMEOUT"
				echo "  Test hung waiting for input. Re-running with verbose output:"
			else
				echo "✗ FAIL"
				echo "  Re-running with verbose output for troubleshooting:"
			fi
			echo "  ----------------------------------------"
			VERBOSE_TESTS=true timeout $TIMEOUT_SECONDS sh "$test_file" || true
			echo "  ----------------------------------------"
			return 1
		fi
	fi
}

# Add usage information
show_usage() {
	echo "Usage: $0 [options]"
	echo ""
	echo "Options:"
	echo "  -v, --verbose      Run tests with verbose output"
	echo "  -u, --unit         Run only unit tests"
	echo "  -i, --integration  Run only integration tests"
	echo "  -h, --help         Show this help message"
	echo ""
	echo "Environment Variables:"
	echo "  VERBOSE_TESTS=true    Force verbose output for all tests"
	echo ""
	echo "Examples:"
	echo "  $0                    # Run all tests quietly (default)"
	echo "  $0 --verbose          # Run all tests with full output"
	echo "  $0 --unit             # Run only unit tests"
	echo "  $0 --integration      # Run only integration tests"
	echo "  VERBOSE_TESTS=true $0 # Run all tests with full output"
}

# Test type selection
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=true

# Parse command line arguments
parse_arguments() {
	while [ $# -gt 0 ]; do
		case "$1" in
			-v|--verbose)
				VERBOSE_TESTS=true
				export VERBOSE_TESTS
				shift
				;;
			-u|--unit)
				RUN_UNIT_TESTS=true
				RUN_INTEGRATION_TESTS=false
				shift
				;;
			-i|--integration)
				RUN_UNIT_TESTS=false
				RUN_INTEGRATION_TESTS=true
				shift
				;;
			-h|--help)
				show_usage
				exit 0
				;;
			*)
				echo "Unknown option: $1" >&2
				show_usage >&2
				exit 1
				;;
		esac
	done
}

# Check test prerequisites
check_prerequisites() {
	missing=""
	prereqs="timeout git"  # Space-separated list of required commands
	
	for cmd in $prereqs; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			missing="$missing $cmd"
		fi
	done
	
	if [ -n "$missing" ]; then
		echo "ERROR: Missing required test prerequisites:$missing" >&2
		echo "Please install the missing commands and try again." >&2
		exit 1
	fi
}

# Main execution
# Parse command line arguments first
parse_arguments "$@"

# Find the project root directory
PROJECT_ROOT="$(get_project_root)"

# Show what tests will be run
if [ "$RUN_UNIT_TESTS" = "true" ] && [ "$RUN_INTEGRATION_TESTS" = "true" ]; then
	echo "Running all ai-rizz tests from: $PROJECT_ROOT"
elif [ "$RUN_UNIT_TESTS" = "true" ]; then
	echo "Running unit tests from: $PROJECT_ROOT"
elif [ "$RUN_INTEGRATION_TESTS" = "true" ]; then
	echo "Running integration tests from: $PROJECT_ROOT"
else
	echo "No tests selected to run"
	exit 0
fi

# Check prerequisites first
check_prerequisites

# Verify ai-rizz script exists
if [ ! -f "$PROJECT_ROOT/ai-rizz" ]; then
	echo "ERROR: Cannot find ai-rizz script at $PROJECT_ROOT/ai-rizz" >&2
	exit 1
fi

failed=0
total=0

for test_file in $(find_tests); do
	total=$((total + 1))
	if ! run_test "$test_file"; then
		failed=$((failed + 1))
	fi
	if [ "$VERBOSE_TESTS" = "true" ]; then
		echo
	fi
done

# Return to the original directory
cd "$ORIG_DIR" || exit 1

echo "Test results: $((total - failed))/$total passed"

if [ "$failed" -gt 0 ]; then
	exit 1
fi

exit 0 