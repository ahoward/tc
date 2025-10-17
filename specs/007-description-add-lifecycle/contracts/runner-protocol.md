# Contract: Stateful Runner Protocol

**Feature**: 007-description-add-lifecycle
**Version**: 1.0.0
**Date**: 2025-10-16

## Overview

This document specifies the JSON-based protocol for communication between tc framework and stateful test runners. This protocol enables long-running runners that handle multiple test scenarios without restarting.

**Communication Method**: JSON messages over stdin/stdout

**Key Principle**: One JSON message per line, flushed immediately after sending.

---

## Protocol Flow

### Lifecycle

```
1. tc runs setup.sh (if exists)
2. tc spawns ./run process
3. Runner enters ready state
4. FOR EACH scenario:
   a. tc runs before_each.sh (if exists)
   b. tc sends TEST command
   c. Runner processes test
   d. Runner sends RESULT response
   e. tc runs after_each.sh (if exists)
5. tc sends SHUTDOWN command
6. Runner sends SHUTDOWN response
7. Runner exits
8. tc runs teardown.sh (if exists)
```

### Message Flow Diagram

```
tc                                  runner
│                                   │
├─ spawn ────────────────────────→ │ (process starts)
│                                   ├─ initialize
│                                   ├─ ready
│                                   │
├─ {"command":"test",...} ────────→ │
│                                   ├─ process test
│                                   │
│                      ←────────────┤ {"status":"pass",...}
│                                   │
├─ {"command":"test",...} ────────→ │
│                                   ├─ process test
│                                   │
│                      ←────────────┤ {"status":"fail",...}
│                                   │
├─ {"command":"shutdown"} ─────────→ │
│                                   ├─ cleanup
│                      ←────────────┤ {"status":"shutdown"}
│                                   ├─ exit
│                                   ▼
│
▼
```

---

## Message Types

### 1. TEST Command (tc → runner)

**Purpose**: Instruct runner to execute a test scenario.

**Direction**: tc → runner (stdin)

**Format**:
```json
{
  "command": "test",
  "scenario": "scenario-name",
  "input_file": "/absolute/path/to/data/scenario-name/input.json"
}
```

**Fields**:

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `command` | string | Yes | Must be `"test"` | `"test"` |
| `scenario` | string | Yes | Scenario name (directory name from `data/`) | `"create-user"` |
| `input_file` | string | Yes | Absolute path to input.json | `"/home/user/tests/suite/data/create-user/input.json"` |

**Validation**:
- `command` must be exactly `"test"`
- `scenario` must be non-empty alphanumeric string (plus hyphens/underscores)
- `input_file` must be absolute path to existing file

**Example**:
```json
{
  "command": "test",
  "scenario": "create-user",
  "input_file": "/home/user/tests/db-suite/data/create-user/input.json"
}
```

**Runner Responsibilities**:
1. Read and parse JSON from stdin
2. Validate all required fields present
3. Read test input from `input_file`
4. Execute test logic
5. Capture output
6. Send RESULT response

---

### 2. RESULT Response (runner → tc)

**Purpose**: Report test execution result to tc.

**Direction**: runner → tc (stdout)

**Format**:
```json
{
  "status": "pass|fail|error",
  "output": "{...json as string...}",
  "duration_ms": 123,
  "error": "optional error description"
}
```

**Fields**:

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `status` | string | Yes | Test outcome: `"pass"`, `"fail"`, or `"error"` | `"pass"` |
| `output` | string | Yes | Test output as JSON string | `"{\"id\":123}"` |
| `duration_ms` | number | Yes | Test execution time in milliseconds | `45` |
| `error` | string | No | Error message if status is `"fail"` or `"error"` | `"Validation failed"` |

**Status Values**:

| Status | Meaning | Usage |
|--------|---------|-------|
| `pass` | Test passed | Expected output matched actual output |
| `fail` | Test failed | Expected output didn't match actual output |
| `error` | Test error | Exception, crash, or invalid state |

**Validation**:
- `status` must be one of: `"pass"`, `"fail"`, `"error"`
- `output` must be valid JSON (when parsed)
- `duration_ms` must be non-negative integer
- `error` field optional but recommended for `fail` and `error` statuses

**Example - Pass**:
```json
{
  "status": "pass",
  "output": "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"created\":true}",
  "duration_ms": 45
}
```

**Example - Fail**:
```json
{
  "status": "fail",
  "output": "{\"id\":null,\"created\":false}",
  "duration_ms": 23,
  "error": "Database constraint violation: duplicate email"
}
```

**Example - Error**:
```json
{
  "status": "error",
  "output": "{}",
  "duration_ms": 12,
  "error": "Connection refused: database not available"
}
```

**tc Responsibilities**:
1. Read and parse JSON from stdout
2. Validate all required fields present
3. Parse `output` field as JSON
4. Compare parsed output with expected.json
5. Report test result (pass/fail/error)

---

### 3. SHUTDOWN Command (tc → runner)

**Purpose**: Instruct runner to cleanup and exit gracefully.

**Direction**: tc → runner (stdin)

**Format**:
```json
{
  "command": "shutdown"
}
```

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `command` | string | Yes | Must be `"shutdown"` |

**Example**:
```json
{
  "command": "shutdown"
}
```

**Runner Responsibilities**:
1. Stop accepting new test commands
2. Cleanup resources (close connections, delete temp files, etc.)
3. Send SHUTDOWN response
4. Exit with code 0

**Timeout**: tc waits up to 5 seconds for runner to exit. If not exited, sends SIGTERM. If still not exited after 1 second, sends SIGKILL.

---

### 4. SHUTDOWN Response (runner → tc)

**Purpose**: Acknowledge shutdown and confirm cleanup complete.

**Direction**: runner → tc (stdout)

**Format**:
```json
{
  "status": "shutdown"
}
```

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `status` | string | Yes | Must be `"shutdown"` |

**Example**:
```json
{
  "status": "shutdown"}
```

**Optional**: Runner may exit without sending this response. tc will detect process exit and consider shutdown complete.

---

## Error Handling

### Runner Errors

#### Non-JSON Output
**Problem**: Runner outputs non-JSON to stdout.

**tc Behavior**:
- Log error: "Invalid JSON response from runner"
- Mark test as ERROR
- Kill runner process
- Run teardown.sh

**Runner Mitigation**:
- Validate JSON before printing
- Use `jq` to format JSON if available
- Never print debug messages to stdout (use stderr)

#### Malformed JSON
**Problem**: Runner outputs JSON with missing required fields.

**tc Behavior**:
- Log error: "Malformed response: missing field 'status'"
- Mark test as ERROR
- Continue to next test (don't kill runner)

**Runner Mitigation**:
- Use schema validation before sending response
- Test with malformed input to ensure error handling works

#### Timeout
**Problem**: Runner doesn't respond within test timeout.

**tc Behavior**:
- Log error: "Runner timeout after Ns"
- Kill runner process (SIGTERM, then SIGKILL)
- Mark test as ERROR
- Run teardown.sh

**Runner Mitigation**:
- Implement internal timeouts shorter than tc's timeout
- Return `{"status":"error","error":"timeout"}` if approaching limit

#### Process Crash
**Problem**: Runner process exits unexpectedly.

**tc Behavior**:
- Log error: "Runner exited unexpectedly (exit code N)"
- Mark current test as ERROR
- Abort remaining tests in suite
- Run teardown.sh

**Runner Mitigation**:
- Catch all exceptions and return `{"status":"error",...}`
- Never call `exit()` except after SHUTDOWN command
- Use defensive programming (null checks, error handling)

### tc Errors

#### Invalid TEST Command
**Problem**: tc sends malformed TEST command.

**Runner Behavior**:
- Log error to stderr
- Return: `{"status":"error","error":"Invalid command: missing field"}`
- Continue running (don't exit)

**Runner Validation**:
```python
def validate_command(cmd):
    if not isinstance(cmd, dict):
        raise ValueError("Command must be JSON object")
    if cmd.get("command") not in ("test", "shutdown"):
        raise ValueError(f"Unknown command: {cmd.get('command')}")
    if cmd["command"] == "test":
        if "scenario" not in cmd:
            raise ValueError("Missing field: scenario")
        if "input_file" not in cmd:
            raise ValueError("Missing field: input_file")
```

#### Input File Not Found
**Problem**: `input_file` path doesn't exist.

**Runner Behavior**:
- Return: `{"status":"error","error":"Input file not found: /path/to/file"}`

#### Input File Invalid JSON
**Problem**: Input file contains malformed JSON.

**Runner Behavior**:
- Return: `{"status":"error","error":"Invalid JSON in input file"}`

---

## Implementation Examples

### Example 1: Ruby Runner

```ruby
#!/usr/bin/env ruby
# Stateful runner example

require 'json'

# Load .tc-env if exists
env_file = File.join(__dir__, '.tc-env')
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    next if line.strip.empty? || line.start_with?('#')
    if line =~ /^export\s+(\w+)="?([^"]*)"?/
      ENV[$1] = $2
    end
  end
end

# Initialize resources (database connection, etc.)
db = connect_to_database(ENV['PGDATABASE'])

# Main loop - read commands from stdin
$stdin.each_line do |line|
  begin
    cmd = JSON.parse(line)

    case cmd['command']
    when 'test'
      # Read input
      input = JSON.parse(File.read(cmd['input_file']))

      # Execute test
      start_time = Time.now
      output = execute_test(db, cmd['scenario'], input)
      duration_ms = ((Time.now - start_time) * 1000).to_i

      # Send response
      response = {
        status: 'pass',
        output: output.to_json,
        duration_ms: duration_ms
      }
      puts response.to_json
      $stdout.flush  # CRITICAL: Flush immediately

    when 'shutdown'
      # Cleanup
      db.close if db
      puts({ status: 'shutdown' }.to_json)
      $stdout.flush
      break
    end

  rescue => e
    # Error handling
    response = {
      status: 'error',
      output: '{}',
      duration_ms: 0,
      error: e.message
    }
    puts response.to_json
    $stdout.flush
  end
end
```

### Example 2: Python Runner

```python
#!/usr/bin/env python3
# Stateful runner example

import sys
import json
import time
import os

# Load .tc-env if exists
env_file = os.path.join(os.path.dirname(__file__), '.tc-env')
if os.path.exists(env_file):
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                if line.startswith('export '):
                    line = line[7:]  # Remove 'export '
                if '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value.strip('"')

# Initialize resources
db = connect_to_database(os.environ['PGDATABASE'])

# Main loop
for line in sys.stdin:
    try:
        cmd = json.loads(line)

        if cmd['command'] == 'test':
            # Read input
            with open(cmd['input_file']) as f:
                input_data = json.load(f)

            # Execute test
            start_time = time.time()
            output = execute_test(db, cmd['scenario'], input_data)
            duration_ms = int((time.time() - start_time) * 1000)

            # Send response
            response = {
                'status': 'pass',
                'output': json.dumps(output),
                'duration_ms': duration_ms
            }
            print(json.dumps(response))
            sys.stdout.flush()  # CRITICAL: Flush immediately

        elif cmd['command'] == 'shutdown':
            # Cleanup
            if db:
                db.close()
            print(json.dumps({'status': 'shutdown'}))
            sys.stdout.flush()
            break

    except Exception as e:
        # Error handling
        response = {
            'status': 'error',
            'output': '{}',
            'duration_ms': 0,
            'error': str(e)
        }
        print(json.dumps(response))
        sys.stdout.flush()
```

### Example 3: Bash Runner

```bash
#!/usr/bin/env bash
# Stateful runner example

set -e

# Load .tc-env if exists
[ -f .tc-env ] && source .tc-env

# Initialize resources
export PGDATABASE="${PGDATABASE:-test_db}"

# Main loop
while IFS= read -r line; do
    # Parse command
    command=$(echo "$line" | jq -r '.command')

    if [ "$command" = "test" ]; then
        scenario=$(echo "$line" | jq -r '.scenario')
        input_file=$(echo "$line" | jq -r '.input_file')

        # Execute test
        start_time=$(date +%s%3N)
        output=$(execute_test "$scenario" "$input_file")
        end_time=$(date +%s%3N)
        duration_ms=$((end_time - start_time))

        # Send response
        jq -n \
            --arg status "pass" \
            --arg output "$output" \
            --argjson duration_ms "$duration_ms" \
            '{status: $status, output: $output, duration_ms: $duration_ms}'

    elif [ "$command" = "shutdown" ]; then
        # Cleanup
        echo '{"status":"shutdown"}'
        break
    fi
done
```

---

## Testing the Protocol

### Manual Testing

**Start runner manually**:
```bash
cd tests/my-suite
./run
```

**Send TEST command**:
```bash
echo '{"command":"test","scenario":"create-user","input_file":"'$(pwd)'/data/create-user/input.json"}' | ./run
```

**Expected output**:
```json
{"status":"pass","output":"{\"id\":123}","duration_ms":45}
```

**Send SHUTDOWN command**:
```bash
echo '{"command":"shutdown"}' | ./run
```

**Expected output**:
```json
{"status":"shutdown"}
```

### Automated Testing

Create test script `test-runner-protocol.sh`:
```bash
#!/usr/bin/env bash
set -e

cd tests/my-suite

# Start runner in background
./run < commands.txt > responses.txt &
runner_pid=$!

# Send commands
cat > commands.txt << 'EOF'
{"command":"test","scenario":"create-user","input_file":"/absolute/path/to/input.json"}
{"command":"shutdown"}
EOF

# Wait for completion
wait $runner_pid

# Validate responses
if grep -q '"status":"pass"' responses.txt; then
    echo "✓ TEST command works"
else
    echo "✗ TEST command failed"
    exit 1
fi

if grep -q '"status":"shutdown"' responses.txt; then
    echo "✓ SHUTDOWN command works"
else
    echo "✗ SHUTDOWN command failed"
    exit 1
fi

echo "✓ All protocol tests passed"
```

---

## Protocol Versioning

**Current Version**: 1.0.0

**Version Compatibility**:
- Major version change: Breaking protocol changes
- Minor version change: Backward-compatible additions
- Patch version change: Bug fixes, clarifications

**Future Extensions** (not in v1.0):
- Health check: `{"command":"ping"}` → `{"status":"pong"}`
- Statistics: `{"command":"stats"}` → `{"status":"ok","tests_run":5}`
- Configuration: `{"command":"config","key":"value"}`

**Negotiation**: tc and runner must both support protocol v1.0. Future versions may add version negotiation at startup.

---

## Summary

This protocol enables:
- ✅ Long-running test runners
- ✅ Stateful test execution (database connections, etc.)
- ✅ Language-agnostic runners (any language that does JSON I/O)
- ✅ Clean shutdown with resource cleanup
- ✅ Error handling and timeout protection

**Key Requirements for Runner Authors**:
1. Parse JSON commands from stdin
2. Send JSON responses to stdout
3. **FLUSH stdout after each response**
4. Handle errors gracefully (return `{"status":"error"}`)
5. Respond to SHUTDOWN and exit cleanly

**Next**: See `quickstart.md` for a complete database testing example.
