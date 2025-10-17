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

# semantic json comparison (order-independent for objects, with pattern matching)
tc_json_compare() {
    local actual_file="$1"
    local expected_file="$2"

    if [ ! -f "$actual_file" ] || [ ! -f "$expected_file" ]; then
        tc_error "json files not found for comparison"
        return 2
    fi

    # check if expected contains patterns like <uuid>, <timestamp>, etc.
    if grep -qE '<[a-z_-]+>' "$expected_file" 2>/dev/null; then
        tc_json_compare_with_patterns "$actual_file" "$expected_file"
        return $?
    fi

    # no patterns, use normal comparison
    local json1=$(jq -S '.' "$actual_file" 2>/dev/null)
    local json2=$(jq -S '.' "$expected_file" 2>/dev/null)

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

# pattern-aware json comparison
tc_json_compare_with_patterns() {
    local actual_file="$1"
    local expected_file="$2"

    # use jq to validate patterns recursively
    local result=$(jq --slurpfile actual "$actual_file" \
                      --slurpfile expected "$expected_file" \
                      -n '
        def is_pattern: type == "string" and (startswith("<") and endswith(">"));

        def validate($actual_val; $expected_val):
          if ($expected_val | is_pattern) then
            # pattern matching
            if $expected_val == "<uuid>" then
              $actual_val | type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
            elif $expected_val == "<timestamp>" then
              $actual_val | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}")
            elif $expected_val == "<number>" then
              $actual_val | type == "number"
            elif $expected_val == "<string>" then
              $actual_val | type == "string"
            elif $expected_val == "<boolean>" then
              $actual_val | type == "boolean"
            elif $expected_val == "<null>" then
              $actual_val | type == "null"
            elif $expected_val == "<any>" then
              true
            else
              # unknown pattern
              false
            end
          elif ($expected_val | type) == "object" and ($actual_val | type) == "object" then
            # recursively validate object properties
            ($expected_val | keys) as $keys |
            (($actual_val | keys) | sort) == ($keys | sort) and
            ($keys | all(. as $k | validate($actual_val[$k]; $expected_val[$k])))
          elif ($expected_val | type) == "array" and ($actual_val | type) == "array" then
            # recursively validate array elements
            ($expected_val | length) == ($actual_val | length) and
            ([range($expected_val | length)] | all(. as $i | validate($actual_val[$i]; $expected_val[$i])))
          else
            # exact comparison for primitives
            $actual_val == $expected_val
          end;

        if ($actual | length) == 0 or ($expected | length) == 0 then
          false
        else
          validate($actual[0]; $expected[0])
        end
      ' 2>/dev/null)

    if [ $? -ne 0 ]; then
        tc_error "pattern validation failed (jq error)"
        return 2
    fi

    if [ "$result" = "true" ]; then
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
