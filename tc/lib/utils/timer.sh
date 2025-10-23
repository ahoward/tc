#!/usr/bin/env bash
# tc timeout management
# keeping the chopper from flying too long 🚁

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# run command with timeout (TERM then KILL escalation)
tc_run_with_timeout() {
    local timeout_seconds="$1"
    shift
    local command=("$@")

    tc_debug "running with timeout: ${timeout_seconds}s"
    tc_debug "command: ${command[*]}"

    # run command in background
    "${command[@]}" &
    local pid=$!

    tc_debug "spawned process: $pid"

    # monitor with timeout
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout_seconds" ]; then
            tc_warn "timeout reached (${timeout_seconds}s), terminating process $pid"

            # graceful termination (TERM)
            kill -TERM "$pid" 2>/dev/null
            sleep 2

            # force kill if still alive (KILL)
            if kill -0 "$pid" 2>/dev/null; then
                tc_warn "process $pid still alive, force killing"
                kill -KILL "$pid" 2>/dev/null
            fi

            # wait for process to die
            wait "$pid" 2>/dev/null

            return 124  # standard timeout exit code
        fi

        sleep 1
        elapsed=$((elapsed + 1))
    done

    # get actual exit code
    wait "$pid"
    local exit_code=$?

    tc_debug "process $pid exited with code: $exit_code"
    return $exit_code
}

# get timeout for suite (from config or default)
tc_get_suite_timeout() {
    local suite_dir="$1"
    local default_timeout="${2:-$TC_DEFAULT_TIMEOUT}"

    # check for .tc-config file
    if [ -f "$suite_dir/.tc-config" ]; then
        local timeout=$(grep '^timeout=' "$suite_dir/.tc-config" | cut -d= -f2)
        if [[ "$timeout" =~ ^[0-9]+$ ]]; then
            echo "$timeout"
            return 0
        fi
    fi

    echo "$default_timeout"
}

# check if timeout is valid
tc_validate_timeout() {
    local timeout="$1"

    if ! [[ "$timeout" =~ ^[0-9]+$ ]] || [ "$timeout" -lt 1 ]; then
        return 1
    fi

    if [ "$timeout" -gt "$TC_MAX_TIMEOUT" ]; then
        tc_warn "timeout exceeds maximum (${TC_MAX_TIMEOUT}s), clamping"
        return 1
    fi

    return 0
}

# start a timer (returns timestamp in milliseconds)
tc_timer_start() {
    date +%s%3N  # milliseconds since epoch
}

# stop timer and return duration in milliseconds
tc_timer_stop() {
    local start_time="$1"
    local end_time=$(date +%s%3N)
    echo $((end_time - start_time))
}
