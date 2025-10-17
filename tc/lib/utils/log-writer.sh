#!/usr/bin/env bash
# tc/lib/utils/log-writer.sh - JSONL log file writer for test execution data
#
# This module provides functions for writing machine-readable test execution
# logs in JSONL format (JSON Lines - one JSON object per line).
#
# Part of: heli-cool-stdout feature (004) - User Story 3
# Dependencies: jq for JSON generation, config/defaults.sh for env vars

# Global log file path
TC_LOG_FILE_PATH=""

# tc_log_init()
#
# Initialize log file system (T047).
# Creates .tc-reports/ directory and sets log file path.
#
# Returns:
#   Exit code 0 on success
#   Exit code 1 if log directory cannot be created
#   Stderr: Error message on failure
tc_log_init() {
    local log_dir="${TC_REPORT_DIR:-.tc-reports}"

    # Create log directory if it doesn't exist
    if [ ! -d "$log_dir" ]; then
        if ! mkdir -p "$log_dir" 2>/dev/null; then
            echo "ERROR: Failed to create log directory: $log_dir" >&2
            return 1
        fi
    fi

    # Set log file path
    local log_file="${TC_LOG_FILE:-report.jsonl}"
    TC_LOG_FILE_PATH="$log_dir/$log_file"

    return 0
}

# tc_log_get_path()
#
# Get current log file path (T049).
#
# Returns:
#   Outputs absolute path to log file to stdout
#   Exit code 0
tc_log_get_path() {
    # If not initialized, return default
    if [ -z "$TC_LOG_FILE_PATH" ]; then
        local log_dir="${TC_REPORT_DIR:-.tc-reports}"
        local log_file="${TC_LOG_FILE:-report.jsonl}"
        echo "$log_dir/$log_file"
    else
        echo "$TC_LOG_FILE_PATH"
    fi
    return 0
}

# tc_log_timestamp()
#
# Generate ISO 8601 timestamp for log entries (T050).
#
# Returns:
#   Outputs ISO 8601 timestamp (UTC) to stdout
#   Exit code 0
tc_log_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
    return 0
}

# tc_log_write(suite_path, test_name, status, duration_ms, [error])
#
# Write test result to JSONL log (T048, T051).
# Appends one JSON object per line to log file.
#
# Args:
#   $1: Suite path (relative or absolute)
#   $2: Test name
#   $3: Status ("pass", "fail", "error")
#   $4: Duration in milliseconds
#   $5: Error message (optional, for fail/error status)
#
# Returns:
#   Exit code 0 on success
#   Exit code 1 on write failure
#   Stderr: Error message if write fails
tc_log_write() {
    local suite_path="$1"
    local test_name="$2"
    local status="$3"
    local duration_ms="$4"
    local error="${5:-}"

    # Get log file path
    local log_path=$(tc_log_get_path)

    # Generate timestamp (T050)
    local timestamp=$(tc_log_timestamp)

    # Create JSON entry with jq (T048, T051)
    local json_entry
    if [ -n "$error" ]; then
        # Include error field if present (T055)
        json_entry=$(jq -n \
            --arg timestamp "$timestamp" \
            --arg suite "$suite_path" \
            --arg test "$test_name" \
            --arg status "$status" \
            --argjson duration "$duration_ms" \
            --arg error "$error" \
            '{
                timestamp: $timestamp,
                suite_path: $suite,
                test_name: $test,
                status: $status,
                duration_ms: $duration,
                error: $error
            }')
    else
        # No error field
        json_entry=$(jq -n \
            --arg timestamp "$timestamp" \
            --arg suite "$suite_path" \
            --arg test "$test_name" \
            --arg status "$status" \
            --argjson duration "$duration_ms" \
            '{
                timestamp: $timestamp,
                suite_path: $suite,
                test_name: $test,
                status: $status,
                duration_ms: $duration
            }')
    fi

    # Append to log file (T051 - JSONL format)
    if ! echo "$json_entry" >> "$log_path" 2>/dev/null; then
        echo "WARNING: Failed to write log entry to: $log_path" >&2
        return 1
    fi

    return 0
}
