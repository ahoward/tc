#!/usr/bin/env bash
# tc/lib/utils/status-line.sh - Single-line animated test status output
#
# This module provides functions for displaying test execution status in a
# single updating line (TTY mode) or line-oriented plain text (non-TTY mode).
#
# Part of: heli-cool-stdout feature (004) - User Story 1 (MVP)
# Dependencies: ansi.sh for ANSI codes, config/defaults.sh for env vars

# Global state variables for status line
TC_STATUS_MODE=""              # "tty" or "non-tty"
TC_CURRENT_SUITE=""
TC_CURRENT_TEST=""
TC_TESTS_PASSED=0
TC_TESTS_FAILED=0
TC_TESTS_TOTAL=0
TC_ANIMATION_FRAME=0
TC_STATUS_LABEL="RUNNING"
TC_TERMINAL_WIDTH=80

# tc_terminal_width()
#
# Get current terminal width in columns.
# Uses tput cols with fallback to 80 if unavailable.
#
# Returns:
#   Outputs integer width to stdout
#   Exit code 0
tc_terminal_width() {
    local width=$(tput cols 2>/dev/null)
    echo "${width:-80}"
    return 0
}

# tc_status_init()
#
# Initialize status line system.
# Detects TTY mode, hides cursor if TTY, initializes state variables.
#
# Returns:
#   Exit code 0 on success
#   Sets global TC_STATUS_* variables
tc_status_init() {
    # Detect TTY mode
    if [ -t 1 ]; then
        TC_STATUS_MODE="tty"
    else
        TC_STATUS_MODE="non-tty"
    fi

    # Check for TC_FANCY_OUTPUT override
    if [ -n "$TC_FANCY_OUTPUT" ]; then
        if [ "$TC_FANCY_OUTPUT" = "false" ]; then
            TC_STATUS_MODE="non-tty"
        elif [ "$TC_FANCY_OUTPUT" = "true" ]; then
            TC_STATUS_MODE="tty"
        fi
    fi

    # Initialize state
    TC_CURRENT_SUITE=""
    TC_CURRENT_TEST=""
    TC_TESTS_PASSED=0
    TC_TESTS_FAILED=0
    TC_TESTS_TOTAL=0
    TC_ANIMATION_FRAME=0
    TC_STATUS_LABEL="RUNNING"
    TC_TERMINAL_WIDTH=$(tc_terminal_width)

    # Hide cursor in TTY mode
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        tc_ansi_hide_cursor
    fi

    return 0
}

# tc_status_update(suite, test, status, passed, failed)
#
# Update status line with current test information.
# In TTY mode: updates in place using CR + line rewrite
# In non-TTY mode: outputs new line
#
# Args:
#   $1: Suite name
#   $2: Test name
#   $3: Status ("running", "passed", "failed")
#   $4: Tests passed count
#   $5: Tests failed count
#
# Returns:
#   Outputs formatted status line to stdout
#   Exit code 0
tc_status_update() {
    local suite="$1"
    local test="$2"
    local status="$3"
    local passed="$4"
    local failed="$5"

    # Update global state
    TC_CURRENT_SUITE="$suite"
    TC_CURRENT_TEST="$test"
    TC_TESTS_PASSED="$passed"
    TC_TESTS_FAILED="$failed"
    TC_TESTS_TOTAL=$((passed + failed))

    # Update status label
    case "$status" in
        running)
            TC_STATUS_LABEL="RUNNING"
            ;;
        passed)
            if [ "$failed" -eq 0 ]; then
                TC_STATUS_LABEL="PASSED"
            else
                TC_STATUS_LABEL="RUNNING"
            fi
            ;;
        failed)
            TC_STATUS_LABEL="FAILED"
            ;;
    esac

    # Format status line
    local status_line="RUNNING : ${suite}/${test}"

    # Output based on mode (send to stderr to not interfere with result data)
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        # TTY mode: clear line, rewrite in place
        printf '\r\033[2K%s' "$status_line" >&2
    else
        # Non-TTY mode: output new line
        printf '%s\n' "$status_line" >&2
    fi

    return 0
}

# tc_status_finish(passed, failed)
#
# Finalize status line and print summary.
# Shows cursor if TTY, clears status line, prints final report.
#
# Args:
#   $1: Total tests passed
#   $2: Total tests failed
#
# Returns:
#   Outputs final summary to stdout
#   Exit code 0 if all passed, 1 if any failed
tc_status_finish() {
    local passed="$1"
    local failed="$2"
    local total=$((passed + failed))

    # Show cursor in TTY mode (output to stderr)
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        tc_ansi_show_cursor >&2
        # Clear the status line
        printf '\r\033[2K' >&2
    fi

    # Print final summary (output to stderr to not interfere with result data)
    printf '\n' >&2
    printf 'Tests complete:\n' >&2
    printf '  Passed: %d\n' "$passed" >&2
    printf '  Failed: %d\n' "$failed" >&2
    printf '  Total:  %d\n' "$total" >&2
    printf '\n' >&2

    # Return exit code
    if [ "$failed" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}
