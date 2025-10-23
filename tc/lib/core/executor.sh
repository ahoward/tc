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

    # initialize logging system (T053)
    tc_log_init

    # load suite-specific configuration if present
    if [ -f "$suite_dir/config.sh" ]; then
        tc_debug "loading suite config: $suite_dir/config.sh"
        source "$suite_dir/config.sh"
    fi

    # validate suite structure
    local validation_errors=$(tc_validate_suite "$suite_dir")
    if [ $? -ne 0 ]; then
        tc_error "suite validation failed:"
        echo "$validation_errors" >&2
        tc_status_finish 0 0  # cleanup
        return 1
    fi

    # get suite timeout
    local timeout=$(tc_get_suite_timeout "$suite_dir")
    tc_debug "suite timeout: ${timeout}s"

    # find all scenarios
    local scenarios=$(tc_find_scenarios "$suite_dir")
    local scenario_count=$(echo "$scenarios" | wc -l)

    tc_info "found $scenario_count scenario(s)"

    # Get suite name for status line
    local suite_name=$(basename "$suite_dir")

    # results tracking
    local passed=0
    local failed=0
    local errors=0
    local results=()

    # T015: Detect if suite has lifecycle hooks and delegate if present
    if tc_is_stateful_suite "$suite_dir"; then
        tc_debug "Suite has lifecycle hooks - delegating to hook-aware executor"

        # Delegate to hook-aware execution (US1: T017-T021)
        tc_execute_suite_with_hooks "$suite_dir" "$mode" passed failed errors results
        local suite_exit_code=$?

        # Don't finalize status line here - let the caller handle it

        # Return results (use ::: as separator between metadata and result lines)
        echo -n "$passed|$failed|$errors:::"
        printf "%s\n" "${results[@]}"

        return $suite_exit_code
    fi

    # execute each scenario (stateless mode - no hooks)
    while read -r scenario_dir; do
        local scenario_name=$(tc_scenario_name "$scenario_dir")

        # Only show progress in non-TTY mode (status line handles TTY mode)
        if [ "$TC_STATUS_MODE" != "tty" ]; then
            tc_progress "  $scenario_name"
        fi

        # Update status line (T019) - test starting
        tc_status_update "$suite_name" "$scenario_name" "running" "$passed" "$failed"

        # validate scenario
        local scenario_errors=$(tc_validate_scenario "$scenario_dir")
        if [ $? -ne 0 ]; then
            [ "$TC_STATUS_MODE" != "tty" ] && tc_progress_fail
            tc_error "scenario validation failed: $scenario_errors"
            ((errors++))
            results+=("$scenario_name|error|0|validation failed")
            # Update status line after failure
            tc_status_update "$suite_name" "$scenario_name" "failed" "$passed" "$((failed + errors))"
            # Write to log (T054, T055)
            tc_log_write "$suite_dir" "$scenario_name" "error" "0" "validation failed"

            # Fail-fast in TTY mode: stop immediately on first failure
            if [ "$TC_STATUS_MODE" = "tty" ]; then
                break
            fi
            continue
        fi

        # run scenario
        local runner_result=$(tc_run_scenario "$suite_dir" "$scenario_dir" "$timeout")
        if [ $? -ne 0 ]; then
            [ "$TC_STATUS_MODE" != "tty" ] && tc_progress_fail
            ((errors++))
            results+=("$scenario_name|error|0|runner failed")
            # Update status line after failure
            tc_status_update "$suite_name" "$scenario_name" "failed" "$passed" "$((failed + errors))"
            # Write to log (T054, T055)
            tc_log_write "$suite_dir" "$scenario_name" "error" "0" "runner failed"

            # Fail-fast in TTY mode: stop immediately on first failure
            if [ "$TC_STATUS_MODE" = "tty" ]; then
                break
            fi
            continue
        fi

        # parse runner output
        IFS='|' read -r output_file stderr_file exit_code duration <<< "$runner_result"

        # check exit code
        if [ "$exit_code" -eq 124 ]; then
            [ "$TC_STATUS_MODE" != "tty" ] && tc_progress_fail
            tc_error "timeout after ${timeout}s"
            ((errors++))
            results+=("$scenario_name|timeout|$duration|exceeded timeout")
            tc_cleanup_runner_output "$output_file" "$stderr_file"
            # Update status line after failure
            tc_status_update "$suite_name" "$scenario_name" "failed" "$passed" "$((failed + errors))"
            # Write to log (T054, T055)
            tc_log_write "$suite_dir" "$scenario_name" "error" "$duration" "timeout after ${timeout}s"

            # Fail-fast in TTY mode: stop immediately on first failure
            if [ "$TC_STATUS_MODE" = "tty" ]; then
                break
            fi
            continue
        elif [ "$exit_code" -ne 0 ]; then
            [ "$TC_STATUS_MODE" != "tty" ] && tc_progress_fail
            tc_error "runner exited with code $exit_code"
            ((errors++))
            results+=("$scenario_name|error|$duration|exit code $exit_code")
            tc_cleanup_runner_output "$output_file" "$stderr_file"
            # Update status line after failure
            tc_status_update "$suite_name" "$scenario_name" "failed" "$passed" "$((failed + errors))"
            # Write to log (T054, T055)
            tc_log_write "$suite_dir" "$scenario_name" "error" "$duration" "exit code $exit_code"

            # Fail-fast in TTY mode: stop immediately on first failure
            if [ "$TC_STATUS_MODE" = "tty" ]; then
                break
            fi
            continue
        fi

        # extract actual output
        local actual_output=$(tc_extract_actual_output "$output_file")

        # compare output
        tc_compare_output "$actual_output" "$scenario_dir/expected.json" "$mode"
        local comparison_result=$?

        if [ "$comparison_result" -eq 0 ]; then
            [ "$TC_STATUS_MODE" != "tty" ] && tc_progress_done
            ((passed++))
            results+=("$scenario_name|pass|$duration|")
            # Update status line after pass (T019)
            tc_status_update "$suite_name" "$scenario_name" "passed" "$passed" "$failed"
            # Write to log (T054)
            tc_log_write "$suite_dir" "$scenario_name" "pass" "$duration"
        else
            [ "$TC_STATUS_MODE" != "tty" ] && tc_progress_fail
            ((failed++))
            local diff=$(tc_generate_diff "$actual_output" "$scenario_dir/expected.json" | head -20)
            results+=("$scenario_name|fail|$duration|$diff")
            # Update status line after failure (T019)
            tc_status_update "$suite_name" "$scenario_name" "failed" "$passed" "$failed"
            # Write to log with error (T054, T055)
            tc_log_write "$suite_dir" "$scenario_name" "fail" "$duration" "$diff"

            # Fail-fast in TTY mode: stop immediately on first failure
            if [ "$TC_STATUS_MODE" = "tty" ]; then
                # cleanup before breaking
                rm -f "$actual_output"
                tc_cleanup_runner_output "$output_file" "$stderr_file"
                break
            fi
        fi

        # cleanup
        rm -f "$actual_output"
        tc_cleanup_runner_output "$output_file" "$stderr_file"

    done <<< "$scenarios"

    # Don't finalize status line here - let the caller handle it
    # This allows single-line updates to continue across multiple suites

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
