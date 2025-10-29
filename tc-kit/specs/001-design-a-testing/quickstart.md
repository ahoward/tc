# Quickstart Guide: TC Testing Framework

**Version**: 1.0 (Draft)
**Target**: Developers getting started with TC

## Overview

TC is a language-agnostic testing framework that enables you to write tests for any application, regardless of programming language. Tests are organized in directories, and results are compared against expected outputs stored as JSON files.

**Key Features**:
- ✅ Zero external dependencies (except `jq` for JSON processing)
- ✅ Language-agnostic - test any application
- ✅ Parallel execution for fast feedback
- ✅ Simple directory-based organization
- ✅ Portable across Linux, macOS, and Windows (WSL)

---

## Installation

### Prerequisites

- POSIX-compatible shell (`bash`, `sh`, `zsh`)
- `jq` command-line JSON processor

**Install jq**:
```bash
# Linux (Debian/Ubuntu)
sudo apt install jq

# Linux (RedHat/CentOS)
sudo yum install jq

# macOS
brew install jq

# Windows (Git Bash includes jq, or via WSL)
```

### Install TC

```bash
# Clone repository (placeholder - adjust when available)
git clone https://github.com/your-org/tc.git
cd tc

# Add to PATH (optional)
export PATH="$PATH:$(pwd)/bin"

# Verify installation
tc --version
```

**Expected output**:
```
TC Testing Framework v1.0.0
```

---

## Your First Test Suite

### 1. Create Test Suite Directory

```bash
mkdir -p my-tests/math/addition
cd my-tests/math/addition
```

### 2. Create Test Scenarios

Create test data directories:

```bash
mkdir -p data/add-positive-numbers
mkdir -p data/add-negative-numbers
mkdir -p data/add-zero
```

**Input file** (`data/add-positive-numbers/input.json`):
```json
{
  "scenario": "add-positive-numbers",
  "input": {
    "a": 5,
    "b": 3
  }
}
```

**Expected output** (`data/add-positive-numbers/expected.json`):
```json
{
  "result": 8
}
```

Repeat for other scenarios:

**`data/add-negative-numbers/input.json`**:
```json
{
  "scenario": "add-negative-numbers",
  "input": {
    "a": -5,
    "b": -3
  }
}
```

**`data/add-negative-numbers/expected.json`**:
```json
{
  "result": -8
}
```

**`data/add-zero/input.json`**:
```json
{
  "scenario": "add-zero",
  "input": {
    "a": 10,
    "b": 0
  }
}
```

**`data/add-zero/expected.json`**:
```json
{
  "result": 10
}
```

### 3. Create Test Runner

Create an executable test runner (`run`):

```bash
#!/bin/bash
# Test runner for addition tests

INPUT_FILE="$1"

# Parse input
A=$(jq -r '.input.a' "$INPUT_FILE")
B=$(jq -r '.input.b' "$INPUT_FILE")
SCENARIO=$(jq -r '.scenario' "$INPUT_FILE")

# Perform addition
RESULT=$((A + B))

# Output result as JSON
jq -n \
  --arg scenario "$SCENARIO" \
  --argjson result "$RESULT" \
  '{
    scenario: $scenario,
    status: "pass",
    output: { result: $result },
    duration_ms: 5
  }'

exit 0
```

**Make it executable**:
```bash
chmod +x run
```

### 4. Run Your Tests

```bash
# From the test suite directory
tc run .

# Or from parent directory
tc run my-tests/math/addition
```

**Expected output**:
```
TC Test Results
================
Suite: math/addition
  ✓ add-positive-numbers (5ms)
  ✓ add-negative-numbers (5ms)
  ✓ add-zero (5ms)

Summary: 3 passed, 0 failed, 0 errors (3 total, 15ms)
```

---

## Directory Structure

Your test suite should follow this structure:

```
my-tests/
└── math/
    └── addition/              # Test suite directory
        ├── run                # Test runner (required, executable)
        ├── .tc-config         # Configuration (optional)
        ├── README.md          # Documentation (optional)
        ├── data/              # Scenario data (required)
        │   ├── add-positive-numbers/
        │   │   ├── input.json       # Scenario input (required)
        │   │   └── expected.json    # Expected output (required)
        │   ├── add-negative-numbers/
        │   │   ├── input.json
        │   │   └── expected.json
        │   └── add-zero/
        │       ├── input.json
        │       └── expected.json
        └── .tc-result         # Result file (generated, not version-controlled)
```

---

## Common Commands

```bash
# Run single test suite
tc run ./path/to/suite

# Run all test suites in directory tree
tc run ./my-tests --all

# Run tests in parallel (auto-detect CPU cores)
tc run ./my-tests --all --parallel

# Run specific test suites by pattern
tc run ./my-tests --pattern="*/auth/*"

# Run with custom parallelism
tc run ./my-tests --all --parallel=4

# Run with custom timeout (seconds)
tc run ./my-tests --timeout=600

# Show help
tc --help
```

---

## Test Runner Examples

### Example 1: HTTP API Test (Python)

**`run`**:
```python
#!/usr/bin/env python3
import json
import sys
import requests
import time

input_file = sys.argv[1]

with open(input_file) as f:
    data = json.load(f)

scenario = data['scenario']
endpoint = data['input']['endpoint']
method = data['input']['method']
body = data['input'].get('body', None)

start = time.time()
response = requests.request(method, endpoint, json=body, timeout=5)
duration = int((time.time() - start) * 1000)

result = {
    "scenario": scenario,
    "status": "pass",
    "output": {
        "status_code": response.status_code,
        "body": response.json() if response.headers.get('content-type') == 'application/json' else response.text
    },
    "duration_ms": duration
}

print(json.dumps(result))
sys.exit(0)
```

**`data/get-user/input.json`**:
```json
{
  "scenario": "get-user",
  "input": {
    "endpoint": "http://localhost:8080/users/42",
    "method": "GET"
  }
}
```

**`data/get-user/expected.json`**:
```json
{
  "status_code": 200,
  "body": {
    "id": 42,
    "name": "John Doe"
  }
}
```

---

### Example 2: CLI Tool Test (Node.js)

**`run`**:
```javascript
#!/usr/bin/env node
const fs = require('fs');
const { execSync } = require('child_process');

const inputFile = process.argv[2];
const data = JSON.parse(fs.readFileSync(inputFile, 'utf8'));

const scenario = data.scenario;
const command = data.input.command;
const args = data.input.args || [];

const start = Date.now();
const output = execSync(`${command} ${args.join(' ')}`, { encoding: 'utf8' });
const duration = Date.now() - start;

const result = {
  scenario: scenario,
  status: 'pass',
  output: { stdout: output.trim() },
  duration_ms: duration
};

console.log(JSON.stringify(result));
process.exit(0);
```

**`data/version-check/input.json`**:
```json
{
  "scenario": "version-check",
  "input": {
    "command": "my-cli",
    "args": ["--version"]
  }
}
```

**`data/version-check/expected.json`**:
```json
{
  "stdout": "my-cli version 1.0.0"
}
```

---

## Configuration

Create `.tc-config` file in test suite directory to customize behavior:

```ini
# Override timeout (default: 300 seconds)
timeout=600

# Override comparison mode (default: semantic_json)
# Options: semantic_json, whitespace_norm, fuzzy
comparison=semantic_json

# Fuzzy matching threshold (default: 0.9)
fuzzy_threshold=0.85

# Allow parallel scenario execution within suite (default: true)
parallel=true

# Environment variables for test runner
env.DATABASE_URL=postgresql://localhost/test_db
env.API_KEY=test_key_12345
```

---

## Tips & Best Practices

### 1. Keep Test Runners Simple

Test runners should:
- Focus on executing the application under test
- Produce structured JSON output
- Avoid complex logic (test logic should be in the application)
- Be self-contained (include dependencies or document installation)

### 2. Organize by Feature

```
my-tests/
├── auth/
│   ├── login/
│   ├── logout/
│   └── password-reset/
├── api/
│   ├── users/
│   └── orders/
└── ui/
    ├── homepage/
    └── checkout/
```

### 3. Use Meaningful Scenario Names

Good: `login-success`, `login-invalid-password`, `login-missing-username`
Bad: `test1`, `test2`, `test3`

### 4. Version Control

**Include in git**:
- Test runner (`run`)
- Configuration (`.tc-config`)
- Scenario data (`input.json`, `expected.json`)
- Documentation (`README.md`)

**Exclude from git** (add to `.gitignore`):
- Result files (`.tc-result`)
- Temporary files

```gitignore
# .gitignore
**/.tc-result
**/.tc-cache
```

### 5. Document Test Suites

Include a `README.md` in each suite directory explaining:
- What is being tested
- How to run tests
- Dependencies required
- Known issues or limitations

---

## Troubleshooting

### Test Runner Not Found

**Error**: `ERROR: Test runner not found: ./run`

**Solution**: Ensure `run` file exists and is executable:
```bash
chmod +x run
```

### Invalid JSON Output

**Error**: `ERROR: Test runner produced invalid JSON`

**Solution**: Validate JSON output:
```bash
./run ./data/scenario/input.json | jq .
```

### Test Timeout

**Error**: `ERROR: Test exceeded timeout (300s)`

**Solution**: Increase timeout in `.tc-config`:
```ini
timeout=600
```

### jq Not Found

**Error**: `ERROR: jq command not found`

**Solution**: Install jq:
```bash
# Linux
sudo apt install jq

# macOS
brew install jq
```

---

## Next Steps

1. **Read the Test Suite Interface Contract**: See `contracts/test-suite-interface.md` for full specification
2. **Explore Examples**: Check `examples/` directory for more test runner examples
3. **Run in CI/CD**: Integrate TC into your build pipeline (see CI/CD guide)
4. **Advanced Features**: Learn about fuzzy matching, custom comparison modes, and result analysis

---

## Getting Help

- Documentation: `tc --help`
- Interface Spec: `contracts/test-suite-interface.md`
- Examples: `examples/` directory
- Issues: Report bugs at [project-repository-url]

