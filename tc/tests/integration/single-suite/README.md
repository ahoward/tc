# single-suite

**tags**: `integration`, `end-to-end`, `execution`, `core`
**what**: tests tc's ability to execute a complete test suite end-to-end
**depends**: all-core-modules
**related**: hierarchical, executor
**priority**: high

## description

integration test that validates tc can:
- discover a test suite
- execute the runner with input
- compare output against expected
- report pass/fail correctly

creates a temporary test suite dynamically and runs tc against it.

critical for: core tc functionality, regression testing

## scenarios

- `passing-suite` - creates simple suite that should pass, verifies tc reports success

## ai notes

run this when: testing tc execution flow, validating core features, regression testing
skip this when: core modules are known broken
after this: run hierarchical tests, parallel tests
