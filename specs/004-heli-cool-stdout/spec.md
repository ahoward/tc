# Feature Specification: Heli-Cool Stdout - Animated Test Runner Output

**Feature Branch**: `004-heli-cool-stdout`
**Created**: 2025-10-13
**Status**: Draft
**Input**: User description: "heli-cool stdout: single status line with animating helicopters and shit for test runners"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Real-Time Test Status with Single-Line Updates (Priority: P1) 🎯 MVP

A developer runs their test suite and sees a clean, single-line status that updates in real-time, showing current progress without scrolling spam.

**Why this priority**: Core functionality - without the single updating status line, there's no feature. This is the fundamental improvement over traditional multi-line output.

**Independent Test**: Run `tc run tests --all` in a TTY and verify that only one line updates with test progress, replacing itself rather than creating new lines.

**Acceptance Scenarios**:

1. **Given** tests are running in a TTY terminal, **When** tc executes test suites, **Then** output displays on a single line that updates in place
2. **Given** tests are running, **When** each test completes, **Then** the status line updates to show current progress without creating new lines
3. **Given** test suite completes, **When** all tests finish, **Then** final summary appears as clean multi-line output

---

### User Story 2 - Visual Test Status Indicators (Priority: P2)

A developer glances at their terminal and immediately understands test status through color-coded visual indicators and emoji markers.

**Why this priority**: Enhances usability - makes status instantly recognizable but not required for basic functionality.

**Independent Test**: Run tests and verify status line includes: single-char emoji (🚁), colored label showing status (RUNNING/PASSED/FAILED), and test progress indicators.

**Acceptance Scenarios**:

1. **Given** tests are running, **When** user views terminal, **Then** status line shows format: `🚁 : RUNNING : [suite-name] : animated-indicator`
2. **Given** tests pass, **When** suite completes successfully, **Then** status shows green PASSED label with ✓ markers
3. **Given** tests fail, **When** suite has failures, **Then** status shows red FAILED label with ✗ markers
4. **Given** test execution, **When** status updates, **Then** animation varies only at the end (growing/shrinking dots or spinner)

---

### User Story 3 - Machine-Readable Detailed Logs (Priority: P3)

A developer or CI system needs detailed test execution data for analysis, debugging, or integration with other tools.

**Why this priority**: Important for automation and debugging but not required for interactive development workflow.

**Independent Test**: Run tests and verify that detailed execution logs are written to `report.json` or similar location, parseable by standard JSON tools.

**Acceptance Scenarios**:

1. **Given** tests are running, **When** tc executes test suites, **Then** detailed logs are written to persistent location (e.g., `.tc-reports/report.jsonl`)
2. **Given** log file exists, **When** viewing log entries, **Then** each entry includes: timestamp, suite path, test name, status, duration
3. **Given** log format, **When** processing with standard tools, **Then** logs are parseable as JSONL (one JSON object per line)
4. **Given** multiple test runs, **When** viewing logs, **Then** entries are appendable and filterable using same strategy as tc's multi-input tests

---

### User Story 4 - Graceful Non-TTY Fallback (Priority: P2)

A developer runs tests in CI/CD or redirected to a file, and gets clean line-oriented output without ANSI escape codes breaking logs.

**Why this priority**: Critical for CI/CD integration - without this, the feature could break automation pipelines.

**Independent Test**: Run `tc run tests --all > output.txt` and verify output contains plain text without ANSI codes, one status update per line.

**Acceptance Scenarios**:

1. **Given** stdout is not a TTY (piped/redirected), **When** tc runs tests, **Then** output is line-oriented without ANSI escape codes
2. **Given** non-TTY output, **When** tests progress, **Then** each status change produces a new line (not in-place updates)
3. **Given** non-TTY output, **When** viewing logs, **Then** output is clean ASCII text suitable for log files and CI systems

---

### Edge Cases

- What happens when terminal width is very narrow (< 40 chars)?
  - Status line truncates gracefully, showing most important info (emoji + status + current test)
- How does system handle SIGWINCH (terminal resize) during test execution?
  - Status line adapts to new width on next update
- What happens when test suite name is extremely long?
  - Suite name truncates with ellipsis (...) to fit within uniform width section
- How does output handle terminal that doesn't support colors?
  - Falls back to plain text with ASCII markers (*, +, x) instead of emoji
- What happens if report.json already exists?
  - Appends new entries (JSONL format naturally supports this)
- How does system detect if stdout is a TTY?
  - Standard `isatty()` / `[ -t 1 ]` check

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect if stdout is a TTY and enable fancy animated output only for TTY sessions
- **FR-002**: System MUST display test progress on a single line that updates in place (using CR + line rewrite) when stdout is a TTY
- **FR-003**: System MUST format status line as: `[emoji] : [COLORED-LABEL] : [uniform-width-info] : [variable-width-animation]`
- **FR-004**: System MUST use ANSI color codes for status labels: green for PASSED, red for FAILED, yellow for RUNNING
- **FR-005**: System MUST animate only the rightmost portion of the status line (dots, spinner, or similar)
- **FR-006**: System MUST output plain ASCII text without ANSI codes when stdout is not a TTY
- **FR-007**: System MUST write detailed execution logs to persistent storage in machine-readable format
- **FR-008**: System MUST write logs as JSONL (JSON Lines) format for streamability and filterability
- **FR-009**: System MUST include in each log entry: timestamp, suite_path, test_name, status, duration_ms
- **FR-010**: System MUST write log file to `.tc-reports/` directory by default (configurable via environment variable)
- **FR-011**: System MUST maintain uniform width for non-animated portions of status line to prevent visual jitter
- **FR-012**: System MUST use helicopter emoji (🚁) as the status line prefix marker
- **FR-013**: System MUST handle terminal width gracefully, truncating suite names if needed to fit status line
- **FR-014**: System MUST restore cursor and clear line on test completion before printing final summary

### Key Entities

- **Status Line**: Real-time single-line output showing current test execution state
  - Emoji indicator (🚁)
  - Status label (RUNNING/PASSED/FAILED)
  - Current test context (suite name, test name)
  - Animation component (variable-width trailing indicator)

- **Log Entry**: Machine-readable record of test execution event
  - Timestamp (ISO 8601)
  - Suite path (relative or absolute)
  - Test name (scenario name)
  - Status (pass/fail/error)
  - Duration in milliseconds
  - Optional error details

- **Output Mode**: Runtime determination of output format
  - TTY mode (fancy, animated, colored)
  - Non-TTY mode (plain, line-oriented, no colors)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can monitor test progress without scrolling - status updates stay within visible terminal viewport
- **SC-002**: Test status is visually identifiable within 1 second of glancing at terminal (through colors and emoji)
- **SC-003**: Detailed logs are machine-parseable and filterable using standard JSON tools (jq, grep, etc.)
- **SC-004**: Status line output works correctly in 95% of common terminal emulators (tested: bash, zsh, tmux, screen, vscode terminal, iterm2, gnome-terminal)
- **SC-005**: Non-TTY output is clean enough for CI logs - no escape codes, no formatting artifacts
- **SC-006**: Log file accumulates test runs without corruption - JSONL format allows safe append operations

## Assumptions

- Developers primarily run tests in terminal environments with ANSI color support
- Standard POSIX TTY detection (`test -t 1`) is sufficient for TTY/non-TTY determination
- Test execution is serial (one test at a time) - parallel execution would require multiple status lines or different approach
- Terminal width is at least 40 characters for reasonable display
- Log file location `.tc-reports/` is acceptable default (can be overridden with TC_REPORT_DIR environment variable)
- JSONL format is familiar to developers or documentation will explain how to parse it
- Helicopter emoji (🚁) renders correctly in developer terminals (fallback to ASCII 'tc' if needed)

## Dependencies

- Existing TC test execution framework (tc_execute_suite, tc_run_all_suites)
- ANSI escape code support in target terminals (for TTY mode)
- jq or similar JSON processing tools (for users wanting to parse logs, not required for tc itself)

## Out of Scope

- Multiple simultaneous status lines for parallel test execution
- Interactive controls (pause/resume tests from keyboard)
- Graphical UI or web dashboard for test results
- Real-time streaming of logs to remote services
- Historical test result comparison
- Test failure screenshots or artifacts
- Integration with specific CI/CD platforms (should work generically)
