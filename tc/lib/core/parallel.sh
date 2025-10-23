#!/usr/bin/env bash
# tc parallel execution coordinator
# flying multiple choppers at once 🚁🚁🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/platform.sh"

# run test suites in parallel with job control
# returns: aggregated results from all suites
tc_run_suites_parallel() {
    local root_path="$1"
    local max_jobs="${2:-auto}"
    local filter_tags="${3:-}"

    # auto-detect CPU cores if needed
    if [ "$max_jobs" = "auto" ]; then
        max_jobs=$(tc_detect_cpu_cores)
        tc_debug "auto-detected $max_jobs CPU cores for parallel execution"
    fi

    # ensure max_jobs is valid
    if ! [[ "$max_jobs" =~ ^[0-9]+$ ]] || [ "$max_jobs" -lt 1 ]; then
        tc_warn "invalid parallel jobs: $max_jobs, defaulting to 4"
        max_jobs=4
    fi

    tc_info "parallel execution with $max_jobs workers"

    # discover all suites
    local all_suites=$(tc_discover_suites_recursive "$root_path")

    # filter by tags if specified
    local suites="$all_suites"
    if [ -n "$filter_tags" ]; then
        tc_info "filtering by tags: $filter_tags"
        suites=""
        while read -r suite_dir; do
            [ -z "$suite_dir" ] && continue
            if tc_suite_has_tag "$suite_dir" "$filter_tags"; then
                suites="$suites$suite_dir"$'\n'
            fi
        done <<< "$all_suites"
    fi

    local suite_count=$(echo "$suites" | grep -c . || echo 0)

    if [ -z "$suites" ] || [ "$suite_count" -eq 0 ]; then
        tc_error "no test suites found in: $root_path"
        return 1
    fi

    tc_info "found $suite_count suite(s)"
    echo ""

    # create temp directory for results
    local results_dir=$(mktemp -d)
    trap "rm -rf '$results_dir'" EXIT

    # aggregate results
    local total_passed=0
    local total_failed=0
    local total_errors=0
    local overall_exit=0
    local suite_index=0

    # run each suite with job control
    while read -r suite_dir; do
        [ -z "$suite_dir" ] && continue

        # wait if we've hit max parallel jobs
        while [ "$(jobs -r | wc -l)" -ge "$max_jobs" ]; do
            sleep 0.1
        done

        local suite_name=$(tc_suite_relative_path "$suite_dir" "$root_path")
        local result_file="$results_dir/$suite_index.result"

        # run suite in background, capture result to file
        (
            tc_info "running: $suite_name"

            # execute suite
            local result=$(tc_execute_suite "$suite_dir")
            local exit_code=$?

            # parse results
            local metadata="${result%%:::*}"
            local rest="${result#*:::}"
            IFS='|' read -r passed failed errors <<< "$metadata"

            # write results to temp file
            echo "$passed|$failed|$errors|$exit_code|$suite_name" > "$result_file"
            echo "$rest" >> "$result_file"

            # report suite results
            local results=()
            while IFS= read -r line; do
                [ -n "$line" ] && results+=("$line")
            done <<< "$rest"

            tc_report_suite "$suite_dir" "$passed" "$failed" "$errors" "${results[@]}"

            # write results to .tc-result file
            tc_write_results "$suite_dir" "${results[@]}"

            echo ""

        ) &

        suite_index=$((suite_index + 1))

    done <<< "$suites"

    # wait for all background jobs to complete
    tc_info "waiting for $suite_count suite(s) to complete..."
    wait

    # aggregate results from all temp files
    for result_file in "$results_dir"/*.result; do
        [ -f "$result_file" ] || continue

        # read first line with metadata
        local first_line=$(head -1 "$result_file")
        IFS='|' read -r passed failed errors exit_code suite_name <<< "$first_line"

        total_passed=$((total_passed + passed))
        total_failed=$((total_failed + failed))
        total_errors=$((total_errors + errors))

        if [ "$exit_code" -ne 0 ]; then
            overall_exit=1
        fi
    done

    # print overall summary
    echo "===================================="
    echo "overall results (parallel)"
    echo "===================================="
    echo ""
    echo "suites run: $suite_count"
    echo "workers: $max_jobs"
    tc_report_summary "$total_passed" "$total_failed" "$total_errors"
    echo ""

    return $overall_exit
}

# check if parallel execution should be used
# based on suite count and system capabilities
tc_should_use_parallel() {
    local suite_count="$1"
    local min_suites_for_parallel=2

    # need at least 2 suites to benefit from parallelism
    if [ "$suite_count" -lt "$min_suites_for_parallel" ]; then
        return 1
    fi

    # check if we have multiple cores
    local cores=$(tc_detect_cpu_cores)
    if [ "$cores" -lt 2 ]; then
        return 1
    fi

    return 0
}
