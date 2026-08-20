# Implementation Plan: Heli-Cool Stdout - Animated Test Runner Output

**Branch**: `004-heli-cool-stdout` | **Date**: 2025-10-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-heli-cool-stdout/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement single-line animated status output for TC test runner with TTY detection. Primary requirement: replace multi-line scrolling test output with a clean, updating status line showing real-time progress. Technical approach: detect TTY mode, use ANSI escape codes for in-place updates in terminals, fall back to line-oriented plain text for CI/CD. Secondary requirement: persist detailed execution logs as JSONL for machine parsing.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible shell scripting)
**Primary Dependencies**: Existing TC framework, jq (already required), standard POSIX tools (test, printf, tput)
**Storage**: JSONL files (`.tc-reports/report.jsonl`)
**Testing**: TC's own test framework (dogfooding)
**Target Platform**: Unix-like systems (Linux, macOS, WSL) with terminal emulators
**Project Type**: Single project (shell library extension)
**Performance Goals**: Status line updates must not add >50ms overhead per test, animation updates ~10Hz
**Constraints**: Must work in 95% of terminal emulators, zero dependencies beyond POSIX + jq, no breaking changes to existing TC API
**Scale/Scope**: Thousands of test scenarios per run, terminal widths 40-200 chars

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: ✅ PASS (No constitution file exists - project has no formal constraints beyond spec requirements)

Since there's no constitution.md with formal principles, we proceed with common best practices:
- Maintain existing TC architecture patterns
- Zero breaking changes to public APIs
- Preserve POSIX compatibility
- Keep dependencies minimal
- Follow existing test structure (dogfooding)

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
tc/
├── bin/
│   └── tc                    # Main CLI (updated to use new output modules)
├── lib/
│   ├── core/
│   │   ├── executor.sh       # Updated: integrate status line output
│   │   └── runner.sh         # Updated: integrate status line output
│   └── utils/
│       ├── reporter.sh       # Updated: TTY-aware reporting
│       ├── status-line.sh    # NEW: Single-line TTY output
│       ├── ansi.sh           # NEW: ANSI escape code utilities
│       └── log-writer.sh     # NEW: JSONL log file writer
├── config/
│   └── defaults.sh           # Updated: add TC_REPORT_DIR, TC_FANCY_OUTPUT env vars
└── tests/
    └── integration/
        └── heli-output/      # NEW: Test suite for fancy output feature
```

**Structure Decision**: Extend existing TC architecture with new utility modules. Status line logic lives in `utils/` alongside existing reporter. Core execution modules (executor.sh, runner.sh) integrate status line calls. No changes to public CLI interface - behavior adapts based on TTY detection.

## Complexity Tracking

*No violations - this section is not applicable.*

The feature adds orthogonal functionality (output formatting) without violating any architectural principles.
