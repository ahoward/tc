# Data Model: TC Source Layout Refactoring

**Feature**: TC Source Layout Refactoring
**Branch**: `003-refactor-tc-source`
**Date**: 2025-10-12

## Overview

This document defines the entities, relationships, and state models for the refactored TC source layout. This is primarily a **structural refactoring**, so the "data model" focuses on filesystem organization, path resolution, and configuration hierarchy rather than traditional data entities.

---

## Entity Definitions

### E1: Framework Root Directory

**Entity**: `FrameworkRoot`
**Physical Path**: `./tc/`
**Purpose**: Container for all TC framework code, separating framework from project-level files (README, docs, user tests)

**Structure**:
```
tc/
├── tc              # Entry point executable
├── config.sh       # Global configuration
├── lib/            # Framework libraries
└── tests/          # Framework self-tests
```

**Properties**:
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `location` | Path | Yes | Absolute path to tc/ directory |
| `executable` | Path | Yes | `$location/tc` |
| `config` | Path | Yes | `$location/config.sh` |
| `lib_dir` | Path | Yes | `$location/lib/` |
| `tests_dir` | Path | Yes | `$location/tests/` |

**Validation Rules**:
- Must contain executable file `tc` with execute permissions
- Must contain readable file `config.sh`
- Must contain directory `lib/` with subdirectories `core/` and `utils/`
- Tests directory is optional (may not exist in minimal installations)

**Relationships**:
- Contains 1 `CLIEntryPoint` (tc)
- Contains 1 `GlobalConfiguration` (config.sh)
- Contains N `LibraryModule` (lib/**/*.sh)
- Contains N `TestSuite` (tests/*/)

---

### E2: CLI Entry Point

**Entity**: `CLIEntryPoint`
**Physical Path**: `./tc/tc`
**Purpose**: Main executable that routes commands, loads configuration, discovers libraries

**Properties**:
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `path` | Path | Yes | Absolute path to executable |
| `tc_root` | Path | Yes | Resolved framework root directory |
| `invocation_method` | Enum | Yes | `direct`, `symlink`, `path_lookup` |

**State Transitions**:
```
[Invoked] → [Resolve TC_ROOT] → [Load Config] → [Load Libraries] → [Route Command] → [Execute] → [Exit]
```

**Invocation Methods**:

1. **Direct**: `./tc/tc run tests`
   - `BASH_SOURCE[0]` = `/path/to/repo/tc/tc`
   - `TC_ROOT` = `/path/to/repo/tc`

2. **Symlink**: `tc run tests` (via `/usr/local/bin/tc` → `/path/to/repo/tc/tc`)
   - `BASH_SOURCE[0]` = `/path/to/repo/tc/tc` (resolves through symlink)
   - `TC_ROOT` = `/path/to/repo/tc`

3. **PATH Lookup**: `tc run tests` (via `PATH=/path/to/repo/tc:$PATH`)
   - `BASH_SOURCE[0]` = `/path/to/repo/tc/tc`
   - `TC_ROOT` = `/path/to/repo/tc`

**Validation Rules**:
- Must be executable (`chmod +x`)
- Must successfully resolve `TC_ROOT` on invocation
- Must load all required libraries without error
- Must handle missing libraries gracefully with error message

**Relationships**:
- Located in 1 `FrameworkRoot`
- Loads 1 `GlobalConfiguration`
- Sources N `LibraryModule`
- Executes 0..N `TestSuite`

---

### E3: Library Module

**Entity**: `LibraryModule`
**Physical Path**: `./tc/lib/{core,utils}/*.sh`
**Purpose**: Reusable shell script modules providing framework functionality

**Categories**:

**Core Modules** (`./tc/lib/core/`):
- `comparator.sh` - JSON comparison logic
- `discovery.sh` - Test suite discovery
- `executor.sh` - Test execution engine
- `generator.sh` - Test suite scaffolding
- `metadata.sh` - Test metadata parsing
- `parallel.sh` - Parallel execution
- `runner.sh` - Test runner coordination
- `templates.sh` - Template management
- `validator.sh` - Input validation

**Utility Modules** (`./tc/lib/utils/`):
- `json.sh` - JSON processing helpers
- `log.sh` - Logging functions
- `platform.sh` - Platform detection
- `reporter.sh` - Result reporting
- `timer.sh` - Timing utilities

**Properties**:
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `path` | Path | Yes | Absolute path to .sh file |
| `category` | Enum | Yes | `core`, `utils` |
| `functions` | List[String] | Yes | Public functions exported |
| `dependencies` | List[Path] | No | Other modules this depends on |

**Loading Order**:
```bash
# 1. Config first (defines defaults)
source "$TC_ROOT/config.sh"

# 2. Utilities (no dependencies)
source "$TC_ROOT/lib/utils/log.sh"
source "$TC_ROOT/lib/utils/json.sh"
source "$TC_ROOT/lib/utils/platform.sh"
source "$TC_ROOT/lib/utils/timer.sh"
source "$TC_ROOT/lib/utils/reporter.sh"

# 3. Core modules (may depend on utils)
source "$TC_ROOT/lib/core/discovery.sh"
source "$TC_ROOT/lib/core/validator.sh"
source "$TC_ROOT/lib/core/comparator.sh"
source "$TC_ROOT/lib/core/executor.sh"
source "$TC_ROOT/lib/core/runner.sh"
source "$TC_ROOT/lib/core/metadata.sh"
source "$TC_ROOT/lib/core/generator.sh"
source "$TC_ROOT/lib/core/templates.sh"
source "$TC_ROOT/lib/core/parallel.sh"
```

**Validation Rules**:
- Must be readable files
- Must define at least one function
- Must not have circular dependencies
- Must use `TC_ROOT` for any internal path references

**Relationships**:
- Located in 1 `FrameworkRoot`
- Sourced by 1 `CLIEntryPoint`
- May depend on N other `LibraryModule`

---

### E4: Global Configuration

**Entity**: `GlobalConfiguration`
**Physical Path**: `./tc/config.sh`
**Purpose**: Default settings for all TC operations

**Properties**:
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `TC_DEFAULT_TIMEOUT` | Integer (seconds) | 300 | Test execution timeout |
| `TC_MAX_TIMEOUT` | Integer (seconds) | 3600 | Maximum allowed timeout |
| `TC_DEFAULT_COMPARISON` | Enum | `semantic_json` | Comparison mode |
| `TC_FUZZY_THRESHOLD` | Float (0.0-1.0) | 0.9 | Fuzzy match threshold |
| `TC_PARALLEL_MODE` | String | `auto` | Parallel execution mode |
| `TC_PARALLEL_DEFAULT` | Integer | 4 | Default parallel workers |
| `TC_OUTPUT_FORMAT` | Enum | `human` | Output format |
| `TC_RESULT_FILE` | String | `.tc-result` | Result filename |
| `TC_FAIL_FAST` | Boolean (0/1) | 0 | Stop on first failure |
| `TC_VERBOSE` | Boolean (0/1) | 0 | Verbose output |
| `TC_DEBUG` | Boolean (0/1) | 0 | Debug mode |
| `TC_COLOR_*` | String (ANSI) | Various | Color codes |

**Validation Rules**:
- Timeout values must be positive integers
- Fuzzy threshold must be between 0.0 and 1.0
- Comparison mode must be in allowed list
- Output format must be `human`, `json`, or `jsonl`
- Boolean flags must be 0 or 1

**Override Hierarchy** (highest to lowest priority):
1. **Environment Variables**: Set before running `tc` command
2. **Suite Configuration**: Loaded from test suite's `config.sh`
3. **Global Configuration**: Default values from `./tc/config.sh`

**Relationships**:
- Located in 1 `FrameworkRoot`
- Loaded by 1 `CLIEntryPoint`
- Overridden by N `SuiteConfiguration`

---

### E5: Suite Configuration

**Entity**: `SuiteConfiguration`
**Physical Path**: `<test-suite-dir>/config.sh`
**Purpose**: Per-suite overrides of global configuration

**Properties**: Same as `GlobalConfiguration` but all optional

**Example**:
```bash
# tests/long-running-api/config.sh
TC_DEFAULT_TIMEOUT=1800       # 30 minutes (override global 5 minutes)
TC_VERBOSE=1                  # Enable verbose logging for this suite
# All other settings inherit from global config
```

**Loading Behavior**:
```bash
# In tc_execute_suite function
function tc_execute_suite() {
    local suite_dir="$1"

    # Global config already loaded at startup

    # Load suite-specific overrides if present
    if [ -f "$suite_dir/config.sh" ]; then
        source "$suite_dir/config.sh"
    fi

    # Now use configuration for test execution
    timeout "$TC_DEFAULT_TIMEOUT" ./run < input.json
}
```

**Validation Rules**:
- File is optional (most suites use defaults)
- Must be valid bash script (sources without error)
- Should only set TC_* variables (don't pollute namespace)
- Values must pass same validation as global config

**Isolation**:
- Configuration changes apply only to current suite
- Next suite execution reloads global config (fresh state)
- No cross-suite configuration leakage

**Relationships**:
- Located in 1 `TestSuite`
- Overrides values from 1 `GlobalConfiguration`
- Scoped to single suite execution

---

### E6: Test Suite

**Entity**: `TestSuite`
**Physical Path**: `<any-directory>/` (user-defined location)
**Purpose**: Language-agnostic test suite (consumer of TC framework)

**Structure**:
```
my-test-suite/
├── run                    # Executable test runner
├── config.sh              # Optional: suite-specific config
├── data/
│   ├── scenario-1/
│   │   ├── input.json
│   │   └── expected.json
│   └── scenario-2/
│       ├── input.json
│       └── expected.json
└── .tc-result             # Generated: test results (JSONL)
```

**Properties**:
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `path` | Path | Yes | Absolute path to suite directory |
| `runner` | Path | Yes | `$path/run` executable |
| `config` | Path | No | `$path/config.sh` (optional) |
| `scenarios` | List[Scenario] | Yes | Test scenarios in data/ |
| `results` | Path | No | `$path/.tc-result` (generated) |

**Validation Rules**:
- Must contain executable `run` file
- Must contain `data/` directory with at least one scenario
- Each scenario must have `input.json` and `expected.json`
- Runner must read JSON from stdin/args, write JSON to stdout

**State Machine** (per scenario):
```
[Pending] → [Executing] → [Pass|Fail|Error]
```

**Relationships**:
- May be located in `FrameworkRoot/tests/` (self-tests) or anywhere else (user tests)
- Executed by 1 `CLIEntryPoint`
- May have 0..1 `SuiteConfiguration`
- Contains N `Scenario` (in data/ subdirectories)

---

## Entity Relationships

```
FrameworkRoot (./tc/)
├── has 1 → CLIEntryPoint (./tc/tc)
│   ├── loads 1 → GlobalConfiguration (./tc/config.sh)
│   ├── sources N → LibraryModule (./tc/lib/**/*.sh)
│   └── executes N → TestSuite (any location)
│       └── may have 0..1 → SuiteConfiguration (config.sh)
├── contains 1 → GlobalConfiguration
├── contains N → LibraryModule
└── contains N → TestSuite (framework self-tests)
```

---

## Path Resolution Model

**Path Discovery Algorithm**:

```bash
# Step 1: Detect script location (works for all installation methods)
SCRIPT_PATH="${BASH_SOURCE[0]}"

# Step 2: Resolve to absolute path
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Step 3: TC_ROOT is the directory containing the script
TC_ROOT="$SCRIPT_DIR"

# Step 4: Construct library paths
TC_CONFIG="$TC_ROOT/config.sh"
TC_LIB_DIR="$TC_ROOT/lib"
TC_TESTS_DIR="$TC_ROOT/tests"
```

**Installation Method Mapping**:

| Method | User Action | BASH_SOURCE[0] | TC_ROOT |
|--------|-------------|----------------|---------|
| PATH | `export PATH="/repo/tc:$PATH"` | `/repo/tc/tc` | `/repo/tc` |
| Symlink | `ln -s /repo/tc/tc /usr/local/bin/tc` | `/repo/tc/tc` | `/repo/tc` |
| Copy | `cp -r /repo/tc /usr/local/tc` | `/usr/local/tc/tc` | `/usr/local/tc` |

All three methods result in correct `TC_ROOT` resolution.

---

## Configuration Hierarchy Model

**Loading Sequence**:

```
[Start]
  ↓
[Load Environment Variables] (highest priority)
  ↓
[Load Global Config: ./tc/config.sh] (set defaults using ${VAR:=default})
  ↓
[Detect Suite Directory]
  ↓
[Check for Suite Config: $suite/config.sh]
  ↓ (if exists)
[Load Suite Config] (overrides global)
  ↓
[Execute Test with Merged Config]
  ↓
[End]
```

**Precedence Example**:

```bash
# Scenario: User wants 10-minute timeout for specific suite

# 1. Global config sets default
# ./tc/config.sh
TC_DEFAULT_TIMEOUT=300  # 5 minutes

# 2. Suite config overrides
# tests/slow-integration/config.sh
TC_DEFAULT_TIMEOUT=600  # 10 minutes

# 3. User can override at runtime
TC_DEFAULT_TIMEOUT=120 tc run tests/slow-integration  # 2 minutes (highest priority)
```

---

## Migration Path

**From Current Structure**:
```
bin/tc → source lib/config/defaults.sh
      → source lib/utils/*.sh
      → source lib/core/*.sh
```

**To New Structure**:
```
tc/tc → source tc/config.sh
      → source tc/lib/utils/*.sh
      → source tc/lib/core/*.sh
```

**Changes**:
- Update `source` paths to use `$TC_ROOT` prefix
- Change `TC_ROOT` calculation from parent directory to same directory
- Rename `defaults.sh` to `config.sh`
- Move `tests/` to `tc/tests/`

**Validation**:
- All entities remain functionally identical
- No changes to test suite contract
- No changes to command-line interface
- Path resolution works across all installation methods

---

## Summary

### Core Entities
1. **FrameworkRoot**: Container directory (`./tc/`)
2. **CLIEntryPoint**: Main executable (`./tc/tc`)
3. **LibraryModule**: Framework code (`./tc/lib/**/*.sh`)
4. **GlobalConfiguration**: Default settings (`./tc/config.sh`)
5. **SuiteConfiguration**: Per-suite overrides (optional `config.sh`)
6. **TestSuite**: User/framework tests (any location)

### Key Relationships
- Framework root contains all framework entities
- CLI entry point loads config, sources libraries, executes tests
- Suite config optionally overrides global config
- Test suites are independent consumers of framework

### Critical Properties
- Path resolution works uniformly across installation methods
- Configuration hierarchy respects environment > suite > global
- Test suite contract remains completely unchanged
- Backward compatibility maintained through interface stability

---

**Status**: Data model complete ✅
**Next**: Contracts (filesystem, CLI, configuration)
