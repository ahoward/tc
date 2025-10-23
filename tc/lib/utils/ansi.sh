#!/usr/bin/env bash
# tc/lib/utils/ansi.sh - ANSI escape code utilities for terminal output
#
# This module provides functions for terminal color codes, cursor control,
# and ANSI capability detection. Supports TTY detection and NO_COLOR convention.
#
# Part of: heli-cool-stdout feature (004)
# Dependencies: None (POSIX-compatible)

# ANSI color constants (SGR - Select Graphic Rendition)
# Format: \033[<code>m where 033 is ESC in octal
readonly TC_ANSI_GREEN='\033[0;32m'
readonly TC_ANSI_RED='\033[0;31m'
readonly TC_ANSI_YELLOW='\033[0;33m'
readonly TC_ANSI_BLUE='\033[0;34m'
readonly TC_ANSI_MAGENTA='\033[0;35m'
readonly TC_ANSI_CYAN='\033[0;36m'
readonly TC_ANSI_RESET='\033[0m'

# ANSI cursor control codes
readonly TC_ANSI_CLEAR_LINE='\033[2K'      # Clear entire line
readonly TC_ANSI_HIDE_CURSOR='\033[?25l'   # Hide cursor
readonly TC_ANSI_SHOW_CURSOR='\033[?25h'   # Show cursor
readonly TC_ANSI_CR='\r'                    # Carriage return (move to line start)

# tc_ansi_supported()
#
# Detect if terminal supports ANSI escape codes.
# Checks: stdout is TTY, TERM is not "dumb", NO_COLOR is not set
#
# Returns:
#   0 if ANSI supported
#   1 if not supported
tc_ansi_supported() {
    # Check if stdout is a TTY
    [ -t 1 ] || return 1

    # Check TERM variable
    [ -n "$TERM" ] || return 1
    [ "$TERM" != "dumb" ] || return 1

    # Check NO_COLOR convention (https://no-color.org/)
    [ -z "$NO_COLOR" ] || return 1

    return 0
}

# tc_ansi_color(name)
#
# Output ANSI color code for given color name.
# Always outputs color code regardless of TTY support.
# Caller should check tc_ansi_supported() first if needed.
#
# Args:
#   $1: Color name (green|red|yellow|blue|magenta|cyan|reset)
#
# Returns:
#   Outputs ANSI escape sequence to stdout
#   Exit code 0 on success, 1 for invalid color name
tc_ansi_color() {
    local color_name="$1"

    case "$color_name" in
        green)
            printf '%b' "$TC_ANSI_GREEN"
            ;;
        red)
            printf '%b' "$TC_ANSI_RED"
            ;;
        yellow)
            printf '%b' "$TC_ANSI_YELLOW"
            ;;
        blue)
            printf '%b' "$TC_ANSI_BLUE"
            ;;
        magenta)
            printf '%b' "$TC_ANSI_MAGENTA"
            ;;
        cyan)
            printf '%b' "$TC_ANSI_CYAN"
            ;;
        reset)
            printf '%b' "$TC_ANSI_RESET"
            ;;
        *)
            # Invalid color name - output nothing, return error
            return 1
            ;;
    esac

    return 0
}

# tc_ansi_clear_line()
#
# Output ANSI code to clear current line.
# Use before rewriting line to prevent artifacts.
#
# Returns:
#   Outputs ANSI escape sequence to stdout
#   Exit code 0
tc_ansi_clear_line() {
    printf '%b' "$TC_ANSI_CLEAR_LINE"
    return 0
}

# tc_ansi_hide_cursor()
#
# Output ANSI code to hide terminal cursor.
# Use at start of animated status line display.
#
# Returns:
#   Outputs ANSI escape sequence to stdout
#   Exit code 0
tc_ansi_hide_cursor() {
    printf '%b' "$TC_ANSI_HIDE_CURSOR"
    return 0
}

# tc_ansi_show_cursor()
#
# Output ANSI code to show terminal cursor.
# Use when finishing status line display or on cleanup.
#
# Returns:
#   Outputs ANSI escape sequence to stdout
#   Exit code 0
tc_ansi_show_cursor() {
    printf '%b' "$TC_ANSI_SHOW_CURSOR"
    return 0
}
