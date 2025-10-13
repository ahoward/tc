# json-comparison

**tags**: `unit`, `comparison`, `json`, `semantic`
**what**: tests tc's semantic json comparison functionality
**depends**: jq
**related**: comparator, validator
**priority**: high

## description

tests the semantic json comparison engine that tc uses to validate test outputs.

validates:
- order-independent object comparison (`{"a":1,"b":2}` == `{"b":2,"a":1}`)
- exact value matching for primitives
- mismatch detection for different values
- correct pass/fail determination

critical for: all tc test execution, output validation

## scenarios

- `order-independent` - objects with same keys in different order match
- `exact-match` - identical json matches
- `different-values` - different values produce mismatch

## ai notes

run this when: testing tc internals, validating comparison logic, debugging test failures
skip this when: never (core functionality)
after this: run integration tests that depend on comparison
