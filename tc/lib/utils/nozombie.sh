#!/usr/bin/env bash
# tc/lib/utils/nozombie.sh - perfect zombie killer
# inspired by https://github.com/ahoward/assassin
#
# ensures no child processes outlive the master test runner
# uses sidecar process + FIFOs for bulletproof cleanup

# global state
TC_NOZOMBIE_ENABLED="${TC_NOZOMBIE_ENABLED:-1}"
TC_NOZOMBIE_FIFO_DIR="${TC_NOZOMBIE_FIFO_DIR:-}"
TC_NOZOMBIE_SIDECAR_PID=""
TC_NOZOMBIE_MASTER_PID="$$"
TC_NOZOMBIE_CHILDREN=()

# tc_nozombie_init(master_pid)
#
# Initialize nozombie system for master test runner.
# Starts sidecar process that monitors master and kills children on exit.
#
# Args:
#   $1: Master PID to monitor (usually $$)
#
# Returns:
#   Exit code 0 on success
#   Sets TC_NOZOMBIE_FIFO_DIR and TC_NOZOMBIE_SIDECAR_PID
tc_nozombie_init() {
    local master_pid="${1:-$$}"

    # Skip if disabled
    if [ "$TC_NOZOMBIE_ENABLED" != "1" ]; then
        return 0
    fi

    # Create FIFO directory
    TC_NOZOMBIE_FIFO_DIR="${TC_TMPDIR:-/tmp}/tc-nozombie-$$"
    mkdir -p "$TC_NOZOMBIE_FIFO_DIR"

    # Create control FIFOs
    local command_fifo="$TC_NOZOMBIE_FIFO_DIR/commands"
    local status_fifo="$TC_NOZOMBIE_FIFO_DIR/status"

    mkfifo "$command_fifo"
    mkfifo "$status_fifo"

    # Start sidecar process in background
    tc_nozombie_sidecar "$master_pid" "$command_fifo" "$status_fifo" &
    TC_NOZOMBIE_SIDECAR_PID=$!

    # Wait for sidecar ready signal
    read -t 5 ready < "$status_fifo" || {
        echo "ERROR: nozombie sidecar failed to start" >&2
        return 1
    }

    # Register cleanup on master exit
    trap "tc_nozombie_shutdown" EXIT INT TERM

    return 0
}

# tc_nozombie_sidecar(master_pid, command_fifo, status_fifo)
#
# Sidecar process that monitors master and manages child lifecycle.
# Runs in background, continuously pings master with kill -0.
# Kills all tracked children when master dies.
#
# Args:
#   $1: Master PID to monitor
#   $2: Command FIFO path
#   $3: Status FIFO path
tc_nozombie_sidecar() {
    local master_pid="$1"
    local command_fifo="$2"
    local status_fifo="$3"

    # Track children PIDs
    declare -A children

    # Signal ready
    echo "ready" > "$status_fifo"

    # Main monitoring loop
    while true; do
        # Check if master is still alive
        if ! kill -0 "$master_pid" 2>/dev/null; then
            # Master died - kill all children
            tc_nozombie_sidecar_cleanup children
            exit 0
        fi

        # Check for commands (non-blocking with timeout)
        if read -t 1 cmd < "$command_fifo"; then
            case "$cmd" in
                add:*)
                    # Add child PID to tracking
                    local child_pid="${cmd#add:}"
                    children["$child_pid"]=1
                    ;;
                remove:*)
                    # Remove child PID from tracking
                    local child_pid="${cmd#remove:}"
                    unset children["$child_pid"]
                    ;;
                shutdown)
                    # Clean shutdown
                    tc_nozombie_sidecar_cleanup children
                    exit 0
                    ;;
            esac
        fi

        # Reap any dead children (prevent zombies)
        for pid in "${!children[@]}"; do
            if ! kill -0 "$pid" 2>/dev/null; then
                unset children["$pid"]
            fi
        done

        # Sleep briefly to avoid busy loop
        sleep 0.1
    done
}

# tc_nozombie_sidecar_cleanup(children_array_name)
#
# Kill all tracked children with escalating signals.
# TERM → (wait 2s) → KILL
tc_nozombie_sidecar_cleanup() {
    local -n children_ref=$1

    # Send TERM to all children
    for pid in "${!children_ref[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # Wait briefly for graceful shutdown
    sleep 2

    # Send KILL to any survivors
    for pid in "${!children_ref[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    # Final cleanup
    sleep 0.5
}

# tc_nozombie_register(child_pid)
#
# Register a child process for tracking.
# Sends add command to sidecar via FIFO.
#
# Args:
#   $1: Child PID to track
tc_nozombie_register() {
    local child_pid="$1"

    # Skip if disabled
    if [ "$TC_NOZOMBIE_ENABLED" != "1" ]; then
        return 0
    fi

    # Check sidecar is running
    if [ -z "$TC_NOZOMBIE_SIDECAR_PID" ]; then
        return 0
    fi

    # Send command to sidecar
    local command_fifo="$TC_NOZOMBIE_FIFO_DIR/commands"
    if [ -p "$command_fifo" ]; then
        echo "add:$child_pid" > "$command_fifo"
    fi

    # Track locally for redundancy
    TC_NOZOMBIE_CHILDREN+=("$child_pid")

    return 0
}

# tc_nozombie_unregister(child_pid)
#
# Unregister a child process (normal completion).
# Sends remove command to sidecar via FIFO.
#
# Args:
#   $1: Child PID to untrack
tc_nozombie_unregister() {
    local child_pid="$1"

    # Skip if disabled
    if [ "$TC_NOZOMBIE_ENABLED" != "1" ]; then
        return 0
    fi

    # Check sidecar is running
    if [ -z "$TC_NOZOMBIE_SIDECAR_PID" ]; then
        return 0
    fi

    # Send command to sidecar
    local command_fifo="$TC_NOZOMBIE_FIFO_DIR/commands"
    if [ -p "$command_fifo" ]; then
        echo "remove:$child_pid" > "$command_fifo"
    fi

    # Remove from local tracking
    local new_children=()
    for pid in "${TC_NOZOMBIE_CHILDREN[@]}"; do
        if [ "$pid" != "$child_pid" ]; then
            new_children+=("$pid")
        fi
    done
    TC_NOZOMBIE_CHILDREN=("${new_children[@]}")

    return 0
}

# tc_nozombie_run(command, args...)
#
# Run command with automatic child tracking.
# Registers PID with nozombie, runs command, then unregisters on completion.
#
# Args:
#   $@: Command and arguments to execute
#
# Returns:
#   Exit code of command
#
# Example:
#   tc_nozombie_run ./my-test < input.json
tc_nozombie_run() {
    # Run command in background to get PID
    "$@" &
    local child_pid=$!

    # Register with nozombie
    tc_nozombie_register "$child_pid"

    # Wait for completion
    local exit_code=0
    wait "$child_pid" || exit_code=$?

    # Unregister (normal completion)
    tc_nozombie_unregister "$child_pid"

    return $exit_code
}

# tc_nozombie_run_with_timeout(timeout, command, args...)
#
# Run command with timeout and automatic child tracking.
# Combines nozombie tracking with timeout enforcement.
#
# Args:
#   $1: Timeout in seconds
#   $@: Command and arguments to execute
#
# Returns:
#   Exit code 124 on timeout
#   Exit code of command otherwise
tc_nozombie_run_with_timeout() {
    local timeout="$1"
    shift

    # Run command in background
    "$@" &
    local child_pid=$!

    # Register with nozombie
    tc_nozombie_register "$child_pid"

    # Wait for completion with timeout
    local elapsed=0
    local exit_code=0

    while kill -0 "$child_pid" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout" ]; then
            # Timeout - kill process
            kill -TERM "$child_pid" 2>/dev/null || true
            sleep 1
            kill -KILL "$child_pid" 2>/dev/null || true
            tc_nozombie_unregister "$child_pid"
            return 124  # timeout exit code (matches GNU timeout)
        fi
        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    # Get exit code
    wait "$child_pid" || exit_code=$?

    # Unregister (normal completion)
    tc_nozombie_unregister "$child_pid"

    return $exit_code
}

# tc_nozombie_shutdown()
#
# Shutdown nozombie system cleanly.
# Sends shutdown command to sidecar, waits for it to exit.
# Cleans up FIFOs and temp directory.
tc_nozombie_shutdown() {
    # Skip if disabled or not initialized
    if [ "$TC_NOZOMBIE_ENABLED" != "1" ] || [ -z "$TC_NOZOMBIE_SIDECAR_PID" ]; then
        return 0
    fi

    # Send shutdown command to sidecar
    local command_fifo="$TC_NOZOMBIE_FIFO_DIR/commands"
    if [ -p "$command_fifo" ]; then
        echo "shutdown" > "$command_fifo" 2>/dev/null || true
    fi

    # Wait for sidecar to exit (with timeout)
    local timeout=5
    while kill -0 "$TC_NOZOMBIE_SIDECAR_PID" 2>/dev/null && [ $timeout -gt 0 ]; do
        sleep 0.5
        timeout=$((timeout - 1))
    done

    # Force kill sidecar if still running
    if kill -0 "$TC_NOZOMBIE_SIDECAR_PID" 2>/dev/null; then
        kill -KILL "$TC_NOZOMBIE_SIDECAR_PID" 2>/dev/null || true
    fi

    # Cleanup FIFOs and temp directory
    if [ -d "$TC_NOZOMBIE_FIFO_DIR" ]; then
        rm -rf "$TC_NOZOMBIE_FIFO_DIR"
    fi

    return 0
}

# tc_nozombie_status()
#
# Print status of nozombie system (debugging).
tc_nozombie_status() {
    echo "nozombie status:"
    echo "  enabled: $TC_NOZOMBIE_ENABLED"
    echo "  master_pid: $TC_NOZOMBIE_MASTER_PID"
    echo "  sidecar_pid: $TC_NOZOMBIE_SIDECAR_PID"
    echo "  fifo_dir: $TC_NOZOMBIE_FIFO_DIR"
    echo "  tracked_children: ${#TC_NOZOMBIE_CHILDREN[@]}"

    if [ ${#TC_NOZOMBIE_CHILDREN[@]} -gt 0 ]; then
        echo "  children:"
        for pid in "${TC_NOZOMBIE_CHILDREN[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                echo "    - $pid (alive)"
            else
                echo "    - $pid (dead)"
            fi
        done
    fi
}
