#!/usr/bin/env bash
# tc/lib/core/hooks.sh - Lifecycle hooks management
#
# Provides hook discovery, validation, and execution for test suites.
# Enables setup/teardown/before_each/after_each patterns for integration testing.
#
# Part of: lifecycle hooks feature (007)
# Dependencies: log.sh, json.sh, timer.sh

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/timer.sh"

# ============================================================================
# Hook Discovery (T005, T006)
# ============================================================================

# tc_has_hook(suite_dir, hook_name)
#
# Check if hook file exists and is executable
#
# Args:
#   $1: Suite directory (absolute path)
#   $2: Hook name (setup, teardown, before_each, after_each)
#
# Returns:
#   0 if hook exists and is executable
#   1 otherwise
tc_has_hook() {
    local suite_dir="$1"
    local hook_name="$2"
    local hook_file="$suite_dir/${hook_name}.sh"

    [ -f "$hook_file" ] && [ -x "$hook_file" ]
}

# tc_has_global_hook(test_root, hook_name)
#
# Check if global hook exists in tests/.tc/hooks/
#
# Args:
#   $1: Test root directory
#   $2: Hook name (global_setup, global_teardown)
#
# Returns:
#   0 if global hook exists and is executable
#   1 otherwise
tc_has_global_hook() {
    local test_root="$1"
    local hook_name="$2"
    local hook_file="$test_root/.tc/hooks/${hook_name}.sh"

    [ -f "$hook_file" ] && [ -x "$hook_file" ]
}

# ============================================================================
# Hook Validation (T007)
# ============================================================================

# tc_validate_hook(hook_file)
#
# Validate hook file meets requirements
#
# Args:
#   $1: Hook file path
#
# Returns:
#   0 if valid
#   1 if invalid (logs error)
tc_validate_hook() {
    local hook_file="$1"

    # Must be regular file
    if [ ! -f "$hook_file" ]; then
        tc_error "Hook is not a regular file: $hook_file"
        return 1
    fi

    # Must be executable
    if [ ! -x "$hook_file" ]; then
        tc_error "Hook is not executable: $hook_file (run: chmod +x $hook_file)"
        return 1
    fi

    # Must not be symlink (security)
    if [ -L "$hook_file" ]; then
        tc_error "Hook cannot be a symlink: $hook_file"
        return 1
    fi

    # Must have .sh extension
    if [[ "$hook_file" != *.sh ]]; then
        tc_error "Hook must have .sh extension: $hook_file"
        return 1
    fi

    return 0
}

# ============================================================================
# Environment Variable Management (T009, T010)
# ============================================================================

# tc_set_hook_env(suite_dir, hook_type, [scenario], [data_dir])
#
# Set standard environment variables for hooks
#
# Args:
#   $1: Suite directory (absolute path)
#   $2: Hook type (setup|teardown|before_each|after_each|global_setup|global_teardown)
#   $3: Scenario name (optional, for before_each/after_each)
#   $4: Data directory (optional, for before_each/after_each)
tc_set_hook_env() {
    local suite_dir="$1"
    local hook_type="$2"
    local scenario="${3:-}"
    local data_dir="${4:-}"

    # Standard variables for all hooks
    export TC_SUITE_PATH="$suite_dir"
    export TC_HOOK_TYPE="$hook_type"
    export TC_ROOT="${TC_ROOT}"

    # Additional variables for before_each/after_each
    if [[ "$hook_type" == "before_each" ]] || [[ "$hook_type" == "after_each" ]]; then
        export TC_SCENARIO="$scenario"
        export TC_DATA_DIR="$data_dir"
    fi

    # Mark global hooks
    if [[ "$hook_type" == global_* ]]; then
        export TC_GLOBAL_HOOK="true"
    fi
}

# tc_load_hook_env(suite_dir)
#
# Source .tc-env file if it exists
#
# Args:
#   $1: Suite directory
#
# Returns:
#   0 always (missing .tc-env is OK)
tc_load_hook_env() {
    local suite_dir="$1"
    local env_file="$suite_dir/.tc-env"

    if [ -f "$env_file" ]; then
        tc_debug "Loading hook environment from: $env_file"
        # Source in subshell first to validate syntax
        if bash -n "$env_file" 2>/dev/null; then
            source "$env_file"
        else
            tc_error "Invalid syntax in .tc-env file: $env_file"
            return 1
        fi
    fi

    return 0
}

# ============================================================================
# Hook Execution (T008)
# ============================================================================

# tc_run_hook(suite_dir, hook_name, [scenario], [data_dir])
#
# Execute hook with timeout, error capture, and environment setup
#
# Args:
#   $1: Suite directory
#   $2: Hook name (setup, teardown, before_each, after_each)
#   $3: Scenario name (optional, for before_each/after_each)
#   $4: Data directory (optional, for before_each/after_each)
#
# Returns:
#   Hook exit code
tc_run_hook() {
    local suite_dir="$1"
    local hook_name="$2"
    local scenario="${3:-}"
    local data_dir="${4:-}"
    local hook_file="$suite_dir/${hook_name}.sh"

    # Check if hook exists
    if ! tc_has_hook "$suite_dir" "$hook_name"; then
        tc_debug "Hook not found (skipping): $hook_name"
        return 0  # Missing hooks are OK
    fi

    # Validate hook
    if ! tc_validate_hook "$hook_file"; then
        return 1
    fi

    # Load .tc-env if exists
    tc_load_hook_env "$suite_dir"

    # Set standard environment variables
    tc_set_hook_env "$suite_dir" "$hook_name" "$scenario" "$data_dir"

    # Execute hook with timeout and error capture
    local start_time=$(tc_timer_start)
    local stderr_file=$(mktemp)
    local timeout="${TC_HOOK_TIMEOUT:-30}"

    tc_debug "Running hook: $hook_name (timeout: ${timeout}s)"

    set +e  # Don't exit on hook failure
    (
        cd "$suite_dir" || exit 1
        timeout "$timeout" "./${hook_name}.sh" 2>"$stderr_file"
    )
    local exit_code=$?
    set -e

    local duration=$(tc_timer_stop "$start_time")

    # Log hook execution
    tc_log_hook "$hook_name" "$suite_dir" "$exit_code" "$duration" "$stderr_file" "$scenario"

    # Cleanup stderr file
    rm -f "$stderr_file"

    return $exit_code
}

# ============================================================================
# Hook Logging (T011)
# ============================================================================

# tc_log_hook(hook_type, suite_dir, exit_code, duration_ms, stderr_file, [scenario])
#
# Log hook execution to tc logging system
#
# Args:
#   $1: Hook type
#   $2: Suite directory
#   $3: Exit code
#   $4: Duration in milliseconds
#   $5: Stderr file path
#   $6: Scenario name (optional)
tc_log_hook() {
    local hook_type="$1"
    local suite_dir="$2"
    local exit_code="$3"
    local duration_ms="$4"
    local stderr_file="$5"
    local scenario="${6:-}"

    # Read stderr content if hook failed
    local stderr_content=""
    if [ "$exit_code" -ne 0 ] && [ -f "$stderr_file" ]; then
        stderr_content=$(cat "$stderr_file" 2>/dev/null | head -c 10240)  # Max 10KB
    fi

    if [ "$exit_code" -eq 0 ]; then
        tc_debug "${hook_type}.sh passed (${duration_ms}ms)"
    else
        tc_error "${hook_type}.sh failed with exit code $exit_code (${duration_ms}ms)"
        if [ -n "$stderr_content" ]; then
            echo "$stderr_content" >&2
        fi
    fi

    # Log to JSONL if log writer available
    if type -t tc_log_write >/dev/null 2>&1; then
        tc_log_write "$suite_dir" "${scenario:-$hook_type}" "hook_$exit_code" "$duration_ms" "$stderr_content"
    fi
}

# ============================================================================
# Hook Failure Handling (T012)
# ============================================================================

# tc_handle_hook_failure(hook_type, exit_code, stderr_file)
#
# Handle hook failures according to spec
#
# Args:
#   $1: Hook type
#   $2: Exit code
#   $3: Stderr file path
#
# Returns:
#   0 to continue, 1 to abort
tc_handle_hook_failure() {
    local hook_type="$1"
    local exit_code="$2"
    local stderr_file="$3"

    # Success - continue
    if [ "$exit_code" -eq 0 ]; then
        return 0
    fi

    # Read stderr for error message
    local stderr_content=""
    if [ -f "$stderr_file" ]; then
        stderr_content=$(cat "$stderr_file" 2>/dev/null)
    fi

    # Handle failure based on hook type
    case "$hook_type" in
        setup|global_setup)
            tc_error "$hook_type.sh failed - aborting suite"
            return 1  # Abort
            ;;
        before_each)
            tc_error "$hook_type.sh failed - skipping scenario"
            return 1  # Skip scenario
            ;;
        teardown|global_teardown|after_each)
            tc_error "$hook_type.sh failed (exit code $exit_code)"
            return 0  # Log but continue (cleanup failures shouldn't block)
            ;;
        *)
            tc_error "Unknown hook type: $hook_type"
            return 1
            ;;
    esac
}

# ============================================================================
# Hook Mode Detection (T013)
# ============================================================================

# tc_is_stateful_suite(suite_dir)
#
# Detect if suite should run in stateful mode
#
# Args:
#   $1: Suite directory
#
# Returns:
#   0 if stateful mode (has setup.sh)
#   1 if stateless mode
tc_is_stateful_suite() {
    local suite_dir="$1"
    tc_has_hook "$suite_dir" "setup"
}

# ============================================================================
# Hook Execution State Machine (T014)
# ============================================================================

# tc_execute_suite_with_hooks(suite_dir, mode, passed, failed, errors, results)
#
# Execute test suite with lifecycle hooks
# Orchestrates: setup → (before_each → scenario → after_each)* → teardown
#
# Args:
#   $1: Suite directory (absolute path)
#   $2: Comparison mode
#   $3: Variable name for passed count (will be updated)
#   $4: Variable name for failed count (will be updated)
#   $5: Variable name for error count (will be updated)
#   $6: Variable name for results array (will be updated)
#
# Returns:
#   0 if all tests passed
#   1 if any failures/errors
#
# Note: This is the skeleton/orchestration function. Detailed implementation
#       of hook integration points will be completed in US1 (T017-T040).
tc_execute_suite_with_hooks() {
    local suite_dir="$1"
    local mode="$2"
    local -n _passed=$3
    local -n _failed=$4
    local -n _errors=$5
    local -n _results=$6

    tc_debug "Executing suite with lifecycle hooks: $suite_dir"

    # T016: Setup trap for guaranteed teardown
    # Use a marker file to track if teardown has been executed
    local teardown_marker="$suite_dir/.tc-teardown-done"
    rm -f "$teardown_marker"  # Clean slate
    trap 'tc_execute_teardown_trap "$suite_dir" "$teardown_marker"' EXIT INT TERM

    # Run setup hook if present
    if tc_has_hook "$suite_dir" "setup"; then
        tc_debug "Running setup hook"
        if ! tc_run_hook "$suite_dir" "setup"; then
            # Setup failure aborts entire suite (T012)
            tc_error "setup.sh failed - aborting suite"
            _errors=$((_errors + 1))
            _results+=("setup|error|0|setup hook failed")
            return 1
        fi
    fi

    # Find all scenarios (same as stateless mode)
    local scenarios=$(tc_find_scenarios "$suite_dir")

    # Execute each scenario with before_each/after_each hooks
    while read -r scenario_dir; do
        local scenario_name=$(tc_scenario_name "$scenario_dir")
        local data_dir="$scenario_dir"
        local scenario_failed=0

        # Get suite timeout for scenario execution
        local timeout=$(tc_get_suite_timeout "$suite_dir")

        # Run before_each hook if present (T018)
        if tc_has_hook "$suite_dir" "before_each"; then
            tc_debug "Running before_each hook for: $scenario_name"
            if ! tc_run_hook "$suite_dir" "before_each" "$scenario_name" "$data_dir"; then
                # before_each failure skips scenario (T012, T019)
                tc_error "before_each.sh failed - skipping scenario: $scenario_name"
                _errors=$((_errors + 1))
                _results+=("$scenario_name|error|0|before_each hook failed")
                scenario_failed=1
            fi
        fi

        # Execute scenario (only if before_each succeeded) (T021)
        if [ "$scenario_failed" -eq 0 ]; then
            # Validate scenario
            local scenario_errors=$(tc_validate_scenario "$scenario_dir")
            if [ $? -ne 0 ]; then
                tc_error "scenario validation failed: $scenario_errors"
                _errors=$((_errors + 1))
                _results+=("$scenario_name|error|0|validation failed")
                scenario_failed=1
            else
                # Run scenario
                local runner_result=$(tc_run_scenario "$suite_dir" "$scenario_dir" "$timeout")
                if [ $? -ne 0 ]; then
                    _errors=$((_errors + 1))
                    _results+=("$scenario_name|error|0|runner failed")
                    scenario_failed=1
                else
                    # Parse runner output
                    IFS='|' read -r output_file stderr_file exit_code duration <<< "$runner_result"

                    # Check exit code
                    if [ "$exit_code" -eq 124 ]; then
                        tc_error "timeout after ${timeout}s"
                        _errors=$((_errors + 1))
                        _results+=("$scenario_name|timeout|$duration|exceeded timeout")
                        tc_cleanup_runner_output "$output_file" "$stderr_file"
                        scenario_failed=1
                    elif [ "$exit_code" -ne 0 ]; then
                        tc_error "runner exited with code $exit_code"
                        _errors=$((_errors + 1))
                        _results+=("$scenario_name|error|$duration|exit code $exit_code")
                        tc_cleanup_runner_output "$output_file" "$stderr_file"
                        scenario_failed=1
                    else
                        # Extract and compare output
                        local actual_output=$(tc_extract_actual_output "$output_file")
                        tc_compare_output "$actual_output" "$scenario_dir/expected.json" "$mode"
                        local comparison_result=$?

                        if [ "$comparison_result" -eq 0 ]; then
                            _passed=$((_passed + 1))
                            _results+=("$scenario_name|pass|$duration|")
                        else
                            _failed=$((_failed + 1))
                            local diff=$(tc_generate_diff "$actual_output" "$scenario_dir/expected.json" | head -20)
                            _results+=("$scenario_name|fail|$duration|$diff")
                            scenario_failed=1
                        fi

                        # Cleanup
                        rm -f "$actual_output"
                        tc_cleanup_runner_output "$output_file" "$stderr_file"
                    fi
                fi
            fi
        fi

        # Run after_each hook if present (always runs, even if scenario failed) (T018, T019)
        if tc_has_hook "$suite_dir" "after_each"; then
            tc_debug "Running after_each hook for: $scenario_name"
            if ! tc_run_hook "$suite_dir" "after_each" "$scenario_name" "$data_dir"; then
                # after_each failure is logged but doesn't fail scenario (T012)
                tc_warn "after_each.sh failed for scenario: $scenario_name (continuing)"
            fi
        fi

    done <<< "$scenarios"

    # Run teardown hook if present (always runs)
    if tc_has_hook "$suite_dir" "teardown"; then
        tc_debug "Running teardown hook"
        if ! tc_run_hook "$suite_dir" "teardown"; then
            # teardown failure is logged but doesn't fail suite (T012)
            tc_warn "teardown.sh failed (continuing)"
        fi
    fi

    # Mark teardown as executed so trap doesn't run it again
    touch "$teardown_marker"

    # Clear trap since we've successfully run teardown
    trap - EXIT INT TERM

    # Return success/failure based on scenario results
    if [ "$_failed" -gt 0 ] || [ "$_errors" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# ============================================================================
# Guaranteed Teardown (T016)
# ============================================================================

# tc_execute_teardown_trap(suite_dir, teardown_marker)
#
# Trap handler to ensure teardown runs even on early exit
#
# Args:
#   $1: Suite directory
#   $2: Path to teardown marker file
tc_execute_teardown_trap() {
    local suite_dir="$1"
    local teardown_marker="$2"

    # Only run teardown if it hasn't already been executed
    if [ ! -f "$teardown_marker" ]; then
        if tc_has_hook "$suite_dir" "teardown"; then
            tc_debug "Running teardown via trap (emergency cleanup)"
            tc_run_hook "$suite_dir" "teardown" || true  # Never fail in trap
        fi
        # Mark as done even if it failed (don't retry)
        touch "$teardown_marker" 2>/dev/null || true
    fi
}

