# Research: TC Source Layout Refactoring

**Feature**: TC Source Layout Refactoring
**Branch**: `003-refactor-tc-source`
**Date**: 2025-10-12

## Overview

This document captures technical research for refactoring TC's source layout from `bin/tc` + `lib/` to consolidated `./tc/` structure. Key challenges: library path discovery across installation methods, configuration hierarchy, and maintaining zero breaking changes.

---

## R1: Library Path Discovery

### Decision

Use `BASH_SOURCE[0]` to detect the script's actual location, then resolve `TC_ROOT` as parent directory. This works reliably across all installation methods (symlink, PATH, copy).

### Research Findings

**Current Implementation** (bin/tc:11-12):
```bash
# find tc root directory
TC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..\" && pwd)"
```

This locates the script file itself, goes up one directory level (`/..`), and resolves to absolute path.

**Symlink Behavior**:
- When `/usr/local/bin/tc` → `/home/user/repo/bin/tc`
- `BASH_SOURCE[0]` resolves to the **target** of the symlink: `/home/user/repo/bin/tc`
- Going up one level: `/home/user/repo`
- This correctly finds `lib/` at `/home/user/repo/lib/`

**New Structure** (./tc/run):
```bash
# find tc root directory
TC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")\" && pwd)"
```

Key change: Remove `/../` because `./tc/run` IS already inside the framework directory. Just need current directory.

**Why This Works**:
- PATH installation: `./tc/run` executed → `TC_ROOT = ./tc/`
- Symlink: `/usr/local/bin/tc` → `/repo/tc/run` → `TC_ROOT = /repo/tc/`
- Copy: `/usr/local/tc/run` → `TC_ROOT = /usr/local/tc/`

Then all library loads use `$TC_ROOT/lib/...` relative paths.

### Alternatives Considered

**Alternative 1**: Use `$0` instead of `BASH_SOURCE[0]`
- **Problem**: `$0` shows how the script was invoked (e.g., `tc`, `./tc/run`), not actual file location
- **Rejected**: Unreliable for symlinks and non-canonical paths

**Alternative 2**: Hardcode absolute paths during installation
- **Problem**: Breaks development workflow, requires different binaries for dev vs. production
- **Rejected**: Too inflexible, complicates testing and contribution

**Alternative 3**: Use environment variable `TC_HOME`
- **Problem**: Requires users to set environment variable, fragile
- **Rejected**: Adds installation complexity, easy to misconfigure

### Implementation Notes

1. Update `./tc/run` to detect `TC_ROOT` as current directory (not parent)
2. Keep all library paths relative to `$TC_ROOT/lib/`
3. Test across all 3 installation methods in acceptance tests
4. Document path resolution logic in code comments

---

## R2: Configuration Loading Hierarchy

### Decision

Load global config first (`./tc/config.sh`), then detect and load suite-specific `config.sh` if present. Suite variables override globals by simple bash variable reassignment.

### Research Findings

**Current Implementation**:
- Global config: `lib/config/defaults.sh` (loaded once at startup)
- No suite-specific config support exists yet (new feature)

**Proposed Hierarchy**:
```bash
# 1. Load global defaults
source "$TC_ROOT/config.sh"

# 2. Detect suite-specific config (if in suite directory)
if [ -f "$SUITE_DIR/config.sh" ]; then
    source "$SUITE_DIR/config.sh"  # Variables override globals
fi
```

**Variable Precedence** (bash behavior):
- First assignment: `TC_DEFAULT_TIMEOUT=300` (global)
- Second assignment: `TC_DEFAULT_TIMEOUT=600` (suite)
- Result: `TC_DEFAULT_TIMEOUT=600` (suite wins)

This is native bash behavior - no special logic needed.

**Example Scenario**:

Global `./tc/config.sh`:
```bash
TC_DEFAULT_TIMEOUT=300
TC_FUZZY_THRESHOLD=0.9
```

Suite `tests/long-running/config.sh`:
```bash
TC_DEFAULT_TIMEOUT=1800  # Override: 30 minutes for slow tests
# TC_FUZZY_THRESHOLD unchanged (inherits 0.9)
```

Result:
- `TC_DEFAULT_TIMEOUT=1800`
- `TC_FUZZY_THRESHOLD=0.9`

**Environment Variable Interaction**:

Priority order (highest to lowest):
1. Environment variables (user sets `TC_DEFAULT_TIMEOUT=600` before running tc)
2. Suite-specific config.sh
3. Global config.sh

Implementation:
```bash
# Load global defaults (only if not already set)
: ${TC_DEFAULT_TIMEOUT:=300}

# Load suite config (can override)
[ -f "$SUITE_DIR/config.sh" ] && source "$SUITE_DIR/config.sh"

# Env vars override everything (already set before script runs)
```

Using `: ${VAR:=default}` sets variable only if unset, preserving environment variables.

### Alternatives Considered

**Alternative 1**: Explicit override functions
- **Example**: `tc_config_override "timeout" "600"`
- **Rejected**: Overly complex, non-standard bash pattern

**Alternative 2**: JSON/YAML configuration files
- **Rejected**: Adds parsing complexity, breaks Unix simplicity

**Alternative 3**: Command-line flags for all settings
- **Example**: `tc run --timeout=600 tests/suite`
- **Rejected**: Doesn't scale (too many settings), can't share across test runs

### Implementation Notes

1. Rename `lib/config/defaults.sh` → `./tc/config.sh`
2. Add suite config loading in `tc_execute_suite()` function
3. Use bash parameter expansion `${VAR:=default}` to respect env vars
4. Document configuration precedence in quickstart.md
5. Add test scenario: suite with custom timeout overrides global

---

## R3: Installation Method Compatibility

### Decision

Update installation instructions to reference `./tc/` instead of `bin/`. Each method adapts naturally:
- **PATH**: Add `./tc/` to PATH (not `./tc/run`)
- **Symlink**: Link to `./tc/run` (not `bin/tc`)
- **Copy**: Copy entire `./tc/` directory (not just `bin/` and `lib/` separately)

### Research Findings

**Method 1: PATH Installation**

Current:
```bash
export PATH="$PWD/bin:$PATH"
```

New:
```bash
export PATH="$PWD/tc:$PATH"
```

**Behavior**:
- `tc` resolves to `$PWD/tc/tc` — **WRONG**
- Need to create wrapper or rename `./tc/run` → `./tc/tc`

**Corrected Decision**: Keep executable named `tc` inside `./tc/`:
```bash
./tc/tc         # Executable (renamed from 'run')
```

Then PATH installation works: `export PATH="$PWD/tc:$PATH"` finds `./tc/tc`.

**Method 2: Symlink Installation**

Current:
```bash
sudo ln -s "$PWD/bin/tc" /usr/local/bin/tc
```

New:
```bash
sudo ln -s "$PWD/tc/tc" /usr/local/bin/tc
```

Works identically - symlink target updated to new path.

**Method 3: Copy Installation**

Current:
```bash
sudo cp -r bin lib /usr/local/
```

New:
```bash
sudo cp -r tc /usr/local/
sudo ln -s /usr/local/tc/tc /usr/local/bin/tc  # Make accessible in PATH
```

Or simpler:
```bash
sudo cp -r tc /usr/local/
export PATH="/usr/local/tc:$PATH"
```

**Revised Structure Decision**:

Based on PATH installation requirements, change plan:

```
tc/
├── tc                 # Executable (NOT 'run')
├── config.sh
├── lib/
└── tests/
```

This allows `export PATH="$PWD/tc:$PATH"` to find the `tc` command naturally.

### Alternatives Considered

**Alternative 1**: Keep executable named `run`, create wrapper script
- **Example**: `./tc/tc` wrapper calls `./tc/run`
- **Rejected**: Adds unnecessary indirection, confusing

**Alternative 2**: Use `./tc/bin/tc` internally
- **Example**: `./tc/bin/tc` as entry point, `./tc/lib/` for libraries
- **Rejected**: Adds extra nesting, defeats "ultra tidy" goal

**Alternative 3**: Require users to symlink after PATH installation
- **Example**: Add `./tc/` to PATH, then run `ln -s run tc` manually
- **Rejected**: Adds manual step, error-prone

### Implementation Notes

1. **REVISED**: Executable is `./tc/tc` (not `./tc/run`)
2. Update all installation instructions in README.md
3. Update spec.md to reflect executable name change
4. Test all 3 methods in acceptance tests
5. Add troubleshooting section for common PATH issues

---

## R4: Backward Compatibility Strategy

### Decision

Maintain complete interface stability: test runner contract, discovery algorithm, result format, and command-line API remain unchanged. Only internal file paths change.

### Research Findings

**Test Runner Interface** (unchanged):
```bash
# Test suite contract
./tests/my-suite/run         # Executable that reads input.json
input.json  → stdin or arg   # Standard input format
output JSON → stdout         # Standard output format
```

This contract is between TC framework and test suites - completely independent of TC's internal organization.

**Test Discovery** (unchanged):

Current algorithm:
1. Look for directories with executable `run` file
2. Look for `data/*/input.json` and `data/*/expected.json`
3. Return suite path

No changes needed - discovery walks filesystem looking for pattern, doesn't care where TC's code lives.

**Result Format** (unchanged):
```jsonl
{"scenario":"scenario-1","status":"pass","elapsed":0.234}
{"scenario":"scenario-2","status":"fail","error":"..."}
```

Written to `.tc-result` file in suite directory. Format unchanged.

**CLI Commands** (unchanged):
```bash
tc run <path>
tc run <path> --all
tc run <path> --tags TAG
tc run <path> --parallel
tc new <path>
tc init <dir>
tc list [path]
tc tags [path]
tc explain <path>
tc --version
tc --help
```

All commands, flags, and behavior remain identical.

**What Actually Changes**:

Internal only:
- File paths in `source` statements (bin/tc → tc/tc)
- TC_ROOT calculation (one level up → same directory)
- Config file location (lib/config/defaults.sh → tc/config.sh)
- Test suite location (tests/ → tc/tests/ for framework self-tests)

User-visible:
- Installation paths (bin/tc → tc/tc)
- Documentation references to paths

**Zero User Impact**:
- Existing test suites: work without modification
- Test results: identical format and behavior
- Commands: identical interface

### Validation Strategy

**Regression Test Approach**:

1. Run full test suite BEFORE refactoring, capture results
2. Perform refactoring
3. Run identical test suite AFTER refactoring
4. Diff results - must be byte-identical except timestamps

**Acceptance Test Scenarios** (from spec.md):

- ✅ `tc --version` displays correctly
- ✅ `tc run tests --all` passes all tests with identical results
- ✅ `tc new tests/foo` generates identical structure
- ✅ `tc run tests --parallel` executes identically

### Implementation Notes

1. Create "golden" test results before refactoring starts
2. Do NOT modify test discovery, runner, or result generation logic
3. Do NOT modify command parsing or flag handling
4. Only update: file paths, directory structure, documentation
5. Run full regression suite as final implementation step

---

## Summary

### Key Technical Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Executable Name** | `./tc/tc` (revised from `./tc/run`) | Enables clean PATH installation without wrappers |
| **Path Discovery** | `BASH_SOURCE[0]` → same directory | Works reliably across all installation methods |
| **Config Hierarchy** | Global first, suite overrides | Simple bash variable reassignment, no special logic |
| **Installation Methods** | Update paths, behavior unchanged | All 3 methods remain simple, just reference new locations |
| **Backward Compat** | Zero interface changes | Only internal paths change, user-facing behavior identical |

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Symlink resolution breaks | Low | High | Test all installation methods in CI |
| Suite config conflicts | Low | Medium | Document precedence clearly, add examples |
| PATH issues on different shells | Medium | Low | Test on bash, zsh, sh, fish |
| Documentation drift | Medium | Medium | Update all docs in same PR, review checklist |
| Regression in test execution | Low | High | Run full test suite before/after, diff results |

### Open Questions

**Q1**: Should framework self-tests (tc/tests/) run automatically on `tc run --all` from repo root?
- **Answer**: No. User runs `tc run tc/tests --all` explicitly to test framework itself. `tc run tests --all` for user tests only.

**Q2**: Should old `bin/tc` remain as deprecated wrapper during transition period?
- **Answer**: No. Clean break is simpler. Users update installation once. Document in upgrade guide.

**Q3**: Should config.sh support includes (e.g., `source common-config.sh`)?
- **Answer**: Out of scope for this refactoring. Could be added later if needed.

---

## References

- Feature Specification: [spec.md](./spec.md)
- Implementation Plan: [plan.md](./plan.md)
- Current Source: `bin/tc`, `lib/`
- Bash Manual: BASH_SOURCE, source command behavior
- TC Test Suites: examples/hello-world/, tests/unit/, tests/integration/

---

**Status**: Research complete ✅
**Next Phase**: Design (data-model.md, contracts/, quickstart.md)
