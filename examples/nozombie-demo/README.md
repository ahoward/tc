# Nozombie Demo

Demonstrates the nozombie process management system.

## What is Nozombie?

Nozombie ensures that child processes never outlive the master test runner. It uses a sidecar process architecture with FIFO communication to provide bulletproof cleanup.

**Inspired by**: [assassin](https://github.com/ahoward/assassin)

## Test Cases

This demo includes several test scenarios:

### timeout-test

Demonstrates timeout functionality with automatic process cleanup.

**Input**: Request to sleep for 10 seconds
**Timeout**: 1 second
**Expected**: Process killed after 1s, exit code 124 (timeout)

```bash
tc examples/nozombie-demo
```

## How It Works

1. **Master process** initializes nozombie system
2. **Sidecar process** starts monitoring master PID
3. **Test runner** spawns (registered with nozombie)
4. If master dies unexpectedly → sidecar kills all children
5. Normal completion → children unregistered cleanly

## Architecture

```
Master TC Process ($$)
  ├─ Nozombie Sidecar (watcher)
  │    └─ Monitors master with kill -0
  │    └─ Kills children if master dies
  └─ Test Runner (./run)
       └─ Spawns subprocess (sleep, etc.)
            └─ Automatically killed on timeout or crash
```

## Manual Testing

```bash
# Source nozombie
source tc/lib/utils/nozombie.sh

# Initialize
tc_nozombie_init $$

# Spawn a long-running process
sleep 999 &
child_pid=$!

# Register it
tc_nozombie_register "$child_pid"

# Check status
tc_nozombie_status

# Now try killing the master process:
# - The sidecar will detect it
# - The sleep process will be killed
# - No zombies or orphans left behind
```

## See Also

- [Nozombie Documentation](../../docs/nozombie.md)
- [Assassin (Ruby gem)](https://github.com/ahoward/assassin)
