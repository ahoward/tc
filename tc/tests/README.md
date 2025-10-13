# tc tests - dogfooding the chopper 🚁

tc tests itself using tc. meta? yes. awesome? absolutely.

## structure

```
tests/
├── unit/                   # unit tests for individual components
│   └── json-comparison/    # tests semantic json comparison
└── integration/            # integration tests for complete workflows
    ├── single-suite/       # tests running a single suite
    └── hierarchical/       # tests hierarchical --all execution
```

## running tests

```bash
# run all tests
tc run tests --all

# run just unit tests
tc run tests/unit --all

# run just integration tests
tc run tests/integration --all

# run a specific suite
tc run tests/unit/json-comparison
```

## what we test

### unit tests

**json-comparison** - tests tc's semantic json comparison:
- order-independent object comparison
- exact value matching
- mismatch detection

### integration tests

**single-suite** - tests running a complete test suite end-to-end:
- creates a temporary test suite
- runs tc on it
- verifies it passes

**hierarchical** - tests hierarchical test discovery:
- creates multiple test suites
- runs tc --all on them
- verifies all are discovered and executed

## writing new tests

tc tests are just test suites! follow the standard tc structure:

```
my-test/
├── run                 # test runner (can use tc internals)
└── data/
    └── scenario/
        ├── input.json
        └── expected.json
```

### tips for testing tc

1. **use TC_ROOT**: `TC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"`
2. **source tc libs**: access tc internals for unit tests
3. **use temp dirs**: integration tests should create temp suites
4. **clean up**: use `trap "rm -rf $tmpdir" EXIT`

## dogfooding philosophy

we use tc to test tc because:
- **validates the framework**: if tc can't test itself, something's wrong
- **real-world usage**: these are real tests solving real problems
- **documentation by example**: shows how to organize hierarchical tests
- **catches regressions**: changes that break tc will fail its own tests

## continuous improvement

as we add features to tc, we add tests:
- new comparison modes? add unit tests
- parallel execution? add integration tests
- pattern matching? add discovery tests

🚁 **if it flies, test it. if it tests, fly it.**
