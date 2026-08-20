# Research: Lifecycle Hooks and Stateful Test Runners

**Feature**: 007-description-add-lifecycle
**Date**: 2025-10-16
**Status**: Phase 0 Complete

## Executive Summary

Research into lifecycle hooks and stateful test runners for tc framework. All technical decisions resolved based on POSIX compatibility, existing tc patterns, and testing framework best practices. **No external dependencies required** - all functionality achievable with bash, jq, and standard tools.

**Key Findings**:
1. File presence detection is most reliable hook discovery method
2. JSON over stdin/stdout is most portable runner protocol
3. Setup failure → abort suite; teardown always runs (industry standard)
4. .tc-env files with `source` command for state sharing
5. Global hooks run outside suite scope, compose cleanly

---

## Research Question 1: Hook Discovery Pattern

**Question**: How should tc detect hook scripts?

### Options Evaluated

#### Option A: File Presence Check ✅ SELECTED
**Description**: Check for files named `setup.sh`, `teardown.sh`, `before_each.sh`, `after_each.sh` in suite directory.

**Pros**:
- Simple and explicit
- No parsing required
- Works with any shell
- Immediately visible to developers (`ls` shows hooks)
- Aligns with tc's file-based philosophy

**Cons**:
- None significant

**Implementation**:
```bash
tc_has_hook() {
    local suite_dir="$1"
    local hook_name="$2"
    [ -f "$suite_dir/$hook_name.sh" ] && [ -x "$suite_dir/$hook_name.sh" ]
}
```

#### Option B: Shebang Detection
**Description**: Check first line of `run` script for `#!/usr/bin/env tc-stateful-runner`.

**Pros**:
- Self-documenting runner mode
- Common Unix pattern

**Cons**:
- Requires parsing file contents
- Not needed if setup.sh exists
- Adds complexity

**Verdict**: **Rejected** - File presence is simpler and more reliable.

#### Option C: Metadata File
**Description**: JSON/YAML file (e.g., `.tc-hooks.json`) listing enabled hooks.

**Pros**:
- Centralized configuration

**Cons**:
- Extra file to maintain
- Not discoverable via `ls`
- Adds parsing complexity

**Verdict**: **Rejected** - Violates KISS principle.

### Decision

**SELECTED: Option A - File Presence Check**

**Rationale**:
- Most POSIX-compatible (no special tools required)
- Aligns with tc's existing file-based test discovery
- Developer-friendly (visible in directory listings)
- Zero parsing overhead

**Implementation Notes**:
- Check both existence (`-f`) and executable bit (`-x`)
- Standard naming: `setup.sh`, `teardown.sh`, `before_each.sh`, `after_each.sh`
- Global hooks: Check `tests/.tc/hooks/global_setup.sh` and `global_teardown.sh`
- Hooks are optional - missing hooks are silently skipped

---

## Research Question 2: Stateful Runner Protocol

**Question**: How should tc communicate with long-running runners?

### Options Evaluated

#### Option A: JSON over stdin/stdout ✅ SELECTED
**Description**: tc sends JSON commands to runner's stdin, runner responds on stdout.

**Pros**:
- Universal (works everywhere bash exists)
- tc already uses jq for JSON parsing
- Simple to implement and debug
- Language-agnostic (runner can be any language)
- Aligns with tc's existing text I/O philosophy

**Cons**:
- Line buffering can be tricky (solved with `\n` after each message)

**Protocol Example**:
```bash
# tc sends to runner stdin:
echo '{"command":"test","scenario":"create-user","input_file":"/path/to/input.json"}' | runner

# Runner responds on stdout:
{"status":"pass","output":"{\"id\":123}","duration_ms":45}
```

#### Option B: Unix Domain Sockets
**Description**: tc creates socket, runner connects, bidirectional communication.

**Pros**:
- Better for bidirectional communication
- More robust error handling

**Cons**:
- Requires `nc` or `socat` (additional dependency)
- More complex setup
- Not as portable (different socket implementations)
- Overkill for one-way command/response pattern

**Verdict**: **Rejected** - Adds complexity without significant benefit.

#### Option C: Named Pipes (FIFOs)
**Description**: Create named pipes for tc → runner and runner → tc communication.

**Pros**:
- Built-in to Unix

**Cons**:
- Deadlock risk if not carefully managed
- Requires cleanup
- More complex than stdin/stdout
- No advantage over stdin/stdout for this use case

**Verdict**: **Rejected** - Unnecessary complexity.

### Decision

**SELECTED: Option A - JSON over stdin/stdout**

**Rationale**:
- Simplest and most portable
- Aligns with tc's existing text I/O philosophy
- Already using jq for JSON parsing
- Easy to debug (can test with echo/cat)
- Language-agnostic runners

**Protocol Specification**:
```json
// Command: Test Execution
// Direction: tc → runner (stdin)
{
  "command": "test",
  "scenario": "scenario-name",
  "input_file": "/absolute/path/to/data/scenario/input.json"
}

// Response: Test Result
// Direction: runner → tc (stdout)
{
  "status": "pass|fail|error",
  "output": "{...json output as string...}",
  "duration_ms": 123,
  "error": "optional error message if status=fail or error"
}

// Command: Shutdown
// Direction: tc → runner (stdin)
{
  "command": "shutdown"
}

// Response: Shutdown Acknowledgment
// Direction: runner → tc (stdout)
{
  "status": "shutdown"
}
```

**Implementation Notes**:
- Each message ends with newline (`\n`)
- Runner must flush stdout after each response
- tc validates JSON before parsing (catches malformed responses)
- Timeout protection: If runner doesn't respond within test timeout, kill process
- Error handling: Non-JSON response = runner error

---

## Research Question 3: Hook Failure Handling

**Question**: What happens when hooks fail?

### Best Practices from Other Frameworks

**pytest** (Python):
- `setup_module` fails → skip all tests in module
- `teardown_module` always runs (even after failures)
- `setup_function` fails → skip test, mark as error
- `teardown_function` always runs

**jest** (JavaScript):
- `beforeAll` fails → skip all tests
- `afterAll` always runs
- `beforeEach` fails → skip test
- `afterEach` always runs

**rspec** (Ruby):
- `before(:all)` fails → skip all tests
- `after(:all)` always runs
- `before(:each)` fails → skip test, mark as failed
- `after(:each)` always runs

### Industry Standard Pattern

**Common across all frameworks**:
1. Setup hooks failing = skip tests (can't test if setup failed)
2. Teardown hooks ALWAYS run (cleanup is critical)
3. Teardown failures logged but don't fail tests (cleanup errors shouldn't obscure test results)
4. Before each failing = skip that test only
5. After each always runs (per-test cleanup)

### Decision

**SELECTED: Industry Standard Pattern**

**Hook Failure Behavior**:

| Hook | Failure Exit Code | Action | Continue? | Rationale |
|------|------------------|--------|-----------|-----------|
| `setup.sh` | ≠ 0 | Abort suite, mark as error | No | Can't test if setup failed |
| `teardown.sh` | ≠ 0 | Log error to stderr | Yes | Final cleanup, don't obscure results |
| `before_each.sh` | ≠ 0 | Skip scenario, mark as error | Yes (next scenario) | One test's setup shouldn't block others |
| `after_each.sh` | ≠ 0 | Log warning to stderr | Yes | Cleanup failure shouldn't block next test |
| `global_setup.sh` | ≠ 0 | Abort all suites | No | Global resource setup failed |
| `global_teardown.sh` | ≠ 0 | Log error to stderr | Yes | Final cleanup |

**Guaranteed Execution**:
- `teardown.sh` ALWAYS runs if `setup.sh` ran (use bash trap for reliability)
- `after_each.sh` ALWAYS runs if `before_each.sh` ran
- `global_teardown.sh` ALWAYS runs if `global_setup.sh` ran

**Implementation**:
```bash
tc_execute_suite_with_hooks() {
    local suite_dir="$1"
    local setup_ran=false

    # Run setup
    if tc_has_hook "$suite_dir" "setup"; then
        if ! tc_run_hook "$suite_dir" "setup"; then
            tc_error "setup.sh failed - aborting suite"
            return 1
        fi
        setup_ran=true
    fi

    # Ensure teardown runs even if tests fail
    trap 'tc_run_hook "$suite_dir" "teardown" || true' EXIT

    # Run tests...

    # Trap will ensure teardown runs
}
```

**Rationale**:
- Matches developer expectations from other frameworks
- Cleanup always happens (prevents resource leaks)
- Failures are informative (logged to stderr with context)
- Suite execution is predictable

---

## Research Question 4: Environment Variable Passing

**Question**: How should hooks share state?

### Options Evaluated

#### Option A: .tc-env Files with `source` ✅ SELECTED
**Description**: Hooks write to `.tc-env` file, subsequent hooks/runner `source` it.

**Pros**:
- Simple and explicit
- Works across all shells
- Human-readable (bash syntax)
- Easy to debug (`cat .tc-env`)
- State persists across hook invocations

**Cons**:
- Requires cleanup (delete `.tc-env` in teardown)

**Example**:
```bash
# setup.sh
export PGDATABASE="test_db_$$"
psql -c "CREATE DATABASE $PGDATABASE"
echo "export PGDATABASE=$PGDATABASE" > .tc-env

# before_each.sh
source .tc-env
psql -d "$PGDATABASE" -c "TRUNCATE users CASCADE"

# run (stateful runner)
source .tc-env
# Use $PGDATABASE...

# teardown.sh
source .tc-env
psql -c "DROP DATABASE $PGDATABASE"
rm -f .tc-env
```

#### Option B: Exported Environment Variables
**Description**: Hooks use `export`, variables inherited by child processes.

**Pros**:
- No files to manage

**Cons**:
- Only works for child processes (not siblings)
- `before_each.sh` can't see variables from `setup.sh` (separate process)
- State doesn't persist between hook invocations
- Can't pass to long-running runner

**Verdict**: **Rejected** - Doesn't work for sibling processes.

#### Option C: Config Files (JSON/YAML)
**Description**: Hooks write JSON, others parse it.

**Pros**:
- Structured data

**Cons**:
- Requires jq for every read
- More complex than simple variables
- Overkill for simple key=value state

**Verdict**: **Rejected** - Unnecessary complexity.

### Decision

**SELECTED: Option A - .tc-env Files with `source`**

**Rationale**:
- Simplest approach that works reliably
- Bash-native (no external tools needed)
- Human-readable for debugging
- State persists across hook invocations
- Works with long-running runners

**Convention**:
- File: `.tc-env` in suite directory
- Format: Bash export statements (`export KEY=value`)
- Created by: setup.sh or before_each.sh
- Consumed by: All subsequent hooks and runner
- Deleted by: teardown.sh (cleanup)

**Standard Environment Variables** (provided by tc):
```bash
TC_SUITE_PATH=/absolute/path/to/suite
TC_SCENARIO=scenario-name           # Only for before_each/after_each
TC_DATA_DIR=/path/to/data/scenario  # Only for before_each/after_each
TC_HOOK_TYPE=setup|teardown|before_each|after_each
TC_ROOT=/path/to/test/root          # For global hooks
```

**Implementation Notes**:
- tc sets standard variables before running hooks
- Hooks can add custom variables via `.tc-env`
- Runner should `source .tc-env` if it exists
- Cleanup: Delete `.tc-env` in teardown.sh

---

## Research Question 5: Global Hook Execution Order

**Question**: How do global hooks compose with suite hooks?

### Framework Precedents

**pytest**:
```
1. conftest.py fixtures (session scope) - global setup
2. conftest.py fixtures (module scope) - per-suite setup
3. conftest.py fixtures (function scope) - per-test setup
4. Test execution
5. Function scope teardown
6. Module scope teardown
7. Session scope teardown
```

**jest**:
```
1. beforeAll (outer describe)
2. beforeAll (inner describe)
3. beforeEach (outer)
4. beforeEach (inner)
5. Test
6. afterEach (inner)
7. afterEach (outer)
8. afterAll (inner)
9. afterAll (outer)
```

### Pattern: Outer-to-Inner Setup, Inner-to-Outer Teardown

**Universal principle**:
- Setup: Broadest scope first (global → suite → test)
- Teardown: Narrowest scope first (test → suite → global)
- Like nesting: `{global {suite {test} suite} global}`

### Decision

**SELECTED: Outer-to-Inner Setup, Inner-to-Outer Teardown**

**Execution Order**:
```
When running: tc tests --all

1. global_setup.sh                 # Once for all suites
2. FOR EACH suite:
   a. suite setup.sh               # Once per suite
   b. FOR EACH scenario:
      i.   before_each.sh          # Per scenario
      ii.  run scenario            # Test execution
      iii. after_each.sh           # Per scenario (always)
   c. suite teardown.sh            # Once per suite (always)
3. global_teardown.sh              # Once for all suites (always)
```

**When running single suite** (`tc tests/my-suite`):
```
1. suite setup.sh
2. FOR EACH scenario:
   - before_each.sh
   - run scenario
   - after_each.sh (always)
3. suite teardown.sh (always)

(No global hooks - only run with --all flag)
```

**Failure Behavior**:
- `global_setup.sh` fails → Abort all suites, run `global_teardown.sh`
- `global_teardown.sh` fails → Log error (final cleanup)
- Suite hooks: See Question 3 (setup fails = abort suite, teardown always runs)

**Rationale**:
- Matches developer intuition (outer scope first)
- Cleanup order is reverse of setup (like stack unwinding)
- Global hooks only run with `--all` (explicit scope)
- Predictable and debuggable

**Implementation Notes**:
- Global hooks location: `tests/.tc/hooks/global_setup.sh`, `global_teardown.sh`
- Global hooks inherit working directory: `tests/.tc/hooks/`
- Standard env var `TC_ROOT` points to test root
- Suite hooks can't see global hook variables (different processes)
  - Use `tests/.tc/hooks/.tc-env` for global state if needed

---

## Technologies & Best Practices

### 1. Bash Hook Execution

**Best Practices**:
```bash
# Hook execution wrapper
tc_run_hook() {
    local suite_dir="$1"
    local hook_name="$2"
    local hook_file="$suite_dir/$hook_name.sh"

    # Validate hook exists and is executable
    if [ ! -f "$hook_file" ]; then
        return 0  # Missing hooks are OK
    fi

    if [ ! -x "$hook_file" ]; then
        tc_error "Hook not executable: $hook_file"
        return 1
    fi

    # Set standard environment variables
    export TC_SUITE_PATH="$suite_dir"
    export TC_HOOK_TYPE="$hook_name"

    # Run hook with timeout and error capture
    local start_time=$(tc_timer_start)
    local stderr_file=$(mktemp)

    set +e  # Don't exit on hook failure
    (
        cd "$suite_dir" || exit 1
        ./"$hook_name.sh" 2>"$stderr_file"
    )
    local exit_code=$?
    set -e

    local duration=$(tc_timer_stop "$start_time")

    # Log hook execution
    if [ $exit_code -eq 0 ]; then
        tc_debug "$hook_name.sh passed (${duration}ms)"
    else
        tc_error "$hook_name.sh failed with exit code $exit_code (${duration}ms)"
        cat "$stderr_file" >&2
    fi

    rm -f "$stderr_file"
    return $exit_code
}
```

**Recommendations for Hook Authors**:
```bash
#!/usr/bin/env bash
# setup.sh - Example hook

set -e  # Exit on error
set -u  # Exit on undefined variable

# Use standard environment variables
echo "Running setup for suite: $TC_SUITE_PATH"

# Write state to .tc-env for other hooks
echo "export MY_VAR=value" >> .tc-env

# Exit 0 on success (implicit with set -e)
```

### 2. JSON Protocol Implementation

**Best Practices**:

**Sending commands** (tc → runner):
```bash
tc_send_command_to_runner() {
    local runner_pid="$1"
    local command="$2"

    # Validate JSON before sending
    if ! echo "$command" | jq empty 2>/dev/null; then
        tc_error "Invalid JSON command"
        return 1
    fi

    # Send to runner's stdin with newline
    echo "$command" >> "/proc/$runner_pid/fd/0"
}
```

**Receiving responses** (runner → tc):
```bash
tc_receive_response_from_runner() {
    local runner_fd="$1"
    local timeout="${2:-30}"

    # Read one line with timeout
    local response
    if ! read -t "$timeout" -r response <&"$runner_fd"; then
        tc_error "Timeout waiting for runner response"
        return 1
    fi

    # Validate JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        tc_error "Invalid JSON response: $response"
        return 1
    fi

    echo "$response"
}
```

**Example Runner** (Python):
```python
#!/usr/bin/env python3
import sys
import json

def main():
    # Long-running runner loop
    for line in sys.stdin:
        cmd = json.loads(line)

        if cmd["command"] == "shutdown":
            print(json.dumps({"status": "shutdown"}))
            sys.stdout.flush()
            break

        # Process test command
        result = run_test(cmd["scenario"], cmd["input_file"])
        print(json.dumps(result))
        sys.stdout.flush()  # CRITICAL: Flush after each response

if __name__ == "__main__":
    main()
```

### 3. Process Management

**Best Practices**:

**Starting long-running runner**:
```bash
tc_start_stateful_runner() {
    local suite_dir="$1"
    local runner="$suite_dir/run"

    # Source .tc-env if exists (setup.sh may have created it)
    if [ -f "$suite_dir/.tc-env" ]; then
        source "$suite_dir/.tc-env"
    fi

    # Start runner in background with redirected I/O
    local runner_fifo=$(mktemp -u)
    mkfifo "$runner_fifo"

    (cd "$suite_dir" && "$runner") <"$runner_fifo" > >(tee runner-output.log) &
    local runner_pid=$!

    # Save runner PID for cleanup
    echo "$runner_pid" > .tc-runner-pid
    echo "$runner_fifo" > .tc-runner-fifo

    # Wait for runner to be ready (optional health check)
    sleep 0.1

    echo "$runner_pid"
}
```

**Shutting down runner**:
```bash
tc_shutdown_stateful_runner() {
    local suite_dir="$1"
    local runner_pid=$(cat "$suite_dir/.tc-runner-pid" 2>/dev/null || echo "")

    if [ -z "$runner_pid" ]; then
        return 0
    fi

    # Send shutdown command
    echo '{"command":"shutdown"}' >> "/proc/$runner_pid/fd/0" 2>/dev/null || true

    # Wait for graceful shutdown (5 second timeout)
    local count=0
    while kill -0 "$runner_pid" 2>/dev/null && [ $count -lt 50 ]; do
        sleep 0.1
        ((count++))
    done

    # Force kill if still running
    if kill -0 "$runner_pid" 2>/dev/null; then
        tc_debug "Force killing runner $runner_pid"
        kill -9 "$runner_pid" 2>/dev/null || true
    fi

    # Cleanup
    rm -f "$suite_dir/.tc-runner-pid"
    local fifo=$(cat "$suite_dir/.tc-runner-fifo" 2>/dev/null || echo "")
    [ -n "$fifo" ] && rm -f "$fifo"
    rm -f "$suite_dir/.tc-runner-fifo"
}
```

**Using nozombie.sh** (existing tc utility):
```bash
# Ensure no zombie processes
source "$TC_ROOT/lib/utils/nozombie.sh"

# nozombie.sh automatically handles SIGCHLD to reap zombies
# No additional code needed - just source it!
```

### 4. Backward Compatibility

**Testing Strategy**:

1. **Run existing test suite** without hooks:
   ```bash
   tc tests --all
   # Expected: All existing tests pass (unchanged behavior)
   ```

2. **Add hooks to existing test**:
   ```bash
   # Add empty hooks
   echo '#!/usr/bin/env bash' > tests/my-test/setup.sh
   chmod +x tests/my-test/setup.sh

   tc tests/my-test
   # Expected: Test still passes (hooks are no-ops)
   ```

3. **Verify stateless mode is default**:
   ```bash
   tc tests/my-test
   # Expected: No mention of "stateful" in logs
   ```

4. **Verify opt-in behavior**:
   ```bash
   # Remove hooks
   rm tests/my-test/setup.sh

   tc tests/my-test
   # Expected: Test runs exactly as before
   ```

**Compatibility Guarantees**:
- Tests without hooks run unchanged (stateless mode)
- No new required configuration
- No changes to existing test suite structure
- No changes to `run` script contract (still gets input.json on stdin)
- Exit codes unchanged (0 = pass, 1 = fail)

---

## Dependencies Analysis

**Zero New Dependencies Required** ✅

| Functionality | Dependency | Status |
|--------------|------------|--------|
| Hook discovery | `test`, `chmod` | ✅ POSIX standard |
| Hook execution | `bash` | ✅ Already required |
| JSON protocol | `jq` | ✅ Already required |
| Process management | `kill`, `sleep` | ✅ POSIX standard |
| State sharing | `source`, `export` | ✅ Bash built-in |
| File I/O | `mktemp`, `rm` | ✅ POSIX standard |

**Optional Dependencies** (for examples):
- PostgreSQL - for database testing example (user provides)
- Docker - for containerized testing example (future, optional)

---

## Implementation Risks

### Risk 1: Hook Execution Overhead

**Risk**: Hooks add latency to test execution.

**Mitigation**:
- Hooks are optional (opt-in)
- Hooks run in suite directory (no path resolution overhead)
- Performance goal: < 10ms per hook execution
- Measurement: Add timing to hook execution logs

**Likelihood**: Low
**Impact**: Low (users choose to use hooks)

### Risk 2: Stateful Runner Deadlocks

**Risk**: Runner doesn't respond, tc blocks forever.

**Mitigation**:
- Timeout on runner responses (use `read -t`)
- Force kill runner after timeout
- Log runner stderr for debugging

**Likelihood**: Medium (user-written runners)
**Impact**: Medium (can be recovered with timeout)

### Risk 3: Backward Compatibility Break

**Risk**: Hooks inadvertently change existing test behavior.

**Mitigation**:
- Feature detection (if no hooks, run old code path)
- Comprehensive testing of existing suites
- Clear documentation of opt-in behavior

**Likelihood**: Low (careful implementation)
**Impact**: High (would break existing users)

### Risk 4: Hook State Leakage

**Risk**: .tc-env leaks between test suites.

**Mitigation**:
- .tc-env is suite-local (written in suite directory)
- teardown.sh deletes .tc-env (cleanup)
- Document best practices for hook authors

**Likelihood**: Low
**Impact**: Medium (test isolation)

---

## Recommendations

### For Implementation

1. **Start with hook discovery** - simplest component, testable independently
2. **Add hook execution to executor** - integrate into existing flow
3. **Implement stateful runner last** - most complex, build on hooks
4. **Test at each step** - dogfood with tc's own tests

### For Users

1. **Start simple** - Try empty hooks first, verify they work
2. **Add logging** - Use `set -x` in hooks during development
3. **Test hooks independently** - Run `./setup.sh` manually before using in tc
4. **Use .tc-env** - Don't rely on exported variables (won't work)
5. **Always cleanup in teardown** - Delete .tc-env, close connections, etc.

### For Documentation

1. **Provide working examples** - Database testing, API testing
2. **Show common patterns** - Connection pooling, data seeding
3. **Document gotchas** - Flush stdout in runners, source .tc-env
4. **Include troubleshooting** - Hook failures, runner timeouts

---

## Next Steps

**Phase 1: Design & Contracts**

Generate:
1. `data-model.md` - Hook execution model, state machine, environment variables
2. `contracts/runner-protocol.md` - Complete JSON protocol specification
3. `quickstart.md` - Step-by-step database testing example

**Phase 2: Task Breakdown**

Run `/speckit.tasks` to generate implementation tasks based on this research and Phase 1 design.

**Phase 3: Implementation**

Execute tasks in dependency order using `/speckit.implement`.

---

**Research Status**: ✅ Complete

All technical decisions resolved. No blockers for Phase 1 design.
