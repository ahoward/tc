# Research: TC Testing Framework Technical Decisions

**Feature**: TC - Language-Agnostic Testing Framework
**Date**: 2025-10-11
**Phase**: 0 (Research & Design Decisions)

## Overview

This document consolidates research findings and technical decisions for implementing the TC testing framework. Each decision addresses specific technical questions raised during the planning phase.

---

## 1. JSON Comparison in Shell

### Decision

**Use `jq` as primary JSON processor with graceful degradation**

### Rationale

- `jq` is widely available (default on many systems, easy install via package managers)
- Provides robust JSON parsing, semantic comparison, and order-independent object comparison
- Pure shell JSON parsing is error-prone and doesn't handle edge cases well
- Python dependency would violate zero-dependency principle
- `jq` can be considered "standard system tool" like grep/sed

### Implementation Approach

```bash
# Semantic JSON comparison (order-independent for objects)
compare_json() {
    local expected="$1"
    local actual="$2"

    # Normalize and sort both JSON structures
    expected_norm=$(jq -S '.' "$expected" 2>/dev/null)
    actual_norm=$(jq -S '.' "$actual" 2>/dev/null)

    if [ "$expected_norm" = "$actual_norm" ]; then
        return 0  # Match
    else
        return 1  # Mismatch
    fi
}
```

### Alternatives Considered

- **Pure shell parsing**: Rejected - too fragile, doesn't handle nested structures or edge cases
- **Python/Node.js fallback**: Rejected - violates zero-dependency principle
- **No JSON processing**: Rejected - JSON comparison is core requirement

### Fallback Strategy

If `jq` is not available:
1. Check for `jq` on first run
2. If missing, provide clear error with installation instructions for user's platform
3. Optionally support byte-for-byte comparison as degraded mode

---

## 2. Cross-Platform Parallelism

### Decision

**Platform-specific CPU detection with manual override, use background jobs for parallelism**

### Rationale

- Native shell background jobs (`&`) are POSIX-compatible and reliable
- CPU detection varies by platform but has known patterns
- Manual override (`--parallel=N`) provides escape hatch
- Avoids dependency on GNU parallel or other external tools

### Implementation Approach

```bash
# Detect CPU cores cross-platform
detect_cores() {
    local cores=4  # Fallback default

    if command -v nproc >/dev/null 2>&1; then
        cores=$(nproc)  # Linux
    elif [ -f /proc/cpuinfo ]; then
        cores=$(grep -c ^processor /proc/cpuinfo)  # Linux fallback
    elif command -v sysctl >/dev/null 2>&1; then
        cores=$(sysctl -n hw.ncpu 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)  # macOS
    elif [ -n "$NUMBER_OF_PROCESSORS" ]; then
        cores=$NUMBER_OF_PROCESSORS  # Windows (Git Bash/WSL)
    fi

    echo "$cores"
}

# Run tests in parallel using job control
run_parallel() {
    local max_jobs="$1"
    shift
    local test_suites=("$@")

    for suite in "${test_suites[@]}"; do
        # Wait if we've hit max parallel jobs
        while [ "$(jobs -r | wc -l)" -ge "$max_jobs" ]; do
            sleep 0.1
        done

        # Run test suite in background
        run_test_suite "$suite" &
    done

    # Wait for all background jobs to complete
    wait
}
```

### Alternatives Considered

- **GNU parallel**: Rejected - external dependency, not always available
- **xargs -P**: Considered - works but less flexible than job control
- **Fixed parallelism**: Rejected - doesn't adapt to hardware

---

## 3. Timeout Implementation

### Decision

**Use shell job control with configurable per-suite timeouts (default 300s / 5min)**

### Rationale

- Portable across POSIX shells
- Configurable via suite-level config file or command-line flag
- Graceful process termination with escalation (TERM then KILL)
- No dependency on `timeout` command (GNU coreutils, not universal)

### Implementation Approach

```bash
# Run command with timeout
run_with_timeout() {
    local timeout_seconds="$1"
    local command="$2"

    # Run command in background
    $command &
    local pid=$!

    # Monitor with timeout
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout_seconds" ]; then
            # Timeout reached - terminate gracefully, then force
            kill -TERM "$pid" 2>/dev/null
            sleep 2
            kill -KILL "$pid" 2>/dev/null
            return 124  # Standard timeout exit code
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    # Get actual exit code
    wait "$pid"
    return $?
}

# Read timeout from suite config or use default
get_suite_timeout() {
    local suite_dir="$1"
    local default_timeout="${2:-300}"  # 5 minutes default

    if [ -f "$suite_dir/.tc-config" ]; then
        grep '^timeout=' "$suite_dir/.tc-config" | cut -d= -f2 || echo "$default_timeout"
    else
        echo "$default_timeout"
    fi
}
```

### Configuration Format

Suite-level `.tc-config` file (optional):
```ini
# .tc-config
timeout=600      # Override timeout to 10 minutes
comparison=fuzzy # Override comparison mode
```

### Alternatives Considered

- **GNU timeout command**: Rejected - not universally available (missing on some BSD/macOS)
- **No timeout**: Rejected - hangs are unacceptable in CI/CD
- **Fixed global timeout**: Rejected - different test types need different durations

---

## 4. Test Runner Interface Contract

### Decision

**Executable-based interface with JSON input via stdin/file, JSON output via stdout**

### Rationale

- Language-agnostic: any language can read JSON and produce JSON
- Stdin/stdout is universal and portable
- Exit codes provide execution status separate from test results
- Clear separation: stdout=data, stderr=logs

### Interface Specification

```
Test Runner Contract v1.0

INPUTS:
  1. Scenario data file path as first argument: $1
  2. Scenario data available at path contains:
     {
       "scenario": "scenario-name",
       "input": { /* test input data */ }
     }

OUTPUTS:
  1. Exit codes:
     - 0: Runner executed successfully (test may pass or fail)
     - Non-zero: Runner crashed/error (framework reports execution failure)

  2. stdout: JSON test result
     {
       "scenario": "scenario-name",
       "status": "pass|fail",
       "output": { /* actual output data */ },
       "duration_ms": 123
     }

  3. stderr: Logs, diagnostics (not compared, captured for debugging)

EXECUTION:
  ./run <scenario-data-file>

EXAMPLE:
  Given: ./data/login-success/input.json contains {"username": "admin", "password": "secret"}
  Run:   ./run ./data/login-success/input.json
  stdout: {"scenario": "login-success", "status": "pass", "output": {"token": "abc123"}, "duration_ms": 45}
  stderr: [2025-10-11 14:30:00] INFO: Connecting to auth service...
  exit:  0
```

### Test Suite Directory Structure

```
tc/user/login/              # Test suite directory
├── run                     # Test runner executable (any language)
├── .tc-config              # Optional: timeout, comparison overrides
├── README.md               # Optional: suite documentation
└── data/
    ├── login-success/
    │   ├── input.json      # Test scenario input
    │   └── expected.json   # Expected output
    ├── login-invalid-password/
    │   ├── input.json
    │   └── expected.json
    └── login-missing-username/
        ├── input.json
        └── expected.json
```

### Alternatives Considered

- **Command-line args for input**: Rejected - doesn't scale for complex data
- **Environment variables**: Rejected - limited size, shell escaping issues
- **No structured output**: Rejected - need machine-parseable results

---

## 5. Result File Format

### Decision

**JSONL format for results, single `.tc-result` file per suite (overwritten)**

### Rationale

- JSONL (JSON Lines) is streamable and easy to parse line-by-line
- Single file simplifies management (no timestamp tracking needed)
- Not version-controlled (add to .gitignore)
- Each line is a complete test scenario result for easy filtering

### Result File Structure

`.tc-result` (JSONL format):
```jsonl
{"suite":"user/login","scenario":"login-success","status":"pass","duration_ms":45,"timestamp":"2025-10-11T14:30:00Z"}
{"suite":"user/login","scenario":"login-invalid-password","status":"pass","duration_ms":38,"timestamp":"2025-10-11T14:30:00Z"}
{"suite":"user/login","scenario":"login-missing-username","status":"fail","duration_ms":42,"timestamp":"2025-10-11T14:30:00Z","diff":{"expected":{"error":"missing_field"},"actual":{"error":"validation_error"}}}
```

Each line contains:
- `suite`: Suite path/identifier
- `scenario`: Scenario name
- `status`: "pass", "fail", "error", "timeout"
- `duration_ms`: Execution time in milliseconds
- `timestamp`: ISO 8601 timestamp
- `diff` (optional): Difference details for failed tests
- `error` (optional): Error message for execution failures

### Summary Report Format

High-level summary (stdout after run):
```
TC Test Results
================
Suite: user/login
  ✓ login-success (45ms)
  ✓ login-invalid-password (38ms)
  ✗ login-missing-username (42ms)

Suite: user/registration
  ✓ register-new-user (156ms)
  ✓ register-duplicate-email (89ms)

Summary: 4 passed, 1 failed, 0 errors (5 total, 370ms)
```

### Alternatives Considered

- **Timestamped files**: Rejected per clarification - single file preferred
- **XML/TAP format**: Rejected - JSONL simpler and more flexible
- **Separate logs per scenario**: Rejected - harder to aggregate

---

## 6. Fuzzy Matching Strategy

### Decision

**String similarity with configurable threshold (default: 0.9 / 90% match)**

### Rationale

- Simple to understand and configure
- Useful for tests with timestamps, IDs, or floating-point precision
- Optional feature - not enabled by default
- Can be implemented in pure shell using Levenshtein distance approximation

### Implementation Approach

```bash
# Fuzzy comparison with configurable threshold
compare_fuzzy() {
    local expected="$1"
    local actual="$2"
    local threshold="${3:-0.9}"  # Default 90% similarity

    # Calculate similarity score (0.0 to 1.0)
    local similarity=$(string_similarity "$expected" "$actual")

    # Compare against threshold
    if awk -v sim="$similarity" -v thresh="$threshold" 'BEGIN { exit (sim >= thresh ? 0 : 1) }'; then
        return 0  # Match
    else
        return 1  # Mismatch
    fi
}

# Simple string similarity (normalized Levenshtein distance)
string_similarity() {
    local str1="$1"
    local str2="$2"

    # Use awk for Levenshtein calculation
    # (Implementation details omitted for brevity - standard algorithm)
    # Returns: 1.0 for identical, 0.0 for completely different
}
```

### Configuration

In `.tc-config`:
```ini
comparison=fuzzy
fuzzy_threshold=0.85  # 85% match required
```

### Use Cases

- Timestamp variations: `{"created_at": "2025-10-11T14:30:00Z"}` ≈ `{"created_at": "2025-10-11T14:30:01Z"}`
- Generated IDs: `{"id": "abc123"}` ≈ `{"id": "abc124"}`
- Floating-point: `{"score": 0.333}` ≈ `{"score": 0.334}`

### Alternatives Considered

- **Regex patterns**: Rejected - too complex to specify, not user-friendly
- **Field-specific rules**: Rejected - scope creep, keep simple
- **No fuzzy matching**: Rejected - requirement is optional but valuable

---

## Summary of Key Technical Decisions

| Aspect | Decision | Key Tool/Approach |
|--------|----------|-------------------|
| JSON Processing | Use `jq` with fallback | jq -S for semantic comparison |
| Parallelism | Background jobs + CPU detection | Shell job control (`&`, `wait`) |
| Timeouts | Shell-based with escalation | TERM → KILL with configurable duration |
| Runner Interface | JSON in/out via files/stdout | Exit codes + JSON output contract |
| Result Storage | JSONL format, single file | `.tc-result` overwritten each run |
| Fuzzy Matching | String similarity threshold | Levenshtein distance, 90% default |

## Dependencies Assessment

**External Dependencies**:
- `jq` (JSON processor) - REQUIRED for JSON comparison
- POSIX shell tools (sh, awk, grep, etc.) - Standard on all target platforms

**Installation Requirements**:
- Most systems: `jq` already installed or available via package manager
- Linux: `apt install jq` / `yum install jq`
- macOS: `brew install jq`
- Windows: Git Bash includes `jq` / WSL uses Linux packages

**Rationale for jq**: While technically an external dependency, `jq` is ubiquitous in dev environments and testing infrastructure. The alternative (pure shell JSON parsing) would be unreliable and fragile. The trade-off favors robustness over absolute zero-dependency.

## Next Steps

Phase 1 artifacts to generate:
1. **data-model.md**: Entity definitions (Test Suite, Scenario, Result, Run)
2. **contracts/test-suite-interface.md**: Formal runner interface contract
3. **quickstart.md**: Getting started guide
4. Update agent context with technical decisions

