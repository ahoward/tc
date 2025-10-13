# Implementation Plan: Test Suite Generator

**Branch**: `002-we-need-a` | **Date**: 2025-10-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-we-need-a/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a `tc new` command that generates complete test suite scaffolding with failing tests and clear next-step guidance. Developers can quickly bootstrap new tests following TDD principles, with automatic integration into tc's metadata and discovery system.

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible shell scripting)
**Primary Dependencies**: jq (JSON processing), existing tc framework
**Storage**: File system (generated templates and directories)
**Testing**: tc itself (dogfooding - test generator with tc)
**Target Platform**: Linux, macOS, Windows/WSL (anywhere bash runs)
**Project Type**: Single project (command-line tool extension)
**Performance Goals**: <10 seconds for complete test suite generation
**Constraints**: Must work offline, zero network dependencies, minimal disk I/O
**Scale/Scope**: Generate typical test structure (3-5 files, 1-3 subdirectories)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution Status**: Project does not have a formal constitution file yet (template placeholders present).

**General Best Practices Applied**:
- **Test-First**: Generator itself will be tested using tc (dogfooding)
- **CLI Interface**: Pure command-line tool following tc's existing patterns
- **Simplicity**: Minimal feature set for MVP, uses existing tc infrastructure
- **No External Dependencies**: Only bash, jq (already required by tc)

**No violations detected** - feature aligns with tc's unix hacker philosophy and existing patterns.

## Project Structure

### Documentation (this feature)

```
specs/002-we-need-a/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (templates, best practices)
├── data-model.md        # Phase 1 output (template structure)
├── quickstart.md        # Phase 1 output (usage guide)
├── contracts/           # Phase 1 output (template format contract)
└── checklists/          # Quality validation
    └── requirements.md  # Spec validation checklist (completed)
```

### Source Code (repository root)

```
# Single project structure (tc framework extension)
bin/
└── tc                   # Main CLI - add 'new' command

lib/
├── core/
│   ├── generator.sh     # NEW: Test generation engine
│   └── templates.sh     # NEW: Template management
└── templates/           # NEW: Built-in templates
    ├── default/         # Default test suite template
    │   ├── run.template
    │   ├── README.template
    │   ├── input.template
    │   └── expected.template
    └── examples/        # Links to existing examples

tests/
├── unit/
│   └── generator/       # NEW: Test generator unit tests
└── integration/
    └── tc-new/          # NEW: Test 'tc new' command end-to-end
```

**Structure Decision**: Extends existing single-project tc framework. Generator logic lives in `lib/core/` alongside existing modules. Templates stored in `lib/templates/` for easy access. Follows tc's established pattern of shell libraries sourced by main `bin/tc` entry point.

## Complexity Tracking

*No violations to justify - feature is straightforward extension of existing CLI*

## Phase 0: Research

### Research Questions

1. **Template Format**: How should templates handle variable substitution (test name, paths, metadata)?
2. **Error Messaging**: What makes a "clear" failing test error message that guides users to next steps?
3. **Directory Detection**: Best practices for detecting tc repository root from any subdirectory?
4. **Name Validation**: Standard regex/patterns for valid test suite names (Unix filename conventions)?
5. **Template Discovery**: How to find and list available templates (built-in vs. example-based)?

### Research Tasks

- **Template Systems**: Survey common approaches (envsubst, sed, heredocs, jq templates)
- **TDD Patterns**: Research failing test patterns that clearly indicate "TODO: implement"
- **CLI Scaffolding**: Best practices from similar tools (rails generate, cargo new, etc.)
- **Path Handling**: Robust methods for nested directory creation and validation
- **Metadata Standards**: Ensure generated README matches existing tc metadata format

*Detailed findings to be documented in research.md*

