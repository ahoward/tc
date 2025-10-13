# Implementation Plan: TC Source Layout Refactoring

**Branch**: `003-refactor-tc-source` | **Date**: 2025-10-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-refactor-tc-source/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Refactor TC source layout from `bin/tc` + scattered `lib/` to consolidated `./tc/` structure. Move CLI entry point to `./tc/run`, relocate global config to `./tc/config.sh`, organize all framework code under `./tc/lib/`, and move self-tests to `./tc/tests/`. Support optional per-suite configuration. This is a pure refactoring - all functionality remains identical, but source organization becomes "ultra tidy" with clear separation between framework and project-level files.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible shell scripting)
**Primary Dependencies**: jq (JSON processing), standard POSIX tools (sh, basename, dirname, find, grep, etc.)
**Storage**: Filesystem-based (test suites as directories, results as .tc-result JSONL files)
**Testing**: TC self-tests (meta: framework tests itself using tc commands)
**Target Platform**: Linux, macOS, Windows/WSL (any POSIX-compatible environment)
**Project Type**: Single CLI tool with library modules
**Performance Goals**: No performance impact - identical runtime behavior to current implementation
**Constraints**:
  - Zero breaking changes to existing test suites
  - All 3 installation methods (PATH, symlink, copy) must work
  - Library discovery must work regardless of invocation path
  - Backward compatibility with existing commands/flags
**Scale/Scope**:
  - ~15 library modules to relocate
  - 1 CLI entry point to move/update
  - ~10 test suites to relocate
  - 3 installation methods to validate
  - Documentation across 5+ files to update

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: No project constitution exists yet - this is an early-stage refactoring. Constitution will be established through spec-kit workflow.

**Key Considerations**:
- Test-first principle applies - existing test suites serve as acceptance tests
- All existing functionality must pass regression tests
- Refactoring must not introduce new features or behavior changes
- Simple is better - directory reorganization only, no architectural changes

**Gate Status**: ✅ PASS (pure refactoring, no new complexity introduced)

## Project Structure

### Documentation (this feature)

```
specs/003-refactor-tc-source/
├── spec.md                    # Feature specification (complete)
├── checklists/
│   └── requirements.md        # Quality validation (complete)
├── plan.md                    # This file (in progress)
├── research.md                # Phase 0 output (pending)
├── data-model.md              # Phase 1 output (pending)
├── quickstart.md              # Phase 1 output (pending)
├── contracts/                 # Phase 1 output (pending)
└── tasks.md                   # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

**Current Structure**:
```
bin/
└── tc                         # CLI entry point

lib/
├── config/
│   └── defaults.sh
├── core/
│   ├── comparator.sh
│   ├── discovery.sh
│   ├── executor.sh
│   ├── generator.sh
│   ├── metadata.sh
│   ├── parallel.sh
│   ├── runner.sh
│   ├── templates.sh
│   └── validator.sh
└── utils/
    ├── json.sh
    ├── log.sh
    ├── platform.sh
    ├── reporter.sh
    └── timer.sh

tests/                         # TC self-tests (dogfooding)
├── unit/
│   └── json-comparison/
├── integration/
│   ├── hierarchical/
│   └── single-suite/

examples/                      # Example test suites
└── hello-world/
```

**Target Structure**:
```
tc/                            # NEW: Framework root directory
├── run                        # NEW: CLI entry point (moved from bin/tc)
├── config.sh                  # NEW: Global config (moved from lib/config/defaults.sh)
├── lib/                       # Framework libraries (relocated)
│   ├── core/
│   │   ├── comparator.sh
│   │   ├── discovery.sh
│   │   ├── executor.sh
│   │   ├── generator.sh
│   │   ├── metadata.sh
│   │   ├── parallel.sh
│   │   ├── runner.sh
│   │   ├── templates.sh
│   │   └── validator.sh
│   └── utils/
│       ├── json.sh
│       ├── log.sh
│       ├── platform.sh
│       ├── reporter.sh
│       └── timer.sh
└── tests/                     # Framework self-tests (relocated)
    ├── unit/
    │   └── json-comparison/
    └── integration/
        ├── hierarchical/
        └── single-suite/

examples/                      # Example test suites (unchanged location)
└── hello-world/
```

**Structure Decision**: Single CLI tool structure (Option 1). All framework code consolidates under `./tc/` directory, maintaining existing internal organization (core/, utils/) but relocating to new parent. Test suites (examples/, user tests) remain outside framework directory - they are consumers, not part of the framework itself.

## Complexity Tracking

*No violations to track - this is a pure refactoring within existing complexity bounds.*

## Phase 0: Research

**Research Questions**:

1. **Library Path Discovery**: How does `./tc/run` discover `./tc/lib/` modules when invoked from different working directories or via different installation methods?
   - Symlink installation: `/usr/local/bin/tc` → `$REPO/tc/run`
   - PATH installation: `$PATH` includes `$REPO/tc/`
   - Copy installation: `/usr/local/tc/run` + `/usr/local/tc/lib/`

2. **Configuration Loading Hierarchy**: How does suite-specific `config.sh` override global `./tc/config.sh`?
   - Loading order: global first, then suite-specific
   - Variable precedence: suite values override globals
   - Environment variable interaction

3. **Installation Method Compatibility**: How do all 3 installation methods adapt to new structure?
   - PATH: Must add `./tc` to PATH (not `./tc/run`)
   - Symlink: Must link to `./tc/run` (not `bin/tc`)
   - Copy: Must copy entire `./tc/` directory structure

4. **Backward Compatibility Strategy**: How to ensure existing test suites work without modification?
   - Test runner interface unchanged
   - Test discovery unchanged
   - Result file format unchanged
   - No changes to test suite structure

**Status**: Research tasks identified. Will generate detailed research.md in Phase 0 execution.

## Phase 1: Design & Contracts

**Entities** (from spec.md Key Entities):
- Framework Root (`./tc/`)
- CLI Entry Point (`./tc/run`)
- Global Configuration (`./tc/config.sh`)
- Test Suite Configuration (optional `config.sh` in suite dirs)

**Contracts**:
- **File Path Contract**: All library `source` statements updated to use new paths
- **Discovery Contract**: TC_ROOT detection must work for all installation methods
- **Configuration Contract**: Suite config inherits and overrides global config
- **CLI Contract**: All existing commands/flags remain identical

**Status**: Will generate data-model.md, contracts/, and quickstart.md in Phase 1 execution.

## Phase Completion Status

### Phase 0: Research ✅ COMPLETE
- ✅ research.md created with detailed technical research
- ✅ Library path discovery strategy finalized
- ✅ Configuration hierarchy defined
- ✅ Installation method compatibility verified
- ✅ Backward compatibility strategy documented

### Phase 1: Design & Contracts ✅ COMPLETE
- ✅ data-model.md created (6 core entities defined)
- ✅ contracts/filesystem-contract.md created
- ✅ contracts/cli-contract.md created (100% backward compatible)
- ✅ quickstart.md created (installation and usage guide)
- ✅ Agent context updated (CLAUDE.md)

### Constitution Check Re-validation ✅ PASS

**Post-Design Status**: No complexity violations introduced

**Validation**:
- ✅ Pure refactoring - no new features or complexity
- ✅ Test-first principle maintained (existing tests serve as acceptance criteria)
- ✅ All functionality must pass regression tests
- ✅ Simple directory reorganization only, no architectural changes
- ✅ Backward compatibility guaranteed for all user-facing interfaces

**Gate Status**: ✅ PASS - Ready for task breakdown and implementation

## Next Steps

1. ✅ Execute Phase 0: Create research.md - **COMPLETE**
2. ✅ Execute Phase 1: Create data-model.md, contracts/, quickstart.md - **COMPLETE**
3. ✅ Update agent context (CLAUDE.md) - **COMPLETE**
4. ✅ Re-validate Constitution Check post-design - **COMPLETE**
5. ⏭️ **NEXT**: Proceed to `/speckit.tasks` for implementation task breakdown
