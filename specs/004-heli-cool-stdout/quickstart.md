# Quickstart: Heli-Cool Stdout

**Feature**: Animated single-line test runner output
**For**: Developers using TC test framework

## What This Feature Does

Transforms TC's test output from scrolling multi-line text to a clean, animated single-line status that updates in place. Think modern build tools like webpack, cargo, npm - tests are now just as slick.

**Before** (scrolling spam):
```
[2025-10-13 09:00:00] INFO: running suite: tests/my-feature
[2025-10-13 09:00:00] INFO: executing suite: tests/my-feature
[2025-10-13 09:00:00] INFO: found 10 scenario(s)
09:00:00   scenario-1... ✓
09:00:01   scenario-2... ✓
09:00:02   scenario-3... ✓
... (scrolls off screen)
```

**After** (single updating line):
```
🚁 : RUNNING : tests/my-feature/scenario-3 : ...
```

*Line updates in place, no scrolling. Animation at the end cycles through dots or spinner.*

## Quick Start

### 1. Just Run Tests Normally

No changes needed! The feature auto-detects if your terminal supports fancy output:

```bash
tc run tests --all
```

If you're in a terminal (TTY), you'll see the animated status line. If piped to a file or running in CI, you get clean plain text.

### 2. See Detailed Logs

Want machine-readable logs for analysis or CI integration?

```bash
tc run tests --all
cat .tc-reports/report.jsonl
```

Or use `jq` to filter:

```bash
# Show only failed tests
jq 'select(.status == "fail")' .tc-reports/report.jsonl

# Show tests slower than 100ms
jq 'select(.duration_ms > 100)' .tc-reports/report.jsonl

# Summary stats
jq -s 'group_by(.status) | map({status: .[0].status, count: length})' .tc-reports/report.jsonl
```

### 3. Customize Behavior

**Disable fancy output** (force plain text):
```bash
TC_FANCY_OUTPUT=false tc run tests --all
```

**Change log location**:
```bash
TC_REPORT_DIR=/tmp/my-logs tc run tests --all
```

**Disable colors** (standard convention):
```bash
NO_COLOR=1 tc run tests --all
```

## For CI/CD

The feature automatically detects non-TTY environments and outputs clean plain text:

```yaml
# GitHub Actions, GitLab CI, Jenkins, etc.
- name: Run tests
  run: tc run tests --all

# Logs are automatically plain text, no ANSI codes
# Detailed JSONL logs available in .tc-reports/report.jsonl
```

## Understanding the Status Line

```
🚁 : RUNNING : tests/my-feature/scenario-3 : ...
│    │         │                             │
│    │         │                             └─ Animation (dots/spinner)
│    │         └─────────────────────────────── Current test path
│    └───────────────────────────────────────── Status (RUNNING/PASSED/FAILED)
└────────────────────────────────────────────── Helicopter indicator
```

**Colors**:
- 🟡 **RUNNING** (yellow) - Tests in progress
- 🟢 **PASSED** (green) - All tests succeeded
- 🔴 **FAILED** (red) - Some tests failed

## JSONL Log Format

Each test produces one log entry:

```json
{
  "timestamp": "2025-10-13T09:00:00Z",
  "suite_path": "tests/my-feature",
  "test_name": "scenario-1",
  "status": "pass",
  "duration_ms": 45
}
```

For failures, an `error` field is included:

```json
{
  "timestamp": "2025-10-13T09:00:01Z",
  "suite_path": "tests/my-feature",
  "test_name": "scenario-2",
  "status": "fail",
  "duration_ms": 120,
  "error": "Expected 5, got 3"
}
```

## Troubleshooting

### Status line not animating

**Problem**: Text appears but doesn't update in place

**Solutions**:
- Check if terminal supports ANSI codes: `echo $TERM` (should be xterm, screen, or similar)
- Force fancy output: `TC_FANCY_OUTPUT=true tc run tests --all`
- Try a different terminal emulator

### Colors not showing

**Problem**: Status line appears but no colors

**Solutions**:
- Check `$NO_COLOR` is not set: `echo $NO_COLOR`
- Verify terminal supports 256 colors: `tput colors`
- Try explicit color mode: `export COLORTERM=truecolor`

### Log file not created

**Problem**: `.tc-reports/report.jsonl` doesn't exist

**Solutions**:
- Check directory is writable: `ls -ld .tc-reports`
- Check for errors in stderr output
- Try explicit directory: `mkdir .tc-reports && tc run tests --all`

### Plain text in terminal

**Problem**: Expected fancy output but getting plain text

**Solutions**:
- Verify stdout is a TTY: `[ -t 1 ] && echo "TTY" || echo "not TTY"`
- Check if running through a pipe or redirection
- Force fancy output: `TC_FANCY_OUTPUT=true tc run tests --all`

## Advanced Usage

### Multiple Test Runs

Logs accumulate across runs (JSONL format):

```bash
tc run tests/suite1 --all
tc run tests/suite2 --all
# Both runs logged to same file
jq -s '.' .tc-reports/report.jsonl  # View as JSON array
```

### Custom Log Analysis

**Count tests by suite**:
```bash
jq -s 'group_by(.suite_path) | map({suite: .[0].suite_path, count: length})' .tc-reports/report.jsonl
```

**Find slowest tests**:
```bash
jq -s 'sort_by(.duration_ms) | reverse | .[0:10]' .tc-reports/report.jsonl
```

**Calculate pass rate**:
```bash
jq -s '{total: length, passed: map(select(.status == "pass")) | length} | {total, passed, rate: ((.passed / .total) * 100)}' .tc-reports/report.jsonl
```

### Disable Animation Only

Keep colors but disable spinner:

```bash
TC_NO_ANIMATION=1 tc run tests --all
```

## Integration Examples

### Git Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

TC_FANCY_OUTPUT=false tc run tests --all > /tmp/tc-precommit.log 2>&1
if [ $? -ne 0 ]; then
    cat /tmp/tc-precommit.log
    echo "Tests failed! Commit aborted."
    exit 1
fi
```

### CI Pipeline with Artifacts

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: tc run tests --all

- name: Upload test logs
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: test-logs
    path: .tc-reports/report.jsonl
```

### Watch Mode (with entr)

```bash
# Re-run tests on file changes
ls tc/lib/**/*.sh tests/**/* | entr -c tc run tests --all
```

## Summary

- **Zero configuration** - fancy output works out of the box in terminals
- **CI-friendly** - auto-detects non-TTY and outputs plain text
- **Machine-readable logs** - JSONL format for easy parsing
- **Customizable** - environment variables for fine-tuning
- **Backwards compatible** - existing TC scripts work unchanged

Enjoy your fancy helicopter vibes! 🚁
