#!/usr/bin/env bash
# tc test suite validator
# pre-flight checklist 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/json.sh"

# validate test suite structure
tc_validate_suite() {
    local suite_dir="$1"
    local errors=()

    tc_debug "validating suite: $suite_dir"

    # check if directory exists
    if [ ! -d "$suite_dir" ]; then
        errors+=("suite directory does not exist: $suite_dir")
        echo "${errors[@]}"
        return 1
    fi

    # check for runner executable
    if [ ! -f "$suite_dir/run" ]; then
        errors+=("missing runner: $suite_dir/run")
    elif [ ! -x "$suite_dir/run" ]; then
        errors+=("runner not executable: $suite_dir/run")
    fi

    # check for data directory
    if [ ! -d "$suite_dir/data" ]; then
        errors+=("missing data directory: $suite_dir/data")
    else
        # check for at least one scenario
        local scenario_count=$(tc_count_scenarios "$suite_dir")
        if [ "$scenario_count" -eq 0 ]; then
            errors+=("no test scenarios found in $suite_dir/data")
        fi
    fi

    # return errors if any
    if [ ${#errors[@]} -gt 0 ]; then
        printf "%s\n" "${errors[@]}"
        return 1
    fi

    return 0
}

# validate test scenario
tc_validate_scenario() {
    local scenario_dir="$1"
    local errors=()

    tc_debug "validating scenario: $scenario_dir"

    # check if directory exists
    if [ ! -d "$scenario_dir" ]; then
        errors+=("scenario directory does not exist: $scenario_dir")
        echo "${errors[@]}"
        return 1
    fi

    # check for input.json
    if [ ! -f "$scenario_dir/input.json" ]; then
        errors+=("missing input.json in $scenario_dir")
    else
        # validate json
        if ! tc_json_valid "$scenario_dir/input.json"; then
            errors+=("invalid json in $scenario_dir/input.json")
        fi
    fi

    # check for expected.json
    if [ ! -f "$scenario_dir/expected.json" ]; then
        errors+=("missing expected.json in $scenario_dir")
    else
        # validate json
        if ! tc_json_valid "$scenario_dir/expected.json"; then
            errors+=("invalid json in $scenario_dir/expected.json")
        fi
    fi

    # return errors if any
    if [ ${#errors[@]} -gt 0 ]; then
        printf "%s\n" "${errors[@]}"
        return 1
    fi

    return 0
}

# find all scenarios in suite
tc_find_scenarios() {
    local suite_dir="$1"

    if [ ! -d "$suite_dir/data" ]; then
        return 1
    fi

    find "$suite_dir/data" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort
}

# count scenarios in suite
tc_count_scenarios() {
    local suite_dir="$1"

    tc_find_scenarios "$suite_dir" | wc -l
}

# get scenario name from path
tc_scenario_name() {
    local scenario_dir="$1"

    basename "$scenario_dir"
}

# validate suite and all scenarios
tc_validate_suite_full() {
    local suite_dir="$1"
    local all_errors=()

    # validate suite structure
    local suite_errors=$(tc_validate_suite "$suite_dir")
    if [ $? -ne 0 ]; then
        all_errors+=("$suite_errors")
    fi

    # validate each scenario
    tc_find_scenarios "$suite_dir" | while read -r scenario_dir; do
        local scenario_errors=$(tc_validate_scenario "$scenario_dir")
        if [ $? -ne 0 ]; then
            all_errors+=("$scenario_errors")
        fi
    done

    # return combined errors
    if [ ${#all_errors[@]} -gt 0 ]; then
        printf "%s\n" "${all_errors[@]}"
        return 1
    fi

    return 0
}
