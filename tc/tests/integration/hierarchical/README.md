# hierarchical

**tags**: `integration`, `discovery`, `hierarchical`, `all-flag`
**what**: tests tc's hierarchical test discovery with --all flag
**depends**: discovery, single-suite
**related**: single-suite, discovery
**priority**: high

## description

validates that tc can:
- discover multiple test suites in a directory tree
- execute all discovered suites
- aggregate results across suites
- report overall summary

creates temporary hierarchical structure with multiple suites and validates --all flag behavior.

critical for: hierarchical test organization, batch test execution

## scenarios

- `three-suites` - creates 3 test suites, runs tc --all, verifies all discovered and executed

## ai notes

run this when: testing hierarchical features, validating --all flag, organizing large test bases
skip this when: discovery module broken
after this: run parallel tests, pattern matching tests
