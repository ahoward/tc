# Data Model: TC Testing Framework

**Feature**: TC - Language-Agnostic Testing Framework
**Date**: 2025-10-11
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the core entities, their attributes, relationships, and state transitions for the TC testing framework. The data model is designed to be simple, file-based, and language-agnostic.

---

## Entity Definitions

### 1. Test Suite

A directory-based collection of related test scenarios with a common test runner.

**Attributes**:
- `path` (string, required): Relative or absolute path to suite directory (e.g., `tc/user/login`)
- `name` (string, derived): Last component of path (e.g., `login`)
- `runner` (file path, required): Path to executable test runner within suite (e.g., `./run`)
- `scenarios` (array of Scenario, derived): List of test scenarios discovered in `data/` subdirectory
- `config` (Config, optional): Suite-level configuration from `.tc-config` file
- `status` (enum, runtime): Current execution status during run
  - Values: `pending`, `running`, `completed`, `error`
- `last_run` (timestamp, persisted): ISO 8601 timestamp of last execution

**File Structure**:
```
<suite-path>/
├── run                 # Test runner (required)
├── .tc-config          # Configuration (optional)
├── README.md           # Documentation (optional)
├── data/               # Scenario data directory (required)
│   └── <scenario-name>/
│       ├── input.json      # Scenario input (required)
│       └── expected.json   # Expected output (required)
└── .tc-result          # Result file (generated, not version-controlled)
```

**Validation Rules**:
- `run` file MUST exist and be executable
- `data/` directory MUST exist
- At least one scenario MUST be present in `data/`
- All scenario directories MUST contain both `input.json` and `expected.json`

**Relationships**:
- HAS MANY Scenarios (1:N)
- PRODUCES ONE Result per execution (1:1 per run)

---

### 2. Test Scenario

A single test case within a suite, defined by input data and expected output.

**Attributes**:
- `name` (string, required): Scenario identifier (directory name under `data/`)
- `suite_path` (string, required): Parent suite path (for context)
- `input_file` (file path, required): Path to `input.json`
- `expected_file` (file path, required): Path to `expected.json`
- `input` (JSON object, loaded): Parsed input data
- `expected` (JSON object, loaded): Parsed expected output
- `status` (enum, runtime): Execution status
  - Values: `pending`, `running`, `pass`, `fail`, `error`, `timeout`
- `actual` (JSON object, runtime): Actual output from test runner
- `duration_ms` (integer, runtime): Execution time in milliseconds
- `diff` (object, runtime): Difference details for failed tests

**File Structure**:
```
data/<scenario-name>/
├── input.json          # Test input
└── expected.json       # Expected output
```

**Validation Rules**:
- Scenario name (directory name) MUST be unique within suite
- Both `input.json` and `expected.json` MUST be valid JSON
- Files MUST be readable

**Relationships**:
- BELONGS TO one Test Suite (N:1)
- PRODUCES one Scenario Result per execution (1:1 per run)

---

### 3. Test Run

An execution instance of one or more test suites, aggregating results and metadata.

**Attributes**:
- `run_id` (string, generated): Unique identifier for this run (timestamp-based)
- `timestamp` (timestamp, required): ISO 8601 start time
- `suites` (array of strings, required): List of suite paths included in run
- `mode` (enum, required): Execution mode
  - Values: `single` (one suite), `batch` (explicit list), `all` (discover all), `selective` (pattern match)
- `parallelism` (integer, required): Number of concurrent workers
- `total_scenarios` (integer, derived): Count of all scenarios across all suites
- `passed` (integer, runtime): Count of passed scenarios
- `failed` (integer, runtime): Count of failed scenarios
- `errors` (integer, runtime): Count of scenarios with execution errors
- `timeouts` (integer, runtime): Count of scenarios that timed out
- `duration_ms` (integer, runtime): Total execution time
- `status` (enum, runtime): Overall run status
  - Values: `running`, `success` (all passed), `failure` (any failed), `error` (execution issues)

**Transient Entity**: Run metadata exists only during execution and in summary output, not persisted to files.

**Relationships**:
- EXECUTES many Test Suites (1:N)
- AGGREGATES many Scenario Results (1:N)

---

### 4. Scenario Result

The outcome of executing a single test scenario.

**Attributes**:
- `suite` (string, required): Suite path
- `scenario` (string, required): Scenario name
- `status` (enum, required): Test outcome
  - Values: `pass`, `fail`, `error`, `timeout`
- `duration_ms` (integer, required): Execution time in milliseconds
- `timestamp` (timestamp, required): ISO 8601 execution time
- `expected` (JSON object, optional): Expected output (included if status=fail)
- `actual` (JSON object, optional): Actual output (included if status=fail or error)
- `diff` (object, optional): Structured difference (for failed tests)
  - Format: `{"field_path": {"expected": value, "actual": value}}`
- `error` (string, optional): Error message (for status=error or timeout)
- `comparison_mode` (enum, persisted): Comparison method used
  - Values: `semantic_json`, `whitespace_norm`, `fuzzy`
- `fuzzy_score` (float, optional): Similarity score if fuzzy comparison used (0.0-1.0)

**File Format**: JSONL (JSON Lines) in `.tc-result` file

**Example**:
```jsonl
{"suite":"user/login","scenario":"login-success","status":"pass","duration_ms":45,"timestamp":"2025-10-11T14:30:00Z","comparison_mode":"semantic_json"}
{"suite":"user/login","scenario":"login-fail","status":"fail","duration_ms":38,"timestamp":"2025-10-11T14:30:01Z","comparison_mode":"semantic_json","diff":{"error.code":{"expected":"invalid_credentials","actual":"auth_failed"}}}
{"suite":"user/login","scenario":"timeout-test","status":"timeout","duration_ms":5000,"timestamp":"2025-10-11T14:30:06Z","error":"Test runner exceeded 5000ms timeout"}
```

**Validation Rules**:
- All fields except optional ones MUST be present
- `status` MUST be valid enum value
- If `status=fail`, `diff` SHOULD be present
- If `status=error` or `status=timeout`, `error` MUST be present

**Relationships**:
- BELONGS TO one Test Scenario (N:1)
- BELONGS TO one Test Run (N:1)
- STORED IN one Test Suite result file (N:1)

---

### 5. Suite Configuration

Optional configuration overrides for a test suite.

**Attributes**:
- `timeout` (integer, optional): Timeout in seconds (default: 300)
- `comparison` (enum, optional): Comparison mode override (default: `semantic_json`)
  - Values: `semantic_json`, `whitespace_norm`, `fuzzy`
- `fuzzy_threshold` (float, optional): Fuzzy match threshold 0.0-1.0 (default: 0.9)
- `parallel` (boolean, optional): Allow parallel scenario execution within suite (default: true)
- `env` (object, optional): Environment variables to set for test runner

**File Format**: INI-style key=value in `.tc-config`

**Example**:
```ini
# .tc-config
timeout=600
comparison=fuzzy
fuzzy_threshold=0.85
parallel=true
env.DATABASE_URL=postgresql://localhost/test_db
env.API_KEY=test_key_12345
```

**Validation Rules**:
- All values must be parseable as specified types
- `timeout` must be positive integer
- `fuzzy_threshold` must be between 0.0 and 1.0
- Invalid keys are ignored with warning

**Relationships**:
- BELONGS TO one Test Suite (1:1)

---

## State Transitions

### Test Suite State Machine

```
[pending] --start--> [running] --complete--> [completed]
                              --error--> [error]
```

**Transitions**:
- `pending → running`: Suite execution begins
- `running → completed`: All scenarios executed successfully (may include failed tests)
- `running → error`: Fatal error prevents suite execution (missing runner, invalid config)

### Test Scenario State Machine

```
[pending] --start--> [running] --success--> [pass]
                              --mismatch--> [fail]
                              --crash--> [error]
                              --timeout--> [timeout]
```

**Transitions**:
- `pending → running`: Scenario execution begins (test runner invoked)
- `running → pass`: Output matches expected (per comparison mode)
- `running → fail`: Output doesn't match expected
- `running → error`: Test runner crashed, invalid JSON output, or file I/O error
- `running → timeout`: Test runner exceeded configured timeout

### Test Run State Machine

```
[running] --all_pass--> [success]
         --any_fail--> [failure]
         --fatal_error--> [error]
```

**Transitions**:
- `running → success`: All scenarios in all suites passed
- `running → failure`: One or more scenarios failed (but all executed)
- `running → error`: Fatal error prevented execution (no suites found, invalid paths)

---

## Data Flow

### Test Execution Flow

```
1. Discovery Phase
   User Command → Suite Discovery → Validate Suites → Load Configurations

2. Execution Phase
   For each suite (parallel):
     For each scenario (parallel if config allows):
       Load Input → Invoke Runner → Capture Output → Compare → Record Result

3. Reporting Phase
   Aggregate Results → Write .tc-result → Display Summary → Exit with Status
```

### File I/O Patterns

**Read Operations**:
- Suite discovery: Filesystem traversal
- Configuration: Read `.tc-config` (optional)
- Scenario data: Read `input.json` and `expected.json`
- Test runner output: Capture stdout (JSON)

**Write Operations**:
- Result persistence: Overwrite `.tc-result` (JSONL)
- Summary output: stdout (human-readable)
- Logs: stderr (streaming)

**Concurrency Considerations**:
- Multiple suites write to separate `.tc-result` files (no conflicts)
- Summary aggregation happens after all suites complete (wait for all)
- Parallel scenarios within a suite append to same result file (use file locking or sequential write)

---

## JSON Schemas

### Scenario Input/Output Format

Schema is user-defined - framework doesn't impose structure. Only requirement: valid JSON.

**Example**:
```json
{
  "username": "admin",
  "password": "secret123",
  "metadata": {
    "client": "web",
    "version": "1.0"
  }
}
```

### Result File Entry Schema

```json
{
  "suite": "string (required)",
  "scenario": "string (required)",
  "status": "pass|fail|error|timeout (required)",
  "duration_ms": "integer (required)",
  "timestamp": "ISO 8601 string (required)",
  "comparison_mode": "semantic_json|whitespace_norm|fuzzy (required)",
  "expected": "object (optional, present if status=fail)",
  "actual": "object (optional, present if status=fail or error)",
  "diff": "object (optional, present if status=fail)",
  "error": "string (optional, present if status=error or timeout)",
  "fuzzy_score": "float 0.0-1.0 (optional, present if comparison_mode=fuzzy)"
}
```

---

## Indexing & Queries

### Filesystem-Based Indexing

**Suite Discovery**:
- Walk directory tree from root path
- Identify directories containing `run` executable
- Validate required structure

**Scenario Discovery**:
- List subdirectories under `data/`
- Verify each contains `input.json` and `expected.json`

**No Database**: All data stored in files, discovered on-demand

### Query Operations

**Find all suites**: Filesystem traversal with validation
**Find scenarios in suite**: List `data/` subdirectories
**Get last result**: Read `.tc-result` file (already aggregated per suite)
**Filter by status**: Parse JSONL, filter by `status` field (client-side)

---

## Summary

| Entity | Storage | Format | Cardinality |
|--------|---------|--------|-------------|
| Test Suite | Directory | Filesystem | N per project |
| Test Scenario | Directory + JSON files | JSON | N per suite |
| Test Run | Transient | Memory | 1 per execution |
| Scenario Result | `.tc-result` file | JSONL | N per suite (overwritten) |
| Suite Config | `.tc-config` file | INI | 1 per suite (optional) |

**Key Design Principles**:
- File-based, no database required
- Self-contained suites (portable)
- Simple formats (JSON, JSONL, INI)
- Overwrite results per run (no history accumulation)
- Discoverable via filesystem traversal

