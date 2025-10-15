# nozombie.sh - Perfect Zombie Killer

**Inspired by**: [assassin](https://github.com/ahoward/assassin)
**Purpose**: Ensure child processes never outlive the master test runner
**Location**: `tc/lib/utils/nozombie.sh`

## The Problem

When running tests that spawn subprocesses, a critical issue arises: **what happens if the master test runner dies unexpectedly?**

- Orphaned child processes continue running
- Zombies accumulate
- Resources leak
- CI/CD systems become unstable
- Tests interfere with each other

Traditional `trap` mechanisms and process groups have limitations:
- Can fail if parent crashes hard
- Don't handle double-fork scenarios
- Race conditions during cleanup

## The Solution

**nozombie.sh** implements a bulletproof sidecar architecture:

```
┌─────────────────┐
│  Master Test    │ (PID: 1234)
│  Runner         │
└────────┬────────┘
         │
         │ spawn + init
         ├─────────────────────┐
         │                     │
         v                     v
┌────────────────┐    ┌───────────────────┐
│  Test Runner   │    │  Nozombie Sidecar │
│  (child)       │    │  (watcher)        │
└────────────────┘    └─────────┬─────────┘
                                │
                      ┌─────────┴─────────┐
                      │  Continuous Loop: │
                      │  1. kill -0 1234  │
                      │  2. if dead →     │
                      │     kill children │
                      └───────────────────┘
```

### Key Features

1. **Sidecar Process**: Independent watchdog that survives parent crashes
2. **FIFO Communication**: Non-blocking, reliable IPC between master and sidecar
3. **Continuous Monitoring**: `kill -0` ping every 100ms to detect parent death
4. **Escalating Signals**: TERM → (wait 2s) → KILL for graceful-then-forceful cleanup
5. **No Zombies**: Automatic reaping of dead children
6. **Zero Config**: Works out of the box with sensible defaults

## Architecture

### Components

**Master Test Runner** (your tc process):
- Initializes nozombie system
- Spawns test runners
- Registers children via FIFO
- Normal operation doesn't care about nozombie

**Sidecar Watcher** (background process):
- Monitors master PID with `kill -0`
- Receives commands via FIFO (add/remove/shutdown)
- Maintains registry of active children
- Kills all children when master dies
- Self-terminates after cleanup

**FIFO Directory** (`/tmp/tc-nozombie-$$`):
- `commands`: Master → Sidecar (add/remove PIDs)
- `status`: Sidecar → Master (ready signal)

### Communication Protocol

```bash
# Commands (Master → Sidecar)
add:<pid>      # Register child PID for tracking
remove:<pid>   # Unregister child PID (normal completion)
shutdown       # Clean shutdown request

# Status (Sidecar → Master)
ready          # Sidecar initialized and monitoring
```

## Usage

### Basic Initialization

```bash
#!/usr/bin/env bash
source tc/lib/utils/nozombie.sh

# Initialize nozombie for this master process
tc_nozombie_init $$

# Now all registered children will be killed if this process dies
```

### Manual Child Tracking

```bash
# Spawn a child process
./my-test-runner < input.json &
child_pid=$!

# Register with nozombie
tc_nozombie_register "$child_pid"

# Wait for completion
wait "$child_pid"

# Unregister (normal completion)
tc_nozombie_unregister "$child_pid"
```

### Automatic Tracking (Recommended)

```bash
# Use tc_nozombie_run wrapper - handles everything
tc_nozombie_run ./my-test-runner < input.json
```

### With Timeout

```bash
# Run with 30 second timeout
tc_nozombie_run_with_timeout 30 ./my-test-runner < input.json
exit_code=$?

if [ $exit_code -eq 124 ]; then
    echo "Timeout!"
fi
```

### Integration with tc Runner

```bash
# In tc/lib/core/runner.sh
tc_run_scenario() {
    local suite_dir="$1"
    local scenario_dir="$2"
    local timeout="${3:-$TC_DEFAULT_TIMEOUT}"

    local runner="$suite_dir/run"
    local input_file="$scenario_dir/input.json"

    # Run with nozombie + timeout
    tc_nozombie_run_with_timeout "$timeout" \
        "$runner" "$input_file" > output.json

    local exit_code=$?

    if [ $exit_code -eq 124 ]; then
        # Handle timeout
        echo "Test timed out after ${timeout}s"
    fi
}
```

## API Reference

### tc_nozombie_init(master_pid)

Initialize nozombie system for master process.

**Args**:
- `master_pid`: PID to monitor (usually `$$`)

**Side Effects**:
- Creates FIFO directory
- Spawns sidecar process
- Registers EXIT trap

**Example**:
```bash
tc_nozombie_init $$
```

---

### tc_nozombie_register(child_pid)

Register a child process for tracking.

**Args**:
- `child_pid`: PID to track

**Example**:
```bash
sleep 60 &
tc_nozombie_register $!
```

---

### tc_nozombie_unregister(child_pid)

Unregister a child process (normal completion).

**Args**:
- `child_pid`: PID to stop tracking

**Example**:
```bash
tc_nozombie_unregister $child_pid
```

---

### tc_nozombie_run(command, args...)

Run command with automatic tracking.

**Args**:
- `$@`: Command and arguments

**Returns**:
- Exit code of command

**Example**:
```bash
tc_nozombie_run ./test-runner < input.json
```

---

### tc_nozombie_run_with_timeout(timeout, command, args...)

Run command with timeout and automatic tracking.

**Args**:
- `timeout`: Timeout in seconds
- `$@`: Command and arguments

**Returns**:
- `124`: Timeout occurred
- Exit code of command otherwise

**Example**:
```bash
tc_nozombie_run_with_timeout 30 ./slow-test
if [ $? -eq 124 ]; then
    echo "Timeout!"
fi
```

---

### tc_nozombie_shutdown()

Shutdown nozombie system cleanly.

Called automatically via EXIT trap.

**Example**:
```bash
tc_nozombie_shutdown
```

---

### tc_nozombie_status()

Print debugging status.

**Example**:
```bash
tc_nozombie_status
# Output:
# nozombie status:
#   enabled: 1
#   master_pid: 1234
#   sidecar_pid: 1235
#   fifo_dir: /tmp/tc-nozombie-1234
#   tracked_children: 3
#   children:
#     - 1236 (alive)
#     - 1237 (alive)
#     - 1238 (dead)
```

## Configuration

Environment variables:

```bash
# Enable/disable nozombie (default: 1)
TC_NOZOMBIE_ENABLED=1

# Custom temp directory for FIFOs (default: /tmp)
TC_TMPDIR=/var/tmp
```

## How It Works

### Initialization Flow

1. Master calls `tc_nozombie_init $$`
2. Creates FIFO directory `/tmp/tc-nozombie-$$`
3. Creates `commands` and `status` FIFOs
4. Spawns sidecar process in background
5. Sidecar writes "ready" to status FIFO
6. Master reads "ready" signal
7. Master registers EXIT trap

### Monitoring Loop (Sidecar)

```bash
while true; do
    # Check master alive
    if ! kill -0 $master_pid; then
        kill_all_children
        exit 0
    fi

    # Read commands (non-blocking, 1s timeout)
    if read -t 1 cmd < commands; then
        handle_command $cmd
    fi

    # Reap dead children
    for pid in children; do
        if ! kill -0 $pid; then
            unregister $pid
        fi
    done

    sleep 0.1
done
```

### Cleanup Escalation

When master dies or shutdown requested:

1. **TERM Phase**: Send SIGTERM to all children
2. **Wait**: Sleep 2 seconds for graceful shutdown
3. **KILL Phase**: Send SIGKILL to survivors
4. **Verify**: Sleep 0.5s, final verification

## Testing

Run the demo:

```bash
# Simple timeout test
tc examples/nozombie-demo

# Manual test: master dies, children get killed
source tc/lib/utils/nozombie.sh
tc_nozombie_init $$

# Spawn some children
sleep 999 &
tc_nozombie_register $!

sleep 999 &
tc_nozombie_register $!

# Check they're tracked
tc_nozombie_status

# Kill master (simulate crash)
kill -9 $$

# Verify children are killed (in another terminal)
ps aux | grep "sleep 999"  # Should be empty
```

## Comparison with Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **trap EXIT** | Simple | Fails on hard crash |
| **Process groups** | Standard | Race conditions, double-fork issues |
| **assassin** | Robust, Ruby gem | Requires Ruby, external dependency |
| **nozombie.sh** | Robust, pure bash, zero dependencies | Slightly more complex |

## Limitations

1. **No distributed support**: Only local processes
2. **FIFO overhead**: Small latency (~100ms detection time)
3. **Bash 4+**: Requires associative arrays
4. **Linux/Unix**: Relies on `kill -0` semantics

## Future Enhancements

- [ ] Support for process groups
- [ ] Configurable monitoring interval
- [ ] Metrics/telemetry (children spawned, killed, etc.)
- [ ] Integration with systemd/init systems
- [ ] Network-aware process tracking

## Related

- [assassin gem](https://github.com/ahoward/assassin) - Ruby process supervisor
- [tc timeout handling](./timeout.md)
- [tc test runner contract](./readme.md#test-runner-contract)

---

*"No zombie left behind."* - TC, probably 🚁
