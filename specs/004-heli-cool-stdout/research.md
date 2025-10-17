# Research: Heli-Cool Stdout

**Feature**: Animated single-line test runner output
**Date**: 2025-10-13
**Status**: Complete

## Research Questions

### Q1: TTY Detection in POSIX Shell

**Decision**: Use `test -t 1` (or `[ -t 1 ]`) for stdout TTY detection

**Rationale**:
- POSIX standard, works across bash, zsh, sh
- File descriptor 1 is stdout
- Returns 0 (true) if FD is a terminal, 1 (false) otherwise
- Zero dependencies, built into shell

**Alternatives considered**:
- `tty -s`: Works but less direct, checks stdin by default
- `/dev/tty` check: File-based, less reliable across environments
- `isatty()` C function: Would require compiled binary

**Example usage**:
```bash
if [ -t 1 ]; then
    # TTY mode: fancy output
    echo "🚁 Fancy status line..."
else
    # Non-TTY mode: plain output
    echo "Plain text output"
fi
```

### Q2: ANSI Escape Codes for In-Place Updates

**Decision**: Use CR (`\r`) + line rewrite for single-line updates, with ANSI color codes

**Rationale**:
- Carriage return (`\r` or `\033[0G`) moves cursor to line start
- Rewriting line content updates in-place without scrolling
- ANSI color codes widely supported (xterm, vt100 compatible)
- Clear line with `\033[2K` to prevent artifacts from shorter updates

**Key ANSI codes**:
```bash
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Cursor control
CR='\r'              # Carriage return
CLEAR_LINE='\033[2K' # Clear entire line
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

# Example
printf "\r\033[2K${GREEN}✓${RESET} Test passed"
```

**Alternatives considered**:
- `tput` commands: More portable but requires ncurses, slower
- VT100 sequences only: Less color support
- Unicode box drawing: Overkill for status line

### Q3: Terminal Width Detection

**Decision**: Use `tput cols` with fallback to 80

**Rationale**:
- `tput cols` queries terminfo database for current width
- Handles SIGWINCH (terminal resize) naturally on next query
- Fallback to 80 chars if tput unavailable or fails
- Graceful degradation for edge cases

**Implementation**:
```bash
tc_terminal_width() {
    local width=$(tput cols 2>/dev/null)
    echo "${width:-80}"
}
```

**Alternatives considered**:
- `$COLUMNS` env var: Not always set, not updated on resize
- `stty size`: Returns rows + columns, requires parsing
- Fixed width: Inflexible across terminal sizes

### Q4: Animation Strategies

**Decision**: Rotating dots with fixed positions (simple spinner)

**Rationale**:
- Low CPU overhead (string replacement, not rendering)
- Works with any animation speed (controlled by test execution)
- No frame timing needed - update on each test event
- Fits "animation varies only at end" requirement from spec

**Implementation**:
```bash
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
SPINNER_IDX=0

tc_next_spinner() {
    echo "${SPINNER_FRAMES[$SPINNER_IDX]}"
    SPINNER_IDX=$(( (SPINNER_IDX + 1) % ${#SPINNER_FRAMES[@]} ))
}

# Or simpler dot animation:
DOT_COUNT=0
tc_animate_dots() {
    local dots=$(printf '.%.0s' $(seq 1 $DOT_COUNT))
    echo "$dots"
    DOT_COUNT=$(( (DOT_COUNT + 1) % 4 ))
}
```

**Alternatives considered**:
- Progress bars: Requires knowing total test count upfront
- Percentage completion: Same issue, plus more complex calculation
- Rotating helicopter: Cool but harder to render in ASCII

### Q5: JSONL Log Format

**Decision**: One JSON object per line, append-only writes

**Rationale**:
- Streamable - can parse incomplete files line-by-line
- No array wrapping needed (unlike JSON array)
- Safe for concurrent writes (each line is atomic)
- Standard format, works with `jq -s` for aggregation

**Schema**:
```json
{"timestamp":"2025-10-13T09:00:00Z","suite":"tests/my-feature","test":"scenario-1","status":"pass","duration_ms":45}
{"timestamp":"2025-10-13T09:00:01Z","suite":"tests/my-feature","test":"scenario-2","status":"fail","duration_ms":120,"error":"Expected 5, got 3"}
```

**Alternatives considered**:
- JSON array: Requires parsing entire file, not streamable
- CSV: Less structured, harder to add optional fields
- Plain text logs: Not machine-parseable

### Q6: Log File Location

**Decision**: `.tc-reports/report.jsonl` (configurable via `TC_REPORT_DIR`)

**Rationale**:
- Hidden directory (`.tc-reports`) keeps repo clean
- Single file per test run avoids clutter
- Environment variable override for CI/CD custom paths
- Append mode allows multiple runs to accumulate

**Alternatives considered**:
- `/tmp`: Lost on reboot, harder to find
- `~/.tc/logs`: Global location, harder to share with team
- Timestamped files: Clutters directory, requires cleanup

### Q7: Performance Overhead

**Decision**: Minimize `printf` calls, batch string construction

**Rationale**:
- Shell `printf` to terminal is fast (<1ms)
- String concatenation in bash is cheap
- Only update status line on test completion events, not continuously
- Skip animation frames if tests complete too quickly (<100ms each)

**Measurement strategy**:
```bash
# Time sensitive section
START=$(date +%s%N)
tc_update_status_line "..."
END=$(date +%s%N)
ELAPSED=$(( (END - START) / 1000000 ))  # Convert to ms
[ $ELAPSED -gt 50 ] && tc_log "WARNING: Status update took ${ELAPSED}ms"
```

**Alternatives considered**:
- Background process for animation: Adds complexity, harder to synchronize
- Buffering updates: Could miss rapid test completions

## Key Implementation Decisions

### Module Responsibilities

**tc/lib/utils/ansi.sh**:
- Color code constants
- Cursor control functions
- Terminal capability detection

**tc/lib/utils/status-line.sh**:
- TTY detection
- Status line formatting
- Animation state management
- Terminal width handling

**tc/lib/utils/log-writer.sh**:
- JSONL file operations
- Log entry formatting
- Directory creation (.tc-reports/)

**tc/lib/core/executor.sh** (updated):
- Call status line updates at test lifecycle events
- Integrate log writer for detailed records

**tc/lib/utils/reporter.sh** (updated):
- Detect TTY mode
- Delegate to status-line module if TTY
- Keep existing multi-line output if non-TTY

### Integration Points

1. **Before suite execution**: Initialize status line, hide cursor (TTY only)
2. **On test start**: Update status with current test name
3. **On test complete**: Update with result, increment animation
4. **After suite complete**: Show cursor, print final summary
5. **Every test event**: Write JSONL log entry

### Fallback Strategy

- TTY detection fails → default to non-TTY mode
- ANSI codes not supported → detect via `$TERM` variable, fallback to plain ASCII
- tput unavailable → use 80 column width
- Log write fails → continue execution, warn to stderr

## References

- POSIX Shell TTY detection: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/test.html
- ANSI escape codes: https://en.wikipedia.org/wiki/ANSI_escape_code
- JSONL format spec: https://jsonlines.org/
- Bash printf formatting: `man bash` section on printf
