# Filesystem Contract: TC Source Layout Refactoring

**Feature**: TC Source Layout Refactoring
**Version**: 1.0.0
**Date**: 2025-10-12

## Overview

This contract defines the filesystem layout, path conventions, and file organization requirements for the refactored TC framework structure.

---

## Directory Structure Contract

### Framework Directory Structure

**Path**: `./tc/`

```
tc/
├── tc                         # REQUIRED: Executable entry point
├── config.sh                  # REQUIRED: Global configuration
├── lib/                       # REQUIRED: Framework libraries
│   ├── core/                  # REQUIRED: Core framework modules
│   │   ├── comparator.sh      # REQUIRED
│   │   ├── discovery.sh       # REQUIRED
│   │   ├── executor.sh        # REQUIRED
│   │   ├── generator.sh       # REQUIRED
│   │   ├── metadata.sh        # REQUIRED
│   │   ├── parallel.sh        # REQUIRED
│   │   ├── runner.sh          # REQUIRED
│   │   ├── templates.sh       # REQUIRED
│   │   └── validator.sh       # REQUIRED
│   └── utils/                 # REQUIRED: Utility modules
│       ├── json.sh            # REQUIRED
│       ├── log.sh             # REQUIRED
│       ├── platform.sh        # REQUIRED
│       ├── reporter.sh        # REQUIRED
│       └── timer.sh           # REQUIRED
└── tests/                     # OPTIONAL: Framework self-tests
    ├── unit/
    │   └── json-comparison/
    └── integration/
        ├── hierarchical/
        └── single-suite/
```

**Contract Guarantees**:
- ✅ All paths relative to `$TC_ROOT` (`./tc/`)
- ✅ Executable `tc` located at `$TC_ROOT/tc`
- ✅ Global config at `$TC_ROOT/config.sh`
- ✅ All libraries under `$TC_ROOT/lib/`
- ✅ Framework tests under `$TC_ROOT/tests/` (optional in minimal installs)

---

## File Permissions Contract

### Executable Files

**Requirements**:
```bash
chmod +x ./tc/tc                         # Entry point must be executable
chmod +x ./tc/tests/*/run                # Test runners must be executable
```

**Validation**:
```bash
[ -x "./tc/tc" ] || echo "ERROR: tc executable not found or not executable"
[ -r "./tc/config.sh" ] || echo "ERROR: config.sh not readable"
[ -d "./tc/lib" ] || echo "ERROR: lib directory not found"
```

### Source Files

**Requirements**:
- All `.sh` files in `lib/` must be readable (`chmod 644` or better)
- Config files must be readable (`chmod 644` or better)
- No execution required for library modules (sourced, not executed)

---

## Path Resolution Contract

### TC_ROOT Detection

**Contract**: `TC_ROOT` must resolve to the directory containing the `tc` executable, regardless of invocation method.

**Implementation**:
```bash
# In ./tc/tc script (line ~11)
TC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Test Cases**:

| Invocation Method | Command | Expected TC_ROOT |
|-------------------|---------|------------------|
| Direct | `./tc/tc --version` | `/path/to/repo/tc` |
| PATH | `tc --version` (PATH includes `/path/to/repo/tc`) | `/path/to/repo/tc` |
| Symlink | `tc --version` (via `/usr/local/bin/tc` → `/path/to/repo/tc/tc`) | `/path/to/repo/tc` |
| Copy | `tc --version` (copied to `/usr/local/tc/tc`) | `/usr/local/tc` |

**Validation**:
```bash
# Verify TC_ROOT points to valid framework directory
[ -f "$TC_ROOT/tc" ] || exit 1
[ -f "$TC_ROOT/config.sh" ] || exit 1
[ -d "$TC_ROOT/lib" ] || exit 1
```

### Library Path Construction

**Contract**: All library paths constructed relative to `$TC_ROOT`.

**Implementation**:
```bash
source "$TC_ROOT/config.sh"
source "$TC_ROOT/lib/utils/log.sh"
source "$TC_ROOT/lib/utils/json.sh"
source "$TC_ROOT/lib/core/discovery.sh"
# etc.
```

**Forbidden Patterns**:
```bash
# ❌ WRONG: Hardcoded absolute paths
source "/usr/local/tc/lib/utils/log.sh"

# ❌ WRONG: Relative paths without TC_ROOT
source "../lib/utils/log.sh"

# ❌ WRONG: Assuming current directory
source "lib/utils/log.sh"

# ✅ CORRECT: Relative to TC_ROOT
source "$TC_ROOT/lib/utils/log.sh"
```

---

## Installation Path Contract

### PATH Installation

**User Action**:
```bash
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/tc:$PATH"
```

**Contract Guarantees**:
- ✅ `tc` command resolves to `$PWD/tc/tc`
- ✅ Libraries discoverable at `$PWD/tc/lib/`
- ✅ No additional symlinks or wrappers required

### Symlink Installation

**User Action**:
```bash
git clone https://github.com/ahoward/tc.git
cd tc
sudo ln -s "$PWD/tc/tc" /usr/local/bin/tc
```

**Contract Guarantees**:
- ✅ `/usr/local/bin/tc` resolves through symlink to actual `tc/tc`
- ✅ `BASH_SOURCE[0]` resolves to target (not symlink), finding libraries
- ✅ Repository can be moved (symlink must be updated)

### Copy Installation

**User Action**:
```bash
git clone https://github.com/ahoward/tc.git
cd tc
sudo cp -r tc /usr/local/
export PATH="/usr/local/tc:$PATH"
```

**Contract Guarantees**:
- ✅ Entire `tc/` directory copied to `/usr/local/tc/`
- ✅ Framework is self-contained, no dependency on source repo
- ✅ Updates require re-copying entire directory

---

## Configuration File Contract

### Global Configuration Location

**Path**: `$TC_ROOT/config.sh`

**Content Contract**:
```bash
#!/usr/bin/env bash
# tc global configuration

# Variable definitions (bash format)
TC_DEFAULT_TIMEOUT=300
TC_DEFAULT_COMPARISON="semantic_json"
# ... etc
```

**Requirements**:
- Must be valid bash script (sourceable without errors)
- Must define all required TC_* variables
- Must use bash variable assignment syntax (`VAR=value`)
- Must not execute commands with side effects (only variable assignments)

### Suite Configuration Location

**Path**: `<test-suite-dir>/config.sh` (optional)

**Content Contract**: Same as global configuration

**Loading Contract**:
```bash
# 1. Global config loaded once at startup
source "$TC_ROOT/config.sh"

# 2. Suite config loaded per suite execution (if exists)
if [ -f "$suite_dir/config.sh" ]; then
    source "$suite_dir/config.sh"
fi
```

---

## Test Suite Contract (Unchanged)

**Path**: Any directory with required structure

```
<test-suite-dir>/
├── run                    # REQUIRED: Executable test runner
├── config.sh              # OPTIONAL: Suite-specific configuration
├── data/                  # REQUIRED: Test scenarios
│   ├── scenario-1/
│   │   ├── input.json     # REQUIRED
│   │   └── expected.json  # REQUIRED
│   └── scenario-2/
│       ├── input.json
│       └── expected.json
└── .tc-result             # GENERATED: Test results (JSONL)
```

**Contract Guarantees** (UNCHANGED from current):
- ✅ Test runner interface identical
- ✅ Discovery algorithm identical
- ✅ Result format identical
- ✅ No changes required to existing test suites

---

## Breaking Changes

### Removed Paths

**Deleted**:
- `bin/tc` → **Moved to** `tc/tc`
- `lib/config/defaults.sh` → **Moved to** `tc/config.sh`
- `lib/core/*.sh` → **Moved to** `tc/lib/core/*.sh`
- `lib/utils/*.sh` → **Moved to** `tc/lib/utils/*.sh`
- `tests/` (at repo root) → **Moved to** `tc/tests/`

**Migration Required**:
- Update installation instructions to reference `tc/` instead of `bin/`
- Update any scripts that reference old paths
- Update documentation

### Non-Breaking

**Unchanged**:
- Test suite structure (user test suites unaffected)
- Test runner interface (no changes to test suite contract)
- Command-line interface (all commands and flags identical)
- Result file format (`.tc-result` unchanged)

---

## Validation Checklist

### Pre-Installation Validation

- [ ] `tc/tc` file exists and is executable
- [ ] `tc/config.sh` file exists and is readable
- [ ] `tc/lib/core/` directory contains all 9 required modules
- [ ] `tc/lib/utils/` directory contains all 5 required modules
- [ ] All `.sh` files are readable

### Post-Installation Validation

- [ ] `tc --version` displays version correctly
- [ ] `tc --help` displays help correctly
- [ ] `tc run examples/hello-world` executes successfully
- [ ] `tc run tc/tests --all` passes all framework self-tests (if present)
- [ ] `tc new test-foo` generates test suite successfully

### Installation Method Validation

- [ ] PATH installation: `which tc` points to correct location
- [ ] Symlink installation: `ls -l $(which tc)` shows correct target
- [ ] Copy installation: `tc --version` works without source repo

---

## Appendix: Migration Commands

### Developer Migration (in-place)

```bash
# No action required - git pull updates repository structure
git pull origin main
export PATH="$PWD/tc:$PATH"  # Updated PATH
tc --version  # Verify
```

### System Installation Migration

**Symlink Method**:
```bash
# Remove old symlink
sudo rm /usr/local/bin/tc

# Create new symlink
cd /path/to/repo
sudo ln -s "$PWD/tc/tc" /usr/local/bin/tc
```

**Copy Method**:
```bash
# Remove old files
sudo rm /usr/local/bin/tc
sudo rm -rf /usr/local/lib/tc

# Copy new structure
cd /path/to/repo
sudo cp -r tc /usr/local/
export PATH="/usr/local/tc:$PATH"
```

---

**Version**: 1.0.0
**Status**: Complete ✅
