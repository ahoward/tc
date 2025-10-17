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

