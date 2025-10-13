# CLI Contract: TC Source Layout Refactoring

**Feature**: TC Source Layout Refactoring
**Version**: 1.0.0
**Date**: 2025-10-12

## Overview

This contract defines the command-line interface for the TC framework. **CRITICAL**: This refactoring maintains 100% CLI compatibility - all commands, flags, and behaviors remain identical.

---

## Command Interface (UNCHANGED)

### Test Execution Commands

#### `tc run <suite-path>`

**Syntax**: `tc run <suite-path>`

**Description**: Run a single test suite

**Examples**:
```bash
tc run examples/hello-world
tc run tests/auth/login
tc run ./my-test-suite
```

**Exit Codes**:
- `0` - All tests passed
- `1` - One or more tests failed or errored

**Output**: Human-readable test results to stdout

---

#### `tc run <path> --all`

**Syntax**: `tc run <path> --all`

**Description**: Run all test suites in directory tree recursively

**Examples**:
```bash
tc run tests --all
tc run . --all
tc run examples --all
```

**Exit Codes**:
- `0` - All tests in all suites passed
- `1` - One or more tests failed or errored

**Output**: Aggregated results for all suites with overall summary

---

#### `tc run <path> --tags TAG`

**Syntax**: `tc run <path> --tags TAG`

**Description**: Run all suites matching specified tag

**Examples**:
```bash
tc run tests --tags auth
tc run tests --tags "api,integration"
```

**Notes**:
- `--tags` implies `--all` (discovers all suites, filters by tag)
- Multiple tags can be comma-separated
- Suite must match ALL specified tags

**Exit Codes**:
- `0` - All matching tests passed
- `1` - One or more tests failed or errored

---

#### `tc run <path> --parallel [N]`

**Syntax**: `tc run <path> --parallel [N]`

**Description**: Run all suites in parallel with N workers (auto-detect if N omitted)

**Examples**:
```bash
tc run tests --all --parallel           # Auto-detect CPU cores
tc run tests --all --parallel 4         # Use 4 workers
tc run tests --tags integration --parallel
```

**Notes**:
- `--parallel` implies `--all`
- If N not specified, detects CPU cores automatically
- Aggregates results from all parallel workers

**Exit Codes**:
- `0` - All tests passed
- `1` - One or more tests failed or errored

---

### Test Generation Commands

#### `tc new <test-path> [options]`

**Syntax**: `tc new <test-path> [options]`

**Description**: Generate new test suite scaffolding

**Options**:
- `--from <template>` - Use specific template (default: "default")
- `--tags <tag1,tag2>` - Comma-separated tags
- `--priority <level>` - Priority: high, medium (default), low
- `--description <text>` - Test description
- `--depends <paths>` - Space-separated dependency paths
- `--force` - Overwrite existing directory
- `--list-examples` - Show available templates
- `--help` - Show help for `new` command

**Examples**:
```bash
tc new tests/my-feature
tc new tests/auth/login --tags "auth,api" --priority high
tc new tests/checkout --description "Test checkout flow"
tc new tests/my-calc --from hello-world
```

**Exit Codes**:
- `0` - Test suite generated successfully
- `1` - Generation failed (invalid path, directory exists without --force, etc.)

**Output**: Success message with generated file paths

---

#### `tc init [directory]`

**Syntax**: `tc init [directory]`

**Description**: Initialize test directory with README

**Examples**:
```bash
tc init                # Initialize ./tests/
tc init my-tests       # Initialize ./my-tests/
```

**Exit Codes**:
- `0` - Directory initialized successfully
- `1` - Initialization failed

**Output**: Success message with created files

---

### Discovery Commands

#### `tc list [path]`

**Syntax**: `tc list [path]`

**Description**: List all test suites with metadata

**Examples**:
```bash
tc list                # List suites in current directory
tc list tests          # List suites in tests/
```

**Exit Codes**: Always `0`

**Output**: Formatted list of test suites with tags and descriptions

---

#### `tc tags [path]`

**Syntax**: `tc tags [path]`

**Description**: Show all available tags across discovered suites

**Examples**:
```bash
tc tags                # Show all tags in current directory
tc tags tests          # Show all tags in tests/
```

**Exit Codes**: Always `0`

**Output**: List of unique tags

---

#### `tc explain <suite>`

**Syntax**: `tc explain <suite>`

**Description**: Explain what a test suite does (show metadata)

**Examples**:
```bash
tc explain tests/auth/login
tc explain examples/hello-world
```

**Exit Codes**:
- `0` - Suite found and explained
- `1` - Suite not found

**Output**: Detailed suite information (description, tags, priority, dependencies, scenarios)

---

### Information Commands

#### `tc --version` / `tc -v`

**Syntax**: `tc --version` or `tc -v`

**Description**: Display version information

**Output**:
```
tc v1.0.0 - island hopper
theodore calvin's language-agnostic testing framework

🚁 testing any language, anywhere
```

**Exit Codes**: Always `0`

---

#### `tc --help` / `tc -h` / `tc help`

**Syntax**: `tc --help` or `tc -h` or `tc help`

**Description**: Display help message

**Output**: Complete usage information with all commands and examples

**Exit Codes**: Always `0`

---

## Environment Variables

### Configuration Overrides

All `TC_*` configuration variables can be overridden via environment:

**Examples**:
```bash
TC_DEFAULT_TIMEOUT=600 tc run tests/slow-suite    # 10-minute timeout
TC_VERBOSE=1 tc run tests --all                   # Verbose output
TC_OUTPUT_FORMAT=json tc run tests/my-suite       # JSON output
```

**Available Variables**:
- `TC_DEFAULT_TIMEOUT` - Test timeout in seconds (default: 300)
- `TC_FUZZY_THRESHOLD` - Fuzzy match threshold 0.0-1.0 (default: 0.9)
- `TC_PARALLEL_DEFAULT` - Default parallel workers (default: 4)
- `TC_OUTPUT_FORMAT` - Output format: human, json, jsonl (default: human)
- `TC_FAIL_FAST` - Stop on first failure: 0 or 1 (default: 0)
- `TC_VERBOSE` - Verbose output: 0 or 1 (default: 0)
- `TC_DEBUG` - Debug mode: 0 or 1 (default: 0)

**Precedence** (highest to lowest):
1. Environment variables
2. Suite-specific config.sh
3. Global config.sh

---

## Backward Compatibility Guarantee

### What Remains Identical

✅ **All Commands**: Every command and subcommand unchanged
✅ **All Flags**: Every flag and option unchanged
✅ **All Behaviors**: Execution logic and output format unchanged
✅ **Exit Codes**: All exit codes unchanged
✅ **Test Suite Contract**: Test runner interface unchanged
✅ **Result Format**: `.tc-result` JSONL format unchanged

### What Changes (Internal Only)

🔧 **Executable Location**: `bin/tc` → `tc/tc` (affects installation, not usage)
🔧 **Library Paths**: Internal `source` statements updated
🔧 **Config Location**: `lib/config/defaults.sh` → `tc/config.sh` (transparent to users)

### Migration Impact

**User Impact**: ZERO - commands work identically after installation update

**Installation Impact**: Update paths in installation instructions

**Before**:
```bash
export PATH="$PWD/bin:$PATH"
sudo ln -s "$PWD/bin/tc" /usr/local/bin/tc
```

**After**:
```bash
export PATH="$PWD/tc:$PATH"
sudo ln -s "$PWD/tc/tc" /usr/local/bin/tc
```

---

## Validation Test Suite

### Regression Tests

**Test Matrix**: All commands × All flags × All edge cases

```bash
# Version and help
tc --version                          # Should display version
tc --help                            # Should display help

# Single suite execution
tc run examples/hello-world           # Should pass
tc run non-existent                  # Should fail with error

# Hierarchical execution
tc run tc/tests --all                # Should run all framework tests
tc run examples --all                # Should run all examples

# Tag filtering
tc run tc/tests --tags unit          # Should run only unit tests
tc run tc/tests --tags integration   # Should run only integration tests

# Parallel execution
tc run tc/tests --all --parallel     # Should run with auto-detected workers
tc run tc/tests --all --parallel 2   # Should run with 2 workers

# Test generation
tc new /tmp/test-foo                 # Should generate suite
tc new /tmp/test-bar --tags "api"    # Should generate with tags
tc new /tmp/test-baz --force         # Should overwrite if exists

# Discovery
tc list tc/tests                     # Should list framework tests
tc tags tc/tests                     # Should show available tags
tc explain tc/tests/unit/json-comparison  # Should explain suite

# Edge cases
tc run                               # Should show error
tc run --all                         # Should run from current directory
tc --invalid-flag                    # Should show error
```

### Acceptance Criteria

All tests must produce **identical output** before and after refactoring (except paths in informational messages).

**Validation Command**:
```bash
# Before refactoring
./bin/tc run tests --all > before.txt 2>&1

# After refactoring
./tc/tc run tests --all > after.txt 2>&1

# Compare (should be identical except paths/timestamps)
diff before.txt after.txt
```

---

## Error Messages (UNCHANGED)

### Path Not Found
```
[ERROR] path not found: tests/non-existent
```

### Not a Test Suite
```
[ERROR] not a test suite: tests/some-directory
[ERROR] test suites must have an executable 'run' file
```

### Invalid Flag
```
[ERROR] unknown flag: --invalid
```

### JQ Not Available
```
[ERROR] jq is required but not found
[ERROR] install jq: https://jqlang.github.io/jq/
```

---

## Performance Contract (UNCHANGED)

**Guarantee**: No performance degradation from refactoring

**Metrics** (must remain equivalent):
- Test execution time (per scenario)
- Test discovery time (for `--all`)
- Parallel execution efficiency
- Memory usage

**Validation**: Benchmark before/after, ensure <5% variance

---

## Contract Versioning

**Current Version**: 1.0.0

**Breaking Changes Policy**:
- Major version increment for CLI command changes
- Minor version increment for new commands/flags (backward compatible)
- Patch version increment for bug fixes

**This Refactoring**: Internal change, CLI version remains 1.0.0

---

**Version**: 1.0.0
**Status**: Complete ✅
**Compatibility**: 100% backward compatible
