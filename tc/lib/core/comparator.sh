#!/usr/bin/env bash
# tc output comparator
# checking if we hit the landing zone 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/json.sh"

# compare test output using specified mode
tc_compare_output() {
    local actual_file="$1"
    local expected_file="$2"
    local mode="${3:-$TC_DEFAULT_COMPARISON}"

    tc_debug "comparing output (mode: $mode)"
    tc_debug "actual: $actual_file"
    tc_debug "expected: $expected_file"

    case "$mode" in
        semantic_json)
            tc_compare_semantic_json "$actual_file" "$expected_file"
            ;;
        whitespace_norm)
            tc_compare_whitespace_norm "$actual_file" "$expected_file"
            ;;
        fuzzy)
            tc_compare_fuzzy "$actual_file" "$expected_file"
            ;;
        *)
            tc_error "unknown comparison mode: $mode"
            return 2
            ;;
    esac
}

# semantic json comparison (order-independent for objects)
tc_compare_semantic_json() {
    local actual_file="$1"
    local expected_file="$2"

    # use json.sh utility
    tc_json_compare "$actual_file" "$expected_file"
    return $?
}

# whitespace normalization comparison
tc_compare_whitespace_norm() {
    local actual_file="$1"
    local expected_file="$2"

    # normalize whitespace: trim, collapse multiple spaces
    local actual_norm=$(cat "$actual_file" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
    local expected_norm=$(cat "$expected_file" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')

    if [ "$actual_norm" = "$expected_norm" ]; then
        return 0  # match
    else
        return 1  # mismatch
    fi
}

# fuzzy matching comparison (placeholder for now)
tc_compare_fuzzy() {
    local actual_file="$1"
    local expected_file="$2"
    local threshold="${TC_FUZZY_THRESHOLD:-0.9}"

    # for mvp, fall back to semantic json
    # full fuzzy implementation (levenshtein distance) in polish phase
    tc_warn "fuzzy matching not yet implemented, falling back to semantic_json"
    tc_compare_semantic_json "$actual_file" "$expected_file"
}

# extract actual output from runner result
tc_extract_actual_output() {
    local runner_output_file="$1"

    # runner outputs raw json directly, so just return the file path
    echo "$runner_output_file"
}

# generate diff for failed comparison
tc_generate_diff() {
    local actual_file="$1"
    local expected_file="$2"

    tc_json_diff "$actual_file" "$expected_file"
}
