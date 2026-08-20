# Feature Specification: Lifecycle Hooks and Stateful Test Runners

**Feature**: tc Lifecycle Hooks and Long-Running Runners
**Date**: 2025-10-16
**Status**: Draft
**Priority**: High

## Problem Statement

tc currently spawns a fresh process per test scenario, which is perfect for isolation but impractical for:

1. **Database testing**: Connecting to a database per test is expensive (100-500ms overhead)
2. **API testing**: Booting a server per test wastes time
3. **Docker testing**: Container startup is too slow for per-test isolation
4. **Data seeding**: Need to clear and seed database between tests
5. **Shared fixtures**: Many tests need the same expensive setup

**Current workaround**: None. Users must handle setup/teardown manually in each test's `run` script.

**Real-world impact**: Integration tests are slow and painful to write.

## User Stories

### US1: Database Testing Pattern (Priority: P1)

**As a** developer writing integration tests
**I want to** connect to a database once, then run all tests against it
**So that** my test suite doesn't waste 5 minutes connecting per test

**Acceptance Criteria**:
- [ ] Boot database connection once before all tests
- [ ] Clear and seed data before each test
- [ ] Run all tests against same connection
- [ ] Close connection after all tests
- [ ] Tests still isolated (clean data per test)

**Example**:
```bash
tests/db-integration/
├── setup.sh                 # Run once: connect to database, create schema
├── before_each.sh          # Run per test: clear tables, seed data
├── after_each.sh           # Run per test: cleanup temp data (optional)
├── teardown.sh             # Run once: close connection, drop test schema
├── run                     # Long-running: accepts scenario name via stdin, keeps DB conn alive
└── data/
    ├── create-user/
    ├── update-user/
    └── delete-user/
```

### US2: Long-Running Test Runner (Priority: P1)

**As a** test framework user
**I want** tc to boot my test runner once and feed it multiple tests
**So that** expensive initialization only happens once

**Acceptance Criteria**:
- [ ] Runner process stays alive across multiple test scenarios
- [ ] tc feeds scenario names/data to runner via stdin
- [ ] Runner returns results per test
- [ ] Runner exits cleanly after all tests
- [ ] Falls back to current stateless mode if no setup hooks exist

**Protocol**:
```bash
# tc sends to runner's stdin:
{"scenario": "create-user", "input_file": "/path/to/data/create-user/input.json"}

# Runner responds on stdout:
{"result": {...}, "status": "pass"}

# tc sends next test:
{"scenario": "update-user", "input_file": "/path/to/data/update-user/input.json"}

# At end, tc sends shutdown signal:
{"command": "shutdown"}
```

### US3: Per-Suite Hooks (Priority: P2)

**As a** test suite author
**I want** different lifecycle hooks per test suite
**So that** each suite can manage its own resources

**Acceptance Criteria**:
- [ ] Each suite can have its own setup/teardown/before_each/after_each
- [ ] Hooks are optional (stateless mode still works)
- [ ] Hooks run in correct order
- [ ] Hook failures abort the suite

**Hook execution order**:
```
1. setup.sh (once per suite)
2. for each scenario:
   - before_each.sh
   - run scenario
   - after_each.sh
3. teardown.sh (once per suite)
```

### US4: Global Hooks (Priority: P3)

**As a** project with shared test infrastructure
**I want** global hooks that run for all test suites
**So that** I can manage shared resources (test DB, Docker, etc.)

**Acceptance Criteria**:
- [ ] Global hooks in `tests/.tc/hooks/` directory
- [ ] Run before/after ALL test suites when using `tc tests --all`
- [ ] Per-suite hooks still work independently
- [ ] Global + per-suite hooks compose correctly

**Hook hierarchy**:
```
tests/.tc/hooks/
├── global_setup.sh      # Before ALL suites
├── global_teardown.sh   # After ALL suites
tests/suite-a/
├── setup.sh             # Before suite-a scenarios
├── before_each.sh       # Before each suite-a scenario
└── ...
tests/suite-b/
├── setup.sh             # Before suite-b scenarios
└── ...
```

## Functional Requirements

### FR-001: Long-Running Runner Protocol

**MUST** support long-running test runner processes that:
- Accept test scenarios via stdin (JSON protocol)
- Return results via stdout (JSON protocol)
- Stay alive across multiple test scenarios
- Shut down cleanly on command

**Protocol specification**:
```json
// tc → runner: Execute test
{"command": "test", "scenario": "name", "input_file": "/path/to/input.json"}

// runner → tc: Test result
{"status": "pass|fail|error", "output": "...", "duration_ms": 123}

// tc → runner: Shutdown
{"command": "shutdown"}

// runner → tc: Shutdown acknowledgment
{"status": "shutdown"}
```

### FR-002: Lifecycle Hook Discovery

**MUST** automatically discover and execute hooks in this order:

**Per test suite**:
1. `setup.sh` - Run once before any scenarios (optional)
2. For each scenario:
   - `before_each.sh` - Run before scenario (optional)
   - Execute scenario test
   - `after_each.sh` - Run after scenario (optional)
3. `teardown.sh` - Run once after all scenarios (optional)

**Global** (when using `--all`):
1. `tests/.tc/hooks/global_setup.sh` - Before all suites (optional)
2. Run all suites (with their own hooks)
3. `tests/.tc/hooks/global_teardown.sh` - After all suites (optional)

### FR-003: Hook Script Requirements

All hook scripts **MUST**:
- Be executable (`chmod +x`)
- Exit 0 on success, non-zero on failure
- Write errors to stderr
- Have access to environment variables:
  - `TC_SUITE_PATH` - Absolute path to test suite directory
  - `TC_SCENARIO` - Current scenario name (for before_each/after_each)
  - `TC_DATA_DIR` - Path to scenario data directory
  - `TC_HOOK_TYPE` - Type of hook (setup|teardown|before_each|after_each)

### FR-004: Runner Mode Detection

tc **MUST** automatically detect runner mode:

**Stateful mode** (new):
- Triggers if `setup.sh` exists OR `run` script has `#!/usr/bin/env tc-stateful-runner` shebang
- Boots runner once via `setup.sh`
- Feeds scenarios to long-running `run` process
- Calls `teardown.sh` at end

**Stateless mode** (current):
- Default if no hooks exist
- Spawns fresh `run` process per scenario (current behavior)
- No state shared between tests

### FR-005: Hook Failure Handling

**Hook failures MUST**:
- `setup.sh` fails → Abort entire suite, mark as error
- `before_each.sh` fails → Skip scenario, mark as error, continue to next
- `after_each.sh` fails → Log warning, continue (cleanup failures shouldn't block tests)
- `teardown.sh` fails → Log error, continue (final cleanup)

### FR-006: Environment Variables for Hooks

Hooks **MUST** receive:
```bash
TC_SUITE_PATH=/absolute/path/to/suite
TC_SCENARIO=create-user                    # Only for before_each/after_each
TC_DATA_DIR=/path/to/suite/data/create-user # Only for before_each/after_each
TC_HOOK_TYPE=setup|teardown|before_each|after_each
TC_ROOT=/path/to/test/root                 # For global hooks
```

### FR-007: Backward Compatibility

**MUST** maintain 100% backward compatibility:
- Existing test suites without hooks work exactly as before
- No changes to existing `run` scripts required
- Opt-in via presence of hook scripts

## Success Criteria

**Must Have** (MVP):
- [ ] SC-001: Database test suite connects once, runs 10 tests in < 2s (vs 10s+ currently)
- [ ] SC-002: `setup.sh` and `teardown.sh` run exactly once per suite
- [ ] SC-003: `before_each.sh` runs before every scenario
- [ ] SC-004: Hook failures abort suite appropriately
- [ ] SC-005: All existing tests pass without modification (backward compatible)

**Should Have**:
- [ ] SC-006: Global hooks work for `tc tests --all` runs
- [ ] SC-007: Long-running runner protocol documented with examples
- [ ] SC-008: Hook execution logged with timing information

**Could Have**:
- [ ] SC-009: Parallel execution respects hooks (runs setup/teardown per worker)
- [ ] SC-010: Hook timeout configuration (`TC_HOOK_TIMEOUT`)

## Non-Functional Requirements

- **NFR-001**: Hook execution overhead < 10ms per hook
- **NFR-002**: Long-running runner adds < 5ms overhead per test vs stateless
- **NFR-003**: Hook failures provide clear error messages with script path
- **NFR-004**: Documentation includes database testing example

## Example: Database Testing

```bash
tests/db-integration/
├── setup.sh              # Connect to Postgres, create test schema
├── before_each.sh        # Clear tables, seed base data
├── teardown.sh           # Drop test schema, close connection
├── run                   # Stateful runner: receives scenarios via stdin
└── data/
    ├── create-user/
    │   ├── input.json    # {"name": "Alice", "email": "alice@example.com"}
    │   └── expected.json # {"id": "<uuid>", "created": true}
    └── query-user/
        ├── input.json
        └── expected.json
```

**setup.sh**:
```bash
#!/usr/bin/env bash
# Connect to database, create test schema
export PGDATABASE=test_db_$$
psql -c "CREATE DATABASE $PGDATABASE"
psql -d $PGDATABASE -f schema.sql
echo "TC_DB_NAME=$PGDATABASE" > .tc-env  # Pass to runner
```

**before_each.sh**:
```bash
#!/usr/bin/env bash
# Clear and seed data for each test
source .tc-env
psql -d $TC_DB_NAME -c "TRUNCATE users CASCADE"
psql -d $TC_DB_NAME -f seeds/base_data.sql
```

**run** (stateful runner):
```bash
#!/usr/bin/env bash
# Long-running: handles multiple scenarios
source .tc-env

while read -r line; do
  scenario=$(echo "$line" | jq -r '.scenario')
  input_file=$(echo "$line" | jq -r '.input_file')

  if [ "$scenario" = "shutdown" ]; then
    exit 0
  fi

  # Execute test against database
  result=$(psql -d $TC_DB_NAME -t -c "SELECT run_test('$scenario', '$input_file')")
  echo "$result"
done
```

**teardown.sh**:
```bash
#!/usr/bin/env bash
# Clean up test database
source .tc-env
psql -c "DROP DATABASE $PGDATABASE"
```

## Out of Scope

- Hook scripts in languages other than bash (use bash wrapper to call Python/Ruby/etc.)
- Distributed test execution with hooks (future work)
- Hook dependency management (use setup.sh to check prerequisites)
- Automatic database migrations (use setup.sh to run migrations manually)

## Assumptions

- Users are comfortable writing bash scripts for hooks
- Test suites are already organized in directories
- Users understand the trade-off: stateful = faster but shared state
- Database/API servers are available for testing

## Dependencies

- Existing tc test discovery and execution
- JSONL result format (for logging hook execution)
- Process management (nozombie.sh for cleanup)

## Risks and Mitigations

**Risk**: Stateful runners leak state between tests
**Mitigation**: Clear documentation, `before_each.sh` pattern enforced

**Risk**: Hook failures are hard to debug
**Mitigation**: Log hook execution with timing, stderr capture

**Risk**: Breaking backward compatibility
**Mitigation**: Hooks are opt-in, default behavior unchanged

**Risk**: Parallel execution breaks with stateful runners
**Mitigation**: Each parallel worker gets own setup/teardown, or document limitation

## Open Questions

1. Should global hooks be `tests/.tc/hooks/` or `tests/hooks/`?
2. How to handle hook timeouts? (Default: same as test timeout)
3. Should hooks support templating? (e.g., `setup.sh.erb`)
4. What if `before_each.sh` is slow? (Future: hook caching?)

---

**Next Steps**: Create implementation plan with technical design for hook discovery, execution order, and protocol specification.
