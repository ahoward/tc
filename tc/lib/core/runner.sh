#!/usr/bin/env bash
# tc test runner executor
# taking the chopper up 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/json.sh"

# execute test runner with scenario input
tc_run_scenario() {
    local suite_dir="$1"
    local scenario_dir="$2"
    local timeout="${3:-$TC_DEFAULT_TIMEOUT}"

    local runner="$suite_dir/run"
    local input_file="$scenario_dir/input.json"
    local scenario_name=$(basename "$scenario_dir")

    tc_debug "running scenario: $scenario_name"
    tc_debug "runner: $runner"
    tc_debug "input: $input_file"

    # check runner exists and is executable
    if [ ! -x "$runner" ]; then
        tc_error "runner not executable: $runner"
        return 2
    fi

    # check input file exists
    if [ ! -f "$input_file" ]; then
        tc_error "input file not found: $input_file"
        return 2
    fi

    # execute runner with input file
    local start_time=$(date +%s%3N)  # milliseconds
    local output_file=$(mktemp)
    local stderr_file=$(mktemp)
    local exit_code=0

    # run with timeout (handled by timer.sh)
    "$runner" "$input_file" >"$output_file" 2>"$stderr_file" || exit_code=$?

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    tc_debug "runner exit code: $exit_code"
    tc_debug "duration: ${duration}ms"

    # check if output is valid json
    if ! tc_json_valid "$output_file"; then
        tc_error "runner produced invalid json output"
        cat "$output_file" >&2
        rm -f "$output_file" "$stderr_file"
        return 2
    fi

    # return output file path for comparison
    echo "$output_file|$stderr_file|$exit_code|$duration"
    return 0
}

# parse runner output
tc_parse_runner_output() {
    local output_file="$1"

    if [ ! -f "$output_file" ]; then
        return 1
    fi

    # extract fields from runner output
    local scenario=$(tc_json_get "$output_file" "scenario")
    local status=$(tc_json_get "$output_file" "status")
    local duration=$(tc_json_get "$output_file" "duration_ms")

    echo "$scenario|$status|$duration"
}

# cleanup temp files
tc_cleanup_runner_output() {
    local output_file="$1"
    local stderr_file="${2:-}"

    rm -f "$output_file" "$stderr_file"
}
