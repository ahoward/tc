#!/usr/bin/env bash
# tc json utilities
# jq wrappers for the helicopter crew 🚁

# check if jq is available
tc_check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        tc_error "jq not found - tc requires jq for json processing"
        tc_error "install: apt install jq | brew install jq | yum install jq"
        return 1
    fi
    return 0
}

# parse json file
tc_json_parse() {
    local file="$1"
    local query="${2:-.}"

    if [ ! -f "$file" ]; then
        tc_error "json file not found: $file"
        return 1
    fi

    jq -r "$query" "$file" 2>/dev/null
}

# validate json file
tc_json_valid() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    jq empty "$file" >/dev/null 2>&1
    return $?
}

# semantic json comparison (order-independent for objects)
tc_json_compare() {
    local file1="$1"
    local file2="$2"

    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        tc_error "json files not found for comparison"
        return 2
    fi

    # normalize and sort both json structures
    local json1=$(jq -S '.' "$file1" 2>/dev/null)
    local json2=$(jq -S '.' "$file2" 2>/dev/null)

    if [ $? -ne 0 ]; then
        tc_error "invalid json in one or both files"
        return 2
    fi

    # compare normalized json
    if [ "$json1" = "$json2" ]; then
        return 0  # match
    else
        return 1  # mismatch
    fi
}

# json diff - show differences between two json files
tc_json_diff() {
    local file1="$1"
    local file2="$2"

    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        echo "json files not found"
        return 2
    fi

    # use jq to show differences
    diff <(jq -S '.' "$file1" 2>/dev/null) <(jq -S '.' "$file2" 2>/dev/null) || true
}

# extract field from json
tc_json_get() {
    local file="$1"
    local field="$2"

    tc_json_parse "$file" ".${field}"
}

# create json object from key-value pairs
tc_json_create() {
    jq -n "$@"
}
