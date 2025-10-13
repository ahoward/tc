#!/usr/bin/env bash
# tc test suite discovery
# finding test sites from the chopper 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"

# find all test suites under a directory
tc_discover_suites() {
    local search_path="${1:-.}"
    local pattern="${2:-*}"

    tc_debug "discovering test suites in: $search_path"

    # find directories containing a 'run' executable
    find "$search_path" -type f -name "run" -executable 2>/dev/null | while read -r runner; do
        local suite_dir=$(dirname "$runner")

        # check if this matches the pattern (if specified)
        if [[ "$suite_dir" == $pattern ]]; then
            echo "$suite_dir"
        elif [ "$pattern" = "*" ]; then
            echo "$suite_dir"
        fi
    done
}

# check if we're in the TC development repo
tc_is_tc_repo() {
    # We're in TC repo if tc/bin/tc exists and TC_ROOT points to tc/
    [ -f "$TC_ROOT/bin/tc" ] && [ "$TC_ROOT" = "$(cd "$TC_ROOT" && pwd)" ]
}

# find all test suites recursively
tc_discover_suites_recursive() {
    local search_path="${1:-.}"
    local pattern="${2:-}"

    tc_debug "recursive discovery in: $search_path (pattern: ${pattern:-none})"

    find "$search_path" -type f -name "run" -executable 2>/dev/null | while read -r runner; do
        local suite_dir=$(dirname "$runner")

        # Quine-like behavior: exclude TC's self-tests when searching user directories
        # If we're in TC repo and searching a path that's NOT explicitly tc/tests,
        # then skip any suites that are under TC_ROOT/tests
        if tc_is_tc_repo; then
            # Get absolute paths for comparison
            local abs_suite_dir="$(cd "$suite_dir" && pwd)"
            local abs_search_path="$(cd "$search_path" && pwd)"
            local tc_tests_path="$TC_ROOT/tests"

            # If search path is not under tc/tests but suite is, skip it
            if [[ "$abs_search_path" != "$tc_tests_path"* ]] && [[ "$abs_suite_dir" == "$tc_tests_path"* ]]; then
                tc_debug "skipping TC self-test: $suite_dir (quine-like behavior)"
                continue
            fi
        fi

        # apply pattern filter if specified
        if [ -n "$pattern" ]; then
            case "$suite_dir" in
                *$pattern*)
                    echo "$suite_dir"
                    ;;
            esac
        else
            echo "$suite_dir"
        fi
    done | sort
}

# check if a directory is a test suite
tc_is_test_suite() {
    local dir="$1"

    [ -d "$dir" ] && [ -x "$dir/run" ]
    return $?
}

# count test suites in directory
tc_count_suites() {
    local search_path="${1:-.}"

    tc_discover_suites_recursive "$search_path" | wc -l
}

# get suite name from path
tc_suite_name() {
    local suite_path="$1"

    basename "$suite_path"
}

# get suite relative path from root
tc_suite_relative_path() {
    local suite_path="$1"
    local root_path="${2:-.}"

    realpath --relative-to="$root_path" "$suite_path" 2>/dev/null || echo "$suite_path"
}
