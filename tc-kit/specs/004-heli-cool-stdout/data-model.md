# Data Model: Heli-Cool Stdout

**Feature**: Animated single-line test runner output
**Date**: 2025-10-13

## Core Entities

### Status Line State

Represents the current state of the animated status line display.

**Attributes**:
- `mode`: string - "tty" or "non-tty" (determined at runtime)
- `current_suite`: string - Name of currently executing test suite
- `current_test`: string - Name of currently executing test scenario
- `tests_passed`: integer - Count of passed tests in current run
- `tests_failed`: integer - Count of failed tests in current run
- `tests_total`: integer - Total tests executed so far
- `animation_frame`: integer - Current animation frame index (0-N)
- `status_label`: string - "RUNNING", "PASSED", or "FAILED"
- `terminal_width`: integer - Current terminal column width

**State Transitions**:
```
INIT → RUNNING (on suite start)
RUNNING → RUNNING (on each test completion, updates counts)
RUNNING → PASSED (on suite success, no failures)
RUNNING → FAILED (on suite completion with failures)
```

**Validation Rules**:
- `mode` must be one of: "tty", "non-tty"
- `status_label` must be one of: "RUNNING", "PASSED", "FAILED"
- `tests_passed`, `tests_failed`, `tests_total` must be non-negative integers
- `tests_total` must equal `tests_passed + tests_failed`
- `terminal_width` must be >= 40 (minimum usable width)

---

### Log Entry

Represents a single test execution event in the machine-readable log.

**Attributes**:
- `timestamp`: string - ISO 8601 timestamp (UTC)
- `suite_path`: string - Relative or absolute path to test suite
- `test_name`: string - Test scenario name (from data/ directory)
- `status`: string - "pass", "fail", or "error"
- `duration_ms`: integer - Test execution time in milliseconds
- `error`: string (optional) - Error message if status is "fail" or "error"

**Relationships**:
- Multiple log entries belong to one test run
- Log entries are ordered by timestamp
- Each log entry corresponds to one test scenario execution

**Validation Rules**:
- `timestamp` must be valid ISO 8601 format
- `suite_path` must be non-empty string
- `test_name` must be non-empty string
- `status` must be one of: "pass", "fail", "error"
- `duration_ms` must be non-negative integer
- `error` field present only if status is "fail" or "error"

**Storage Format**: JSONL (one JSON object per line)

**Example**:
```json
{"timestamp":"2025-10-13T09:00:00Z","suite_path":"tests/my-feature","test_name":"scenario-1","status":"pass","duration_ms":45}
{"timestamp":"2025-10-13T09:00:01Z","suite_path":"tests/my-feature","test_name":"scenario-2","status":"fail","duration_ms":120,"error":"Expected 5, got 3"}
```

---

### Output Configuration

Represents runtime configuration for output behavior.

**Attributes**:
- `fancy_output_enabled`: boolean - Enable fancy TTY output (default: auto-detect)
- `report_dir`: string - Directory for JSONL log files (default: ".tc-reports")
- `log_file_name`: string - Name of log file (default: "report.jsonl")
- `animation_enabled`: boolean - Enable animation in fancy mode (default: true)
- `color_enabled`: boolean - Enable ANSI colors (default: true in TTY)

**Source**: Environment variables and defaults
- `TC_FANCY_OUTPUT` → `fancy_output_enabled` (override auto-detect)
- `TC_REPORT_DIR` → `report_dir`
- `TC_LOG_FILE` → `log_file_name`
- `TC_NO_ANIMATION` → disables `animation_enabled`
- `TC_NO_COLOR` or `NO_COLOR` → disables `color_enabled`

**Validation Rules**:
- `report_dir` must be writable path
- `log_file_name` must be valid filename
- Boolean fields must be "true" or "false" (or unset for default)

---

### ANSI Color Palette

Represents color coding for status labels.

**Color Mappings**:
- `RUNNING` → Yellow (`\033[0;33m`)
- `PASSED` → Green (`\033[0;32m`)
- `FAILED` → Red (`\033[0;31m`)
- `RESET` → Reset to default (`\033[0m`)

**Additional Colors** (for future use):
- Blue (`\033[0;34m`) - Info messages
- Magenta (`\033[0;35m`) - Warnings
- Cyan (`\033[0;36m`) - Debug output

**Validation Rules**:
- Only applied in TTY mode with color support
- Disabled if `NO_COLOR` environment variable set
- Must always include RESET after colored output

---

## Data Flow

### TTY Mode (Fancy Output)

```
Test Event → Status Line State Update → Format Status Line → ANSI Output → Terminal
     ↓
Log Entry Creation → JSONL Append → .tc-reports/report.jsonl
```

### Non-TTY Mode (Plain Output)

```
Test Event → Format Plain Status → Plain Text Output → stdout/log file
     ↓
Log Entry Creation → JSONL Append → .tc-reports/report.jsonl
```

### Log File Structure

```
.tc-reports/
└── report.jsonl    # Append-only JSONL file
    ├── Entry 1 (test 1, pass)
    ├── Entry 2 (test 2, fail)
    ├── Entry 3 (test 3, pass)
    └── ... (continues for each test)
```

**Append Strategy**: Each test completion writes one line immediately (buffering disabled for real-time observability).

---

## State Management

### Global State Variables (Bash)

```bash
# Status line state
TC_STATUS_MODE="tty"              # or "non-tty"
TC_CURRENT_SUITE=""
TC_CURRENT_TEST=""
TC_TESTS_PASSED=0
TC_TESTS_FAILED=0
TC_TESTS_TOTAL=0
TC_ANIMATION_FRAME=0
TC_STATUS_LABEL="RUNNING"
TC_TERMINAL_WIDTH=80

# Configuration
TC_FANCY_OUTPUT=""                # auto-detect if empty
TC_REPORT_DIR=".tc-reports"
TC_LOG_FILE="report.jsonl"
TC_ANIMATION_ENABLED="true"
TC_COLOR_ENABLED="true"
```

### Initialization Sequence

1. Detect TTY mode (`[ -t 1 ]`)
2. Load configuration from environment
3. Initialize status line state
4. Create report directory if needed
5. Hide cursor (TTY mode only)

### Cleanup Sequence

1. Show cursor (TTY mode only)
2. Print final summary
3. Flush any buffered log entries
4. Reset terminal state

---

## Persistence

**Log Files**: 
- Format: JSONL (JSON Lines)
- Location: `.tc-reports/report.jsonl` (configurable)
- Mode: Append-only
- Encoding: UTF-8
- Line terminator: `\n` (LF)

**No Database**: All state is ephemeral (in-memory during test run), only logs persist.

**Log Rotation**: Not implemented - users can manually archive/rotate logs as needed. Future enhancement could add automatic rotation based on size or date.
