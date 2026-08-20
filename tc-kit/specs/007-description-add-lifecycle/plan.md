# Implementation Plan: Lifecycle Hooks and Stateful Test Runners

**Branch**: `007-description-add-lifecycle` | **Date**: 2025-10-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-description-add-lifecycle/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add lifecycle hooks (setup/teardown/before_each/after_each) and long-running test runner support to tc framework, enabling efficient database testing patterns where a single connection serves multiple test scenarios. Hooks execute bash scripts at key points in test execution, with both per-suite and global scopes. Backward compatible - existing stateless tests continue to work unchanged.

**Primary Requirement**: Support "connect to db once, run all tests" pattern for integration testing
**Technical Approach**: Add hook discovery to executor, implement JSON-based protocol for long-running runners, maintain stateless mode as default

## Technical Context

**Language/Version**: Bash 4.0+ (POSIX-compatible shell scripting)
**Primary Dependencies**: jq (JSON processing), standard POSIX tools (test, chmod, source)
**Storage**: Filesystem-based (hook scripts in test suite directories, .tc-env files for hook state)
**Testing**: tc tests itself (dogfooding) - will create self-testing hooks
**Target Platform**: Unix-like systems (Linux, macOS, Windows/WSL)
**Project Type**: Single framework project with library-based architecture
**Performance Goals**:
  - Hook execution overhead < 10ms per hook
  - Long-running runner overhead < 5ms per test vs stateless mode
  - Database test suite: 10 tests in < 2s (vs 10s+ with current per-test connection)
**Constraints**:
  - 100% backward compatibility (no breaking changes to existing tests)
  - Hooks are opt-in via file presence detection
  - Hook failures must abort suite execution cleanly
**Scale/Scope**:
  - 4 hook types per suite (setup, teardown, before_each, after_each)
  - 2 global hooks (global_setup, global_teardown)
  - Support for 100+ test scenarios in single suite with one database connection

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution Status**: Project constitution not yet defined (template file exists but not filled in).

**Design Principles** (inferred from existing tc codebase):
1. ✅ **POSIX Compatibility**: All code uses bash 4.0+ with POSIX-compatible patterns
2. ✅ **Zero External Dependencies**: Only jq and standard tools (already required)
3. ✅ **Backward Compatibility**: Hooks are optional, opt-in via file presence
4. ✅ **KISS Philosophy**: Simple file-based hook discovery, clear execution order
5. ✅ **Dogfooding**: Will test hooks using tc itself
6. ✅ **Text I/O Protocol**: JSON over stdin/stdout for runner communication

**No violations detected** - feature aligns with established patterns.

## Project Structure

### Documentation (this feature)

```
specs/007-description-add-lifecycle/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - hook patterns, runner protocols
├── data-model.md        # Phase 1 output - hook execution model, state management
├── quickstart.md        # Phase 1 output - database testing example
├── contracts/           # Phase 1 output - runner protocol specification
│   └── runner-protocol.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

**Existing structure** (tc framework in `tc/` subdirectory):
```
tc/
├── bin/
│   └── tc                          # Main entry point (no changes needed)
├── lib/
│   ├── core/
│   │   ├── executor.sh             # MODIFY: Add hook execution before/after scenarios
│   │   ├── discovery.sh            # MODIFY: Add hook discovery functions
│   │   ├── runner.sh               # MODIFY: Add stateful runner mode
│   │   └── hooks.sh                # NEW: Hook management functions
│   ├── utils/
│   │   ├── log.sh                  # USE: Hook execution logging
│   │   └── json.sh                 # USE: Runner protocol JSON handling
│   └── config/
│       └── defaults.sh             # MODIFY: Add hook-related defaults
├── tests/                          # ADD: Hook self-tests
│   ├── unit/hooks/                 # NEW: Unit tests for hook functions
│   └── integration/db-hooks/       # NEW: Example database testing suite
└── examples/
    └── db-integration/             # NEW: Database testing example (PostgreSQL)
```

**Structure Decision**: Single project architecture maintained. Hooks implementation follows existing library organization pattern:
- `tc/lib/core/hooks.sh` - Core hook discovery and execution
- `tc/lib/core/executor.sh` - Modified to integrate hooks into test flow
- `tc/lib/core/runner.sh` - Extended with stateful runner protocol

Hook scripts live in user test suites (not in tc framework):
```
tests/my-db-suite/
├── setup.sh              # User-provided hook
├── before_each.sh        # User-provided hook
├── teardown.sh           # User-provided hook
├── run                   # User-provided test runner
└── data/                 # Test scenarios
```

Global hooks live in:
```
tests/.tc/hooks/
├── global_setup.sh       # Optional global hook
└── global_teardown.sh    # Optional global hook
```

## Complexity Tracking

*No constitution violations to justify.*

This feature adds new optional functionality without increasing mandatory complexity. Stateless mode (current behavior) remains the default.

## Phase 0: Research & Technical Decisions

### Research Questions

1. **Hook Discovery Pattern**: How should tc detect hook scripts?
   - Research: File presence check vs shebang vs metadata file
   - Decision needed: Which pattern is most POSIX-compatible and foolproof

2. **Stateful Runner Protocol**: How should tc communicate with long-running runners?
   - Research: JSON over stdin/stdout vs Unix sockets vs named pipes
   - Decision needed: Most portable approach across Unix variants

3. **Hook Failure Handling**: What happens when hooks fail?
   - Research: Best practices for setup/teardown error handling in test frameworks
   - Decision needed: When to abort, when to continue, exit codes

4. **Environment Variable Passing**: How should hooks share state?
   - Research: .tc-env files vs exported variables vs config files
   - Decision needed: Most reliable cross-shell approach

5. **Global Hook Execution Order**: How do global hooks compose with suite hooks?
   - Research: Test framework precedents (pytest, jest, rspec)
   - Decision needed: Execution order, failure behavior, scope isolation

### Technologies & Best Practices

1. **Bash Hook Execution**:
   - Best practice: Use `source` for .tc-env, `chmod +x` validation, `set -e` in hooks
   - Error handling: Capture stderr, log hook output, timeout protection

2. **JSON Protocol**:
   - Best practice: Line-oriented JSON (JSONL) for streaming, jq for parsing
   - Error handling: Validate JSON before sending to runner

3. **Process Management**:
   - Best practice: Use existing nozombie.sh for cleanup
   - Long-running runners: Track PIDs, implement graceful shutdown

4. **Backward Compatibility**:
   - Best practice: Feature detection (if hooks exist, use them; otherwise skip)
   - Testing: Run all existing tests to verify no breakage

### Dependencies Analysis

**No new external dependencies required**:
- All functionality uses existing bash, jq, and POSIX tools
- Hook scripts written by users (bash recommended, any executable allowed)
- Database examples use PostgreSQL (user's existing installation)

## Phase 1: Design & Contracts

### Design Artifacts To Generate

1. **data-model.md**: Hook execution model
   - Hook lifecycle states
   - Environment variable schema
   - .tc-env file format
   - Hook metadata structure

2. **contracts/runner-protocol.md**: Stateful runner protocol
   - JSON message format for tc → runner
   - JSON response format for runner → tc
   - Shutdown protocol
   - Error handling protocol

3. **quickstart.md**: Database testing walkthrough
   - PostgreSQL setup example
   - Hook scripts (setup.sh, before_each.sh, teardown.sh)
   - Long-running runner example
   - Expected behavior and output

### Key Design Decisions Needed

1. **Hook Discovery Algorithm**:
   - Check for `setup.sh`, `teardown.sh`, `before_each.sh`, `after_each.sh` in suite directory
   - Global hooks: Check `tests/.tc/hooks/` for `global_setup.sh`, `global_teardown.sh`
   - Validation: Must be executable (`chmod +x`), must exit 0 for success

2. **Runner Mode Detection**:
   - Stateful mode: If `setup.sh` exists OR run script has `#!/usr/bin/env tc-stateful-runner` shebang
   - Stateless mode: Default (current behavior)
   - Mode logged for debugging

3. **Hook Execution Order**:
   ```
   1. global_setup.sh (if --all flag)
   2. suite setup.sh
   3. FOR EACH scenario:
      a. before_each.sh
      b. run scenario (stateful or stateless)
      c. after_each.sh (even if scenario failed)
   4. suite teardown.sh (always run, even if tests failed)
   5. global_teardown.sh (if --all flag, always run)
   ```

4. **Environment Variables**:
   ```bash
   TC_SUITE_PATH=/absolute/path/to/suite
   TC_SCENARIO=scenario-name           # Only for before_each/after_each
   TC_DATA_DIR=/path/to/data/scenario  # Only for before_each/after_each
   TC_HOOK_TYPE=setup|teardown|before_each|after_each
   TC_ROOT=/path/to/test/root          # For global hooks
   ```

5. **Hook Failure Behavior**:
   - `setup.sh` fails (exit ≠ 0) → Abort entire suite, mark as error, run teardown.sh
   - `before_each.sh` fails → Skip scenario, mark as error, run after_each.sh, continue to next
   - `after_each.sh` fails → Log warning (to stderr), continue (cleanup failures shouldn't block)
   - `teardown.sh` fails → Log error (to stderr), continue (final cleanup)

6. **Stateful Runner Protocol**:
   ```json
   // tc → runner: Execute test
   {"command": "test", "scenario": "create-user", "input_file": "/path/to/input.json"}

   // runner → tc: Success
   {"status": "pass", "output": "{...actual output...}", "duration_ms": 123}

   // runner → tc: Failure
   {"status": "fail", "output": "{...actual output...}", "duration_ms": 456, "error": "description"}

   // tc → runner: Shutdown
   {"command": "shutdown"}

   // runner → tc: Shutdown acknowledgment
   {"status": "shutdown"}
   ```

## Implementation Phases

### Phase 0: Research (Current Phase)

**Deliverables**:
- `research.md` with answers to all research questions
- Decision log for technical choices
- Alternatives considered and rejected

**Success Criteria**:
- All NEEDS CLARIFICATION items resolved
- Technical approach validated against existing tc patterns

### Phase 1: Design & Contracts (Next Phase)

**Deliverables**:
- `data-model.md` - Hook execution model
- `contracts/runner-protocol.md` - Stateful runner protocol spec
- `quickstart.md` - Database testing example

**Success Criteria**:
- All contracts are clear and testable
- Database example is complete and realistic
- Design reviewed against spec requirements

### Phase 2: Task Breakdown (After Phase 1)

**Command**: `/speckit.tasks`

**Output**: `tasks.md` with dependency-ordered implementation tasks

**Estimated Task Count**: 60-80 tasks across:
- Hook discovery functions
- Hook execution engine
- Stateful runner protocol
- Executor integration
- Self-tests for hooks
- Documentation and examples

### Phase 3: Implementation (After Phase 2)

**Command**: `/speckit.implement`

**Success Criteria**:
- All tests pass (existing + new)
- Database example works end-to-end
- Backward compatibility verified
- Performance benchmarks met

---

## Next Steps

1. **Run Phase 0**: Generate `research.md` by researching hook patterns and protocols
2. **Run Phase 1**: Generate design artifacts based on research findings
3. **Update Agent Context**: Run `.specify/scripts/bash/update-agent-context.sh` to capture new patterns
4. **Validate**: Review artifacts against spec.md requirements
5. **Proceed to Phase 2**: Generate tasks.md with `/speckit.tasks`

**Blocking Questions**: None - all decisions can be made based on existing tc patterns and industry best practices.

**Risk Assessment**: Low - Feature is additive, well-scoped, and follows established patterns. Backward compatibility is guaranteed by opt-in design.
