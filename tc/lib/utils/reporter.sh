#!/usr/bin/env bash
# tc result reporter
# bringing the news back to base 🚁

source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# format single suite results
tc_report_suite() {
    local suite_path="$1"
    local passed="$2"
    local failed="$3"
    local errors="$4"
    shift 4
    local results=("$@")

    # T021: In TTY mode, skip all output (status line already showed everything)
    if [ "$TC_STATUS_MODE" = "tty" ]; then
        return 0
    fi

    local suite_name=$(basename "$suite_path")
    local total=$((passed + failed + errors))

    # Non-TTY mode: show detailed results
    if true; then
        echo ""
        echo "tc test results"
        echo "================"
        echo "suite: $suite_name"
        echo ""

        # show individual scenario results
        for result_line in "${results[@]}"; do
            IFS='|' read -r scenario status duration diff <<< "$result_line"

            case "$status" in
                pass)
                    echo "  ${TC_COLOR_PASS}✓${TC_COLOR_RESET} $scenario (${duration}ms)"
                    ;;
                fail)
                    echo "  ${TC_COLOR_FAIL}✗${TC_COLOR_RESET} $scenario (${duration}ms)"
                    if [ -n "$diff" ]; then
                        echo "    diff:"
                        echo "$diff" | sed 's/^/      /'
                    fi
                    ;;
                error|timeout)
                    echo "  ${TC_COLOR_FAIL}✗${TC_COLOR_RESET} $scenario [$status]"
                    if [ -n "$diff" ]; then
                        echo "    $diff"
                    fi
                    ;;
            esac
        done
    fi

    # Always show summary (status line finish already printed it)
    if [ "$skip_details" = false ]; then
        echo ""
        echo "summary: ${TC_COLOR_PASS}$passed passed${TC_COLOR_RESET}, ${TC_COLOR_FAIL}$failed failed${TC_COLOR_RESET}, ${TC_COLOR_WARN}$errors errors${TC_COLOR_RESET} ($total total)"
        echo ""
    fi
}

# format minimal summary
tc_report_summary() {
    local passed="$1"
    local failed="$2"
    local errors="$3"
    local total=$((passed + failed + errors))

    if [ "$failed" -eq 0 ] && [ "$errors" -eq 0 ]; then
        echo -e "${TC_COLOR_PASS}✓${TC_COLOR_RESET} all $total tests passed"
    else
        echo -e "${TC_COLOR_FAIL}✗${TC_COLOR_RESET} $passed passed, $failed failed, $errors errors ($total total)"
    fi
}

# write results to .tc-result file (jsonl format)
tc_write_results() {
    local suite_dir="$1"
    local result_file="$suite_dir/$TC_RESULT_FILE"
    shift
    local results=("$@")

    # overwrite result file
    > "$result_file"

    for result_line in "${results[@]}"; do
        IFS='|' read -r scenario status duration diff <<< "$result_line"

        # create json line
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        # Ensure duration is a valid number (default to 0 if empty/invalid)
        if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
            duration=0
        fi

        local json=$(jq -n \
            --arg suite "$(basename "$suite_dir")" \
            --arg scenario "$scenario" \
            --arg status "$status" \
            --argjson duration "$duration" \
            --arg timestamp "$timestamp" \
            --arg comparison "$TC_DEFAULT_COMPARISON" \
            '{suite: $suite, scenario: $scenario, status: $status, duration_ms: $duration, timestamp: $timestamp, comparison_mode: $comparison}')

        echo "$json" >> "$result_file"
    done

    tc_debug "wrote results to: $result_file"
}

# show test result emoji
tc_result_icon() {
    local status="$1"

    case "$status" in
        pass)
            echo "✓"
            ;;
        fail|error|timeout)
            echo "✗"
            ;;
        *)
            echo "?"
            ;;
    esac
}
