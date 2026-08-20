# Shell Function Contracts: Heli-Cool Stdout

This document defines the shell function interfaces (contracts) for the animated output feature.

## Module: tc/lib/utils/ansi.sh

### tc_ansi_supported()

**Purpose**: Detect if terminal supports ANSI escape codes

**Inputs**: None

**Outputs**:
- Exit code 0 if ANSI supported
- Exit code 1 if not supported

**Side Effects**: None

**Usage**:
```bash
if tc_ansi_supported; then
    echo "Terminal supports colors"
fi
```

**Detection Logic**:
- Check if stdout is TTY (`[ -t 1 ]`)
- Check `$TERM` variable (reject "dumb", accept xterm/vt100/screen variants)
- Check `$NO_COLOR` is not set

---

### tc_ansi_color(code)

**Purpose**: Output ANSI color code

**Inputs**:
- `$1`: Color name ("green", "red", "yellow", "reset")

**Outputs**:
- stdout: ANSI escape sequence
- Exit code 0 on success

**Side Effects**: None

**Usage**:
```bash
printf "$(tc_ansi_color green)PASSED$(tc_ansi_color reset)\n"
```

---

### tc_ansi_clear_line()

**Purpose**: Output ANSI code to clear current line

**Inputs**: None

**Outputs**:
- stdout: `\033[2K` escape sequence
- Exit code 0

**Side Effects**: None

---

### tc_ansi_hide_cursor() / tc_ansi_show_cursor()

**Purpose**: Hide/show terminal cursor

**Inputs**: None

**Outputs**:
- stdout: ANSI cursor visibility codes
- Exit code 0

**Side Effects**: Changes terminal cursor visibility

---

## Module: tc/lib/utils/status-line.sh

### tc_status_init()

**Purpose**: Initialize status line system

**Inputs**: None

**Outputs**:
- Exit code 0 on success
- Sets global variables (TC_STATUS_MODE, TC_TERMINAL_WIDTH, etc.)

**Side Effects**:
- Detects TTY mode
- Hides cursor if TTY
- Initializes state variables

**Usage**:
```bash
tc_status_init
```

---

### tc_status_update(suite, test, status, passed, failed)

**Purpose**: Update status line with current test information

**Inputs**:
- `$1`: Suite name
- `$2`: Test name
- `$3`: Status ("running", "passed", "failed")
- `$4`: Tests passed count
- `$5`: Tests failed count

**Outputs**:
- stdout: Formatted status line (TTY: in-place, non-TTY: new line)
- Exit code 0 on success

**Side Effects**:
- Updates global status state
- Advances animation frame
- Writes to terminal

**Usage**:
```bash
tc_status_update "my-suite" "test-1" "running" 5 2
```

---

### tc_status_finish(passed, failed)

**Purpose**: Finalize status line and print summary

**Inputs**:
- `$1`: Total tests passed
- `$2`: Total tests failed

**Outputs**:
- stdout: Final summary (multi-line)
- Exit code 0 if all passed, 1 if any failed

**Side Effects**:
- Shows cursor if TTY
- Clears status line
- Prints final report

**Usage**:
```bash
tc_status_finish 10 2
```

---

### tc_terminal_width()

**Purpose**: Get current terminal width

**Inputs**: None

**Outputs**:
- stdout: Integer width in columns
- Exit code 0

**Side Effects**: None

**Usage**:
```bash
width=$(tc_terminal_width)
```

---

## Module: tc/lib/utils/log-writer.sh

### tc_log_init()

**Purpose**: Initialize log file system

**Inputs**: None

**Outputs**:
- Exit code 0 on success
- Exit code 1 if log directory cannot be created

**Side Effects**:
- Creates `.tc-reports/` directory if needed
- Sets TC_LOG_FILE_PATH global variable

**Usage**:
```bash
tc_log_init || tc_error "Failed to initialize logging"
```

---

### tc_log_write(suite_path, test_name, status, duration_ms, error?)

**Purpose**: Write test result to JSONL log

**Inputs**:
- `$1`: Suite path
- `$2`: Test name
- `$3`: Status ("pass", "fail", "error")
- `$4`: Duration in milliseconds
- `$5`: Error message (optional, for fail/error status)

**Outputs**:
- Exit code 0 on success
- Exit code 1 on write failure
- stderr: Error message if write fails

**Side Effects**:
- Appends one line to log file
- Creates log file if it doesn't exist

**Usage**:
```bash
tc_log_write "tests/my-feature" "scenario-1" "pass" 45
tc_log_write "tests/my-feature" "scenario-2" "fail" 120 "Expected 5, got 3"
```

**Output Format**:
```json
{"timestamp":"2025-10-13T09:00:00Z","suite_path":"tests/my-feature","test_name":"scenario-1","status":"pass","duration_ms":45}
```

---

### tc_log_get_path()

**Purpose**: Get current log file path

**Inputs**: None

**Outputs**:
- stdout: Absolute path to log file
- Exit code 0

**Side Effects**: None

**Usage**:
```bash
log_path=$(tc_log_get_path)
echo "Logs written to: $log_path"
```

---

## Integration Points

### tc/lib/core/executor.sh Updates

**Function**: `tc_execute_suite(suite_dir)`

**Integration Points**:
1. After suite discovery: `tc_status_update "$suite_name" "" "running" 0 0`
2. Before each test: `tc_status_update "$suite_name" "$test_name" "running" $passed $failed`
3. After each test: 
   ```bash
   tc_log_write "$suite_dir" "$test_name" "$status" "$duration_ms" "$error"
   tc_status_update "$suite_name" "$test_name" "$final_status" $passed $failed
   ```
4. After suite completion: `tc_status_finish $passed $failed`

---

### tc/lib/utils/reporter.sh Updates

**Function**: `tc_report_suite(suite_path, passed, failed, errors, results...)`

**Changes**:
- Detect if status line is active (TTY mode)
- If TTY: Skip individual test result lines (already shown in status line)
- If non-TTY: Keep existing multi-line output
- Always print final summary

---

## Environment Variable Contracts

### TC_FANCY_OUTPUT

**Type**: Boolean string ("true" or "false") or unset
**Default**: Auto-detect based on TTY
**Purpose**: Force enable/disable fancy output

**Example**:
```bash
TC_FANCY_OUTPUT=false tc run tests --all  # Force plain output
```

---

### TC_REPORT_DIR

**Type**: String (directory path)
**Default**: ".tc-reports"
**Purpose**: Specify where to write log files

**Example**:
```bash
TC_REPORT_DIR=/tmp/tc-logs tc run tests --all
```

---

### TC_LOG_FILE

**Type**: String (filename)
**Default**: "report.jsonl"
**Purpose**: Specify log filename within TC_REPORT_DIR

---

### NO_COLOR

**Type**: Presence check (any value disables color)
**Default**: unset (colors enabled)
**Purpose**: Disable ANSI colors (standard convention)

**Example**:
```bash
NO_COLOR=1 tc run tests --all
```

---

## Error Handling

All functions follow these error handling conventions:

1. **Return Codes**:
   - 0 = Success
   - 1 = Failure

2. **Error Messages**:
   - Written to stderr
   - Prefixed with "ERROR: " or "WARNING: "

3. **Fallback Behavior**:
   - TTY detection fails → use non-TTY mode
   - Log write fails → warn to stderr, continue execution
   - Terminal width detection fails → use 80 columns
   - ANSI codes not supported → fallback to plain ASCII

4. **Fatal vs Non-Fatal**:
   - Fatal: Cannot initialize log directory (exit 1)
   - Non-Fatal: Log write failure (warn and continue)
   - Non-Fatal: Status line rendering issues (fallback to plain)
