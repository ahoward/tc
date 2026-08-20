# Implementation Plan: TC - Language-Agnostic Testing Framework

**Branch**: `001-design-a-testing` | **Date**: 2025-10-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-design-a-testing/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

TC is a language-agnostic testing framework that enables test-driven development across any programming language. Tests are organized in hierarchical directory structures with uniform interfaces, comparing actual vs expected outputs stored as JSON. The framework supports parallel execution, selective test runs, and zero-dependency installation for maximum portability. Primary approach: directory-based test suites with executable test runners, semantic JSON comparison, and line-oriented output formats (JSONL).

## Technical Context

**Language/Version**: Shell script (POSIX-compatible) for core framework, any language for test runners
**Primary Dependencies**: None (zero external dependencies beyond standard POSIX tools: sh, jq for JSON handling, basic coreutils)
**Storage**: File-based (test data as JSON files, results as overwritable JSON files within test directories)
**Testing**: Self-hosted (framework tests itself using its own test suite structure)
**Target Platform**: Linux, macOS, Windows (via WSL or POSIX-compatible shell)
**Project Type**: Single CLI tool project with library components
**Performance Goals**: <10% framework overhead per test suite, 75% time reduction with parallel execution (10+ suites), handle 1000 scenarios without degradation
**Constraints**: Install and run first test in <2 minutes, create new test suite in <5 minutes, zero external dependencies, works identically across platforms
**Scale/Scope**: Support hierarchical test organization, multiple comparison modes (semantic JSON, whitespace normalization, fuzzy), configurable timeouts, CPU-based parallelism

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Initial Check (Pre-Research)

**Status**: ⚠️ NO CONSTITUTION FILE FOUND - Using default principles

Since no project constitution exists yet, applying standard best practices:
- ✅ **Simplicity**: Zero dependencies aligns with KISS principle
- ✅ **Portability**: POSIX-compatible shell ensures cross-platform support
- ✅ **Testability**: Framework will test itself (dogfooding)
- ✅ **CLI-First**: Core interface is command-line driven
- ⚠️ **Constitution Needed**: Recommend creating constitution.md to formalize project principles

### Post-Design Check (After Phase 1)

**Status**: ✅ PASSES - Design adheres to core principles

After completing research and design phases, re-evaluated against best practices:

- ✅ **Simplicity Maintained**:
  - Single binary CLI tool
  - File-based storage (no database)
  - Simple directory structure
  - Minimal dependencies (jq only, widely available)
  - Clear interface contract

- ✅ **Portability Achieved**:
  - POSIX-compatible shell scripts
  - Cross-platform CPU detection
  - No platform-specific code in core framework
  - Test suites portable by design

- ✅ **Testability Confirmed**:
  - Framework dogfoods itself (tests directory uses TC structure)
  - Clear test runner interface
  - Deterministic output comparison
  - Isolated test scenarios

- ✅ **CLI-First Design**:
  - All functionality via command-line
  - Text-based I/O (JSON, JSONL)
  - Stdout for data, stderr for logs
  - No GUI dependencies

- ✅ **Performance Considerations**:
  - Parallel execution by default
  - Auto-scaling to CPU cores
  - Minimal overhead (<10% target)
  - Efficient file-based operations

**Recommendation**: Proceed to task generation. Create constitution.md after implementation to formalize these principles for future features.

## Project Structure

### Documentation (this feature)

```
specs/001-design-a-testing/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── test-suite-interface.md
├── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
└── checklists/
    └── requirements.md  # Quality checklist (completed)
```

### Source Code (repository root)

```
# Option 1: Single project (SELECTED)
# Rationale: CLI tool with library components, no frontend/backend split needed

tc                       # Main executable (entry point)
├── bin/
│   └── tc              # CLI entry point script
├── lib/
│   ├── core/
│   │   ├── runner.sh       # Test suite execution engine
│   │   ├── comparator.sh   # Output comparison (JSON semantic, whitespace, fuzzy)
│   │   ├── parallel.sh     # Parallel execution coordinator
│   │   └── discovery.sh    # Test suite discovery and validation
│   ├── utils/
│   │   ├── json.sh         # JSON parsing/comparison utilities
│   │   ├── timer.sh        # Timeout management
│   │   └── reporter.sh     # Result aggregation and reporting
│   └── config/
│       └── defaults.sh     # Default configuration values
├── tests/
│   ├── unit/               # Unit tests for individual lib components
│   ├── integration/        # Integration tests for full workflows
│   └── fixtures/           # Sample test suites for testing
└── docs/
    ├── README.md
    ├── getting-started.md
    └── test-suite-authoring.md
```

**Structure Decision**: Single project structure selected because:
- CLI tool is the primary interface
- Library components are tightly coupled support modules
- No separate frontend/backend/mobile components
- Shell script architecture naturally fits flat library structure
- Tests directory mirrors source for clear organization

## Complexity Tracking

*No constitution violations to track - clean slate project with simple architecture*

## Phase 0: Research Plan

### Research Questions

Based on Technical Context analysis, the following areas need research:

1. **JSON Comparison in Shell**
   - Question: What's the most portable way to perform semantic JSON comparison in POSIX shell?
   - Why: Need order-independent object comparison without external dependencies
   - Options: jq (if acceptable), pure shell parsing, Python fallback

2. **Cross-Platform Parallelism**
   - Question: How to detect CPU cores and manage parallel execution across Linux/macOS/Windows?
   - Why: Auto-detect CPU cores requirement
   - Options: nproc (Linux), sysctl (macOS), WMIC (Windows), GNU parallel alternatives

3. **Timeout Implementation**
   - Question: How to reliably timeout processes in POSIX shell with configurable per-suite overrides?
   - Why: Required for test execution timeout handling
   - Options: timeout command (if portable), shell traps, background jobs with kill

4. **Test Runner Interface Contract**
   - Question: What's the exact interface contract for test runner executables?
   - Why: Need clear specification for how test runners receive input and produce output
   - Define: stdin format, command-line args, exit codes, stdout/stderr conventions

5. **Result File Format**
   - Question: What should the standard result file structure contain?
   - Why: Need consistent format for result persistence
   - Include: test outcomes, timing, diffs, logs, metadata

6. **Fuzzy Matching Strategy**
   - Question: How to implement configurable fuzzy matching for output comparison?
   - Why: Optional fuzzy matching requirement
   - Options: Threshold-based string distance, regex patterns, tolerance rules

### Research Outputs Expected

- `research.md` with decisions for each question above
- Proof-of-concept snippets for critical components (JSON comparison, parallelism)
- Interface specifications that resolve all NEEDS CLARIFICATION markers

---

## Phase 0 Completion: ✅ COMPLETE

Research document generated: [`research.md`](./research.md)

All technical decisions resolved:
1. **JSON Comparison**: Use `jq` for semantic comparison
2. **Parallelism**: Shell job control with platform-specific CPU detection
3. **Timeouts**: Shell-based with TERM→KILL escalation
4. **Runner Interface**: JSON input/output via files/stdout
5. **Result Format**: JSONL in `.tc-result` files
6. **Fuzzy Matching**: Levenshtein distance with 90% threshold

---

## Phase 1: Design & Contracts

### Phase 1 Artifacts Generated

1. **Data Model** ([`data-model.md`](./data-model.md))
   - Test Suite entity (directory-based)
   - Test Scenario entity (input/output pairs)
   - Test Run entity (execution instance)
   - Scenario Result entity (JSONL format)
   - Suite Configuration entity (INI format)
   - State machines and transitions
   - File I/O patterns and concurrency considerations

2. **Interface Contract** ([`contracts/test-suite-interface.md`](./contracts/test-suite-interface.md))
   - Test runner command-line interface
   - Input file format specification
   - Output JSON schema
   - Exit code conventions
   - Error handling requirements
   - Comparison contract
   - Implementation examples (Bash, Python, Go, Node.js)

3. **Quick Start Guide** ([`quickstart.md`](./quickstart.md))
   - Installation instructions
   - First test suite tutorial
   - Directory structure requirements
   - Common commands reference
   - Test runner examples
   - Configuration guide
   - Troubleshooting tips

### Key Design Decisions

**Architecture**:
- Single CLI executable (`tc`) with library modules
- Shell scripts for core framework (POSIX-compatible)
- Any language for test runners (via interface contract)
- File-based storage (no database)

**Data Flow**:
1. Discovery: Find test suites by directory structure
2. Validation: Check required files exist
3. Execution: Run test runners with input files
4. Comparison: Compare output vs expected (semantic JSON)
5. Reporting: Aggregate results, write `.tc-result`, display summary

**Comparison Modes**:
- **Semantic JSON** (default): Order-independent objects, exact values
- **Whitespace Normalization**: Trim/collapse spaces (configurable)
- **Fuzzy Matching**: Threshold-based similarity (optional)

**Parallelism**:
- Suite-level parallelism by default (auto-detect CPU cores)
- Configurable via `--parallel=N` flag
- Optional per-suite parallel scenario execution

**Configuration**:
- Global defaults in framework
- Suite-level overrides in `.tc-config` (INI format)
- Command-line flags for runtime overrides

---

## Phase 1 Completion: ✅ COMPLETE

All design artifacts generated and validated against constitution.

### Summary of Deliverables

| Artifact | Path | Status |
|----------|------|--------|
| Implementation Plan | `plan.md` | ✅ Complete |
| Research Decisions | `research.md` | ✅ Complete |
| Data Model | `data-model.md` | ✅ Complete |
| Test Suite Interface | `contracts/test-suite-interface.md` | ✅ Complete |
| Quick Start Guide | `quickstart.md` | ✅ Complete |
| Agent Context | `CLAUDE.md` (repo root) | ✅ Updated |

---

## Next Steps

### Phase 2: Task Generation (Not Done by `/speckit.plan`)

Run `/speckit.tasks` to generate actionable implementation tasks in `tasks.md`.

Expected task categories:
1. **Foundation** (P0): CLI entry point, configuration, core utilities
2. **Discovery** (P1): Suite finder, validator, scenario loader
3. **Execution** (P1): Runner invocation, timeout management, result capture
4. **Comparison** (P1): JSON semantic comparison, whitespace mode, fuzzy mode
5. **Parallelism** (P2): Parallel coordinator, CPU detection, job management
6. **Reporting** (P2): Result aggregation, JSONL writer, summary formatter
7. **Testing** (P3): Self-tests, integration tests, CI setup
8. **Documentation** (P3): README, examples, API docs

### Implementation Approach

Recommended order:
1. Foundation & utilities (week 1)
2. Single-suite execution (week 2)
3. Comparison modes (week 3)
4. Parallel execution (week 4)
5. Testing & polish (week 5)

### Success Metrics

Before marking feature complete, verify:
- ✅ User can install and run first test in <2 minutes
- ✅ Create new test suite in <5 minutes
- ✅ Framework overhead <10%
- ✅ Parallel execution achieves 75% time reduction (10+ suites)
- ✅ Works identically on Linux, macOS, Windows (WSL)
- ✅ Zero external dependencies beyond jq
- ✅ Self-tests pass (framework tests itself)

---

## Additional Recommendations

1. **Create Constitution** (After Implementation):
   - Run `/speckit.constitution` to formalize project principles
   - Document: simplicity, portability, CLI-first, testability
   - Establish governance for future features

2. **Example Test Suites**:
   - Create `examples/` directory with sample test runners
   - Include: simple calculation, HTTP API, CLI tool, database query
   - Demonstrate each comparison mode

3. **CI/CD Integration**:
   - Document integration with GitHub Actions, GitLab CI, Jenkins
   - Provide example pipeline configurations
   - Show exit code handling for CI systems

4. **Performance Benchmarking**:
   - Create benchmark suite with 100+ scenarios
   - Measure framework overhead
   - Verify parallel speedup claims
   - Document results

---

**Planning Phase Complete**: Ready for `/speckit.tasks`
