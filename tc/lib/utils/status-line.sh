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
TC_START_TIME=""               # Start time in seconds since epoch

# Animation frames (T029)
TC_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# tc_next_spinner()
#
# Get next spinner frame and advance animation counter (T030).
#
# Returns:
#   Outputs spinner character to stdout
#   Exit code 0
tc_next_spinner() {
    local frame_count=${#TC_SPINNER_FRAMES[@]}
    local current_frame="${TC_SPINNER_FRAMES[$TC_ANIMATION_FRAME]}"

    # Advance frame counter
    TC_ANIMATION_FRAME=$(( (TC_ANIMATION_FRAME + 1) % frame_count ))

    echo "$current_frame"
    return 0
}

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

    # Record start time
    TC_START_TIME=$(date +%s)

    # Suppress INFO logging in TTY mode (show only status line + errors)
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        tc_ansi_hide_cursor >&2
        # Set log level to ERROR (3) to suppress INFO messages
        TC_LOG_LEVEL=3
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

    # Format status line with emoji and colors (T026-T028)
    local emoji="🚁"
    local status_label="$TC_STATUS_LABEL"

    # Apply colors if ANSI supported
    if tc_ansi_supported; then
        case "$TC_STATUS_LABEL" in
            RUNNING)
                status_label="$(tc_ansi_color yellow)${TC_STATUS_LABEL}$(tc_ansi_color reset)"
                ;;
            PASSED)
                status_label="$(tc_ansi_color green)${TC_STATUS_LABEL}$(tc_ansi_color reset)"
                ;;
            FAILED)
                status_label="$(tc_ansi_color red)${TC_STATUS_LABEL}$(tc_ansi_color reset)"
                ;;
        esac
    fi

    # Get animation (T031)
    local animation=""
    if [ "$TC_STATUS_LABEL" = "RUNNING" ] && [ "$TC_NO_ANIMATION" != "1" ]; then
        animation=" $(tc_next_spinner)"
    fi

    # Format: emoji : COLOR_LABEL : suite/test : animation
    local status_line="${emoji} : ${status_label} : ${suite}/${test}${animation}"

    # In TTY mode, append log path on failure
    if [ "$TC_STATUS_MODE" = "tty" ] && [ "$TC_STATUS_LABEL" = "FAILED" ]; then
        local log_path=$(tc_log_get_path 2>/dev/null || echo ".tc-reports/report.jsonl")
        status_line="${status_line} - see ${log_path}"
    fi

    # T032: Truncate if status line too long for terminal
    local max_width=$(tc_terminal_width)
    # Account for ANSI codes (they don't take visual space but add characters)
    # Simple heuristic: if line looks too long, truncate suite/test part
    if [ ${#status_line} -gt $((max_width + 20)) ]; then
        # Truncate suite/test with ellipsis
        local available=$(( max_width - 30 ))  # Reserve space for prefix and animation
        if [ $available -lt 10 ]; then
            available=10
        fi
        local truncated_path="${suite}/${test}"
        if [ ${#truncated_path} -gt $available ]; then
            truncated_path="${truncated_path:0:$((available-3))}..."
        fi
        status_line="${emoji} : ${status_label} : ${truncated_path}${animation}"
    fi

    # Output only in TTY mode (send to stderr to not interfere with result data)
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        # TTY mode: clear line, rewrite in place
        printf '\r\033[2K%s' "$status_line" >&2
    fi
    # Non-TTY mode: no output (tc_progress handles this)

    return 0
}

# tc_status_finish(passed, failed, errors)
#
# Finalize status line and print summary.
# Shows cursor if TTY, clears status line, prints final stats.
#
# Args:
#   $1: Total tests passed
#   $2: Total tests failed
#   $3: Total tests with errors (optional, defaults to 0)
#
# Returns:
#   Outputs final summary to stdout
#   Exit code 0 if all passed, 1 if any failed
tc_status_finish() {
    local passed="$1"
    local failed="$2"
    local errors="${3:-0}"
    local total=$((passed + failed + errors))

    # In TTY mode: show cursor, clear line, print stats summary
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        tc_ansi_show_cursor >&2
        # Clear the current status line
        printf '\r\033[2K' >&2

        # Calculate duration
        local end_time=$(date +%s)
        local duration=$((end_time - TC_START_TIME))
        local duration_str="${duration}s"
        if [ "$duration" -ge 60 ]; then
            local minutes=$((duration / 60))
            local seconds=$((duration % 60))
            duration_str="${minutes}m${seconds}s"
        fi

        # Format stats line with colors (always use colors in TTY mode)
        local emoji="🚁"
        local green="$(tc_ansi_color green)"
        local red="$(tc_ansi_color red)"
        local yellow="$(tc_ansi_color yellow)"
        local reset="$(tc_ansi_color reset)"

        local stats="${green}${passed} passed${reset}"
        if [ "$failed" -gt 0 ]; then
            stats="${stats}, ${red}${failed} failed${reset}"
        fi
        if [ "$errors" -gt 0 ]; then
            stats="${stats}, ${yellow}${errors} errors${reset}"
        fi

        # Print final stats line
        printf '%s : %s - %s\n' "$emoji" "$stats" "$duration_str" >&2

        # Return exit code
        return $([ "$failed" -eq 0 ] && [ "$errors" -eq 0 ] && echo 0 || echo 1)
    fi

    # Non-TTY mode: Print summary (output to stderr to not interfere with result data)
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
