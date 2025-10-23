# Test Suite Interface Contract

**Version**: 1.0
**Date**: 2025-10-11
**Status**: Specification

## Overview

This document defines the formal interface contract between the TC testing framework and test suite runners. Any executable that conforms to this contract can serve as a test runner, regardless of programming language.

---

## Contract Summary

A test runner MUST:
1. Accept a scenario data file path as the first command-line argument
2. Read and parse the JSON input from that file
3. Execute the test logic
4. Output a JSON result to stdout
5. Exit with code 0 for successful execution (test may pass or fail)
6. Exit with non-zero code only for execution failures (crashes, invalid input)

---

## Input Contract

### Command-Line Interface

```bash
./run <scenario-data-file>
```

**Arguments**:
- `<scenario-data-file>`: Absolute or relative path to a JSON file containing scenario input

**Example**:
```bash
./run ./data/login-success/input.json
```

### Input File Format

The scenario data file contains a JSON object with the following structure:

```json
{
  "scenario": "scenario-name",
  "input": {
    /* test-specific input data */
  }
}
```

**Fields**:
- `scenario` (string, required): Name of the test scenario (for reference)
- `input` (object, required): Test-specific input data (structure defined by test author)

**Example** (`./data/login-success/input.json`):
```json
{
  "scenario": "login-success",
  "input": {
    "username": "admin",
    "password": "secret123",
    "remember_me": true
  }
}
```

---

## Output Contract

### Standard Output (stdout)

The test runner MUST output a single JSON object to stdout containing the test result:

```json
{
  "scenario": "scenario-name",
  "status": "pass|fail",
  "output": {
    /* actual output data */
  },
  "duration_ms": 123
}
```

**Fields**:
- `scenario` (string, required): Name of the scenario (should match input)
- `status` (string, required): Test execution status
  - `"pass"`: Test executed successfully (output will be compared to expected)
  - `"fail"`: Test executed but indicated failure (e.g., application crashed)
- `output` (object, required): Actual output produced by the test
- `duration_ms` (integer, optional): Execution time in milliseconds (if runner tracks it)

**Example** (success):
```json
{
  "scenario": "login-success",
  "status": "pass",
  "output": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 42,
      "username": "admin",
      "role": "admin"
    },
    "expires_at": "2025-10-12T14:30:00Z"
  },
  "duration_ms": 45
}
```

**Example** (application failure):
```json
{
  "scenario": "login-invalid-password",
  "status": "pass",
  "output": {
    "error": "invalid_credentials",
    "message": "Username or password is incorrect"
  },
  "duration_ms": 38
}
```

**Notes**:
- Even application failures should return `"status": "pass"` if the runner executed successfully
- The framework compares `output` to the expected output to determine test pass/fail
- Runners should NOT determine pass/fail based on application behavior

### Standard Error (stderr)

The test runner MAY output diagnostic logs, debug information, or progress messages to stderr. This output is:
- Captured by the framework for debugging
- NOT compared to expected output
- Included in result files for failure diagnosis

**Example stderr output**:
```
[2025-10-11 14:30:00] INFO: Connecting to auth service at http://localhost:8080
[2025-10-11 14:30:00] DEBUG: Sending credentials for user: admin
[2025-10-11 14:30:00] INFO: Authentication successful, token received
```

### Exit Codes

**Exit Code 0**: Runner executed successfully
- Test may have passed or failed (determined by output comparison)
- JSON output was produced to stdout
- Framework will compare output to expected

**Non-zero Exit Codes**: Runner execution failed
- Runner crashed, threw an exception, or encountered an error
- May not have produced valid JSON output
- Framework records as execution error, not test failure

**Standard Exit Codes** (optional but recommended):
- `0`: Success
- `1`: General error
- `2`: Invalid input (couldn't parse scenario file)
- `124`: Timeout (if runner implements its own timeout)
- `127`: Command not found (shouldn't happen for valid runners)

---

## Error Handling

### Invalid Input File

If the runner cannot read or parse the input file:
- Output error to stderr
- Exit with non-zero code (suggest: 2)
- Framework will record as execution error

**Example**:
```bash
# stderr
ERROR: Could not read input file: ./data/missing/input.json

# exit code
2
```

### Test Execution Crashes

If the test logic crashes or throws an uncaught exception:
- Attempt to log error to stderr
- Exit with non-zero code
- Framework will record as execution error

**Example**:
```bash
# stderr
FATAL: Uncaught exception in test logic: NullPointerException at line 42

# exit code
1
```

### Invalid JSON Output

If the runner outputs malformed JSON to stdout:
- Framework will detect parse error
- Record as execution error
- Include raw stdout in error details

---

## Comparison Contract

The framework compares the `output` field from the runner against the expected output file (`expected.json`).

### Expected Output File Format

```json
{
  /* expected output structure - mirrors runner's output field */
}
```

**Example** (`./data/login-success/expected.json`):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 42,
    "username": "admin",
    "role": "admin"
  },
  "expires_at": "2025-10-12T14:30:00Z"
}
```

### Comparison Modes

The framework supports multiple comparison modes (configurable per suite):

**1. Semantic JSON (default)**:
- Order-independent for object keys
- Array order matters
- Exact value matching
- Best for structured API responses

**2. Whitespace Normalization**:
- Trim leading/trailing whitespace
- Collapse multiple spaces
- Useful for text-based outputs

**3. Fuzzy Matching**:
- Threshold-based similarity (default 90%)
- Tolerates small differences (timestamps, IDs, floating-point)
- Configurable per suite

---

## Examples

### Example 1: Simple Authentication Test

**Input** (`./data/login-success/input.json`):
```json
{
  "scenario": "login-success",
  "input": {
    "username": "admin",
    "password": "secret123"
  }
}
```

**Expected** (`./data/login-success/expected.json`):
```json
{
  "success": true,
  "token": "valid-token"
}
```

**Runner** (`./run`):
```bash
#!/bin/bash
INPUT_FILE="$1"
USERNAME=$(jq -r '.input.username' "$INPUT_FILE")
PASSWORD=$(jq -r '.input.password' "$INPUT_FILE")

if [ "$USERNAME" = "admin" ] && [ "$PASSWORD" = "secret123" ]; then
  jq -n '{
    scenario: "login-success",
    status: "pass",
    output: { success: true, token: "valid-token" },
    duration_ms: 10
  }'
  exit 0
else
  jq -n '{
    scenario: "login-success",
    status: "pass",
    output: { success: false, error: "invalid_credentials" },
    duration_ms: 10
  }'
  exit 0
fi
```

**Result**: Test passes (output matches expected)

---

### Example 2: HTTP API Test (Python)

**Input** (`./data/api-get-user/input.json`):
```json
{
  "scenario": "api-get-user",
  "input": {
    "user_id": 123,
    "endpoint": "http://localhost:8080/users/123"
  }
}
```

**Expected** (`./data/api-get-user/expected.json`):
```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com"
}
```

**Runner** (`./run`):
```python
#!/usr/bin/env python3
import json
import sys
import requests
import time

def main():
    input_file = sys.argv[1]

    with open(input_file) as f:
        data = json.load(f)

    scenario = data['scenario']
    endpoint = data['input']['endpoint']

    start = time.time()
    try:
        response = requests.get(endpoint, timeout=5)
        duration = int((time.time() - start) * 1000)

        result = {
            "scenario": scenario,
            "status": "pass",
            "output": response.json(),
            "duration_ms": duration
        }
        print(json.dumps(result))
        sys.exit(0)

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
```

**Result**: Test passes if API returns expected user data

---

### Example 3: Database Query Test (Go)

**Input** (`./data/db-query-orders/input.json`):
```json
{
  "scenario": "db-query-orders",
  "input": {
    "query": "SELECT * FROM orders WHERE user_id = 42"
  }
}
```

**Expected** (`./data/db-query-orders/expected.json`):
```json
{
  "rows": [
    {"order_id": 1, "total": 99.99},
    {"order_id": 2, "total": 149.50}
  ],
  "count": 2
}
```

**Runner** (`./run`):
```go
#!/usr/bin/env go run
package main

import (
    "encoding/json"
    "fmt"
    "os"
)

type Input struct {
    Scenario string `json:"scenario"`
    Input    struct {
        Query string `json:"query"`
    } `json:"input"`
}

type Output struct {
    Scenario   string      `json:"scenario"`
    Status     string      `json:"status"`
    Output     interface{} `json:"output"`
    DurationMs int         `json:"duration_ms"`
}

func main() {
    inputFile := os.Args[1]

    var input Input
    f, _ := os.Open(inputFile)
    json.NewDecoder(f).Decode(&input)

    // Execute query (simplified)
    result := map[string]interface{}{
        "rows": []map[string]interface{}{
            {"order_id": 1, "total": 99.99},
            {"order_id": 2, "total": 149.50},
        },
        "count": 2,
    }

    output := Output{
        Scenario:   input.Scenario,
        Status:     "pass",
        Output:     result,
        DurationMs: 35,
    }

    json.NewEncoder(os.Stdout).Encode(output)
    os.Exit(0)
}
```

**Result**: Test passes if query returns expected rows

---

## Runner Implementation Checklist

- [ ] Accept scenario file path as first argument
- [ ] Read and parse JSON input file
- [ ] Execute test logic
- [ ] Produce JSON output to stdout with required fields
- [ ] Include `scenario`, `status`, `output`, `duration_ms` in JSON output
- [ ] Write diagnostic logs to stderr (not stdout)
- [ ] Exit with code 0 on successful execution
- [ ] Exit with non-zero code only on execution failures
- [ ] Handle missing/invalid input files gracefully
- [ ] Handle execution errors (crashes) gracefully
- [ ] Validate JSON output format before printing

---

## Validation Tools

Framework will validate:
- Runner file exists and is executable
- Input file is valid JSON
- Runner produces valid JSON output
- Output contains required fields: `scenario`, `status`, `output`
- Exit code is 0 for successful execution

Framework will report errors for:
- Missing or non-executable runner
- Malformed JSON input
- Malformed JSON output
- Missing required output fields
- Execution timeouts

---

## Versioning

**Current Version**: 1.0

Future versions may add:
- Optional fields (backward compatible)
- New comparison modes
- Enhanced error reporting

Breaking changes will increment major version (2.0, etc.)

