keep tc 'ultra tidy' : a refactor in 3 parts


1.
  i want the the source layout to be similar to

  cd project
  ls

    ./tc/run   # <- top level cli
    ./tc/config.sh
    ./tc/tests
    ./tc/tests/ foo/bar/baz /run       # lang specific test runner
    ./tc/tests/ foo/bar/baz /config.sh # test specific config
    ./tc/tests/ foo/bar/baz /tests

    ./tc/tests/ foo/bar/baz /tests/a-feature/
    ./tc/tests/ foo/bar/baz /tests/a-feature/input.json
    ./tc/tests/ foo/bar/baz /tests/a-feature/expected.json
    ./tc/tests/ foo/bar/baz /tests/a-feature/result.json

    ./tc/tests/ foo/bar/baz /tests/another-feature/
    ./tc/tests/ foo/bar/baz /tests/another-feature/input.json
    ./tc/tests/ foo/bar/baz /tests/another-feature/expected.json
    ./tc/tests/ foo/bar/baz /tests/another-feature/result.json


i also want to support running multiple inputs and outputs
