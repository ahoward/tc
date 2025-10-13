#!/usr/bin/env bash
# tc test executor
# mission control for test runs 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/json.sh"
source "$(dirname "${BASH_SOURCE[0]}")/discovery.sh"
source "$(dirname "${BASH_SOURCE[0]}")/validator.sh"
source "$(dirname "${BASH_SOURCE[0]}")/runner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/comparator.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/timer.sh"

# execute single test suite
tc_execute_suite() {
    local suite_dir="$1"
    local mode="${2:-$TC_DEFAULT_COMPARISON}"

    tc_info "executing suite: $suite_dir"

    # validate suite structure
    local validation_errors=$(tc_validate_suite "$suite_dir")
    if [ $? -ne 0 ]; then
        tc_error "suite validation failed:"
        echo "$validation_errors" >&2
        return 1
    fi

    # get suite timeout
    local timeout=$(tc_get_suite_timeout "$suite_dir")
    tc_debug "suite timeout: ${timeout}s"

    # find all scenarios
    local scenarios=$(tc_find_scenarios "$suite_dir")
    local scenario_count=$(echo "$scenarios" | wc -l)

    tc_info "found $scenario_count scenario(s)"

    # results tracking
    local passed=0
    local failed=0
    local errors=0
    local results=()

    # execute each scenario
    while read -r scenario_dir; do
        local scenario_name=$(tc_scenario_name "$scenario_dir")

        tc_progress "  $scenario_name"

        # validate scenario
        local scenario_errors=$(tc_validate_scenario "$scenario_dir")
        if [ $? -ne 0 ]; then
            tc_progress_fail
            tc_error "scenario validation failed: $scenario_errors"
            ((errors++))
            results+=("$scenario_name|error|0|validation failed")
            continue
        fi

        # run scenario
        local runner_result=$(tc_run_scenario "$suite_dir" "$scenario_dir" "$timeout")
        if [ $? -ne 0 ]; then
            tc_progress_fail
            ((errors++))
            results+=("$scenario_name|error|0|runner failed")
            continue
        fi

        # parse runner output
        IFS='|' read -r output_file stderr_file exit_code duration <<< "$runner_result"

        # check exit code
        if [ "$exit_code" -eq 124 ]; then
            tc_progress_fail
            tc_error "timeout after ${timeout}s"
            ((errors++))
            results+=("$scenario_name|timeout|$duration|exceeded timeout")
            tc_cleanup_runner_output "$output_file" "$stderr_file"
            continue
        elif [ "$exit_code" -ne 0 ]; then
            tc_progress_fail
            tc_error "runner exited with code $exit_code"
            ((errors++))
            results+=("$scenario_name|error|$duration|exit code $exit_code")
            tc_cleanup_runner_output "$output_file" "$stderr_file"
            continue
        fi

        # extract actual output
        local actual_output=$(tc_extract_actual_output "$output_file")

        # compare output
        tc_compare_output "$actual_output" "$scenario_dir/expected.json" "$mode"
        local comparison_result=$?

        if [ "$comparison_result" -eq 0 ]; then
            tc_progress_done
            ((passed++))
            results+=("$scenario_name|pass|$duration|")
        else
            tc_progress_fail
            ((failed++))
            local diff=$(tc_generate_diff "$actual_output" "$scenario_dir/expected.json" | head -20)
            results+=("$scenario_name|fail|$duration|$diff")
        fi

        # cleanup
        rm -f "$actual_output"
        tc_cleanup_runner_output "$output_file" "$stderr_file"

    done <<< "$scenarios"

    # return results (use ::: as separator between metadata and result lines)
    echo -n "$passed|$failed|$errors:::"
    printf "%s\n" "${results[@]}"

    # exit with appropriate code
    if [ "$failed" -gt 0 ] || [ "$errors" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}
