#!/usr/bin/env bash
# tc logging utilities
# keeping theodore informed 🚁

# log levels
TC_LOG_DEBUG=0
TC_LOG_INFO=1
TC_LOG_WARN=2
TC_LOG_ERROR=3

TC_LOG_LEVEL=${TC_LOG_LEVEL:-$TC_LOG_INFO}

# timestamp for logs
_tc_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# log to stderr with level
_tc_log() {
    local level=$1
    shift
    local message="$*"

    echo "[$(_tc_timestamp)] $level: $message" >&2
}

# debug - only shown if TC_DEBUG=1
tc_debug() {
    if [ "$TC_DEBUG" = "1" ] || [ "$TC_LOG_LEVEL" -le "$TC_LOG_DEBUG" ]; then
        _tc_log "DEBUG" "$@"
    fi
}

# info - regular informational messages
tc_info() {
    if [ "$TC_LOG_LEVEL" -le "$TC_LOG_INFO" ]; then
        _tc_log "INFO" "$@"
    fi
}

# warn - warnings that don't stop execution
tc_warn() {
    if [ "$TC_LOG_LEVEL" -le "$TC_LOG_WARN" ]; then
        _tc_log "WARN" "$@"
    fi
}

# error - errors (usually followed by exit)
tc_error() {
    _tc_log "ERROR" "$@"
}

# fatal - error and exit
tc_fatal() {
    tc_error "$@"
    exit 1
}

# progress indicator for long operations
tc_progress() {
    local message="$1"
    echo -n "$(date '+%H:%M:%S') ${message}..." >&2
}

# complete progress indicator
tc_progress_done() {
    echo " ✓" >&2
}

# fail progress indicator
tc_progress_fail() {
    echo " ✗" >&2
}
