KEEP TC 'ULTRA TIDY' : A REFACTOR IN 3 PARTS ;-) #HELICOPTER-EMOJI

==================================================================
1.  i want the the source layout to be similar to

  cd project
  ls

    ./tc/run   # <- top level cli
    ./tc/config.sh
    ./tc/tests
    ./tc/tests/ foo/bar/baz /run       # lang specific test runner
    ./tc/tests/ foo/bar/baz /config.sh # test specific config
    ./tc/tests/ foo/bar/baz /tests

    ./tc/tests/ foo/bar/baz /tests/a-feature/
    ./tc/tests/ foo/bar/baz /tests/a-feature/stdin.json    # input
    ./tc/tests/ foo/bar/baz /tests/a-feature/stderr.json   # logs, etc
    ./tc/tests/ foo/bar/baz /tests/a-feature/stdout.json   # actual stdout
    ./tc/tests/ foo/bar/baz /tests/a-feature/expected.json # to match against
    ./tc/tests/ foo/bar/baz /tests/a-feature/result.json   # the result, this might need a pattern to gitignore unless trict matching is on... hrm....
                                                           # if so, this should
                                                           # part of 'tc init'

    ./tc/tests/ foo/bar/baz /tests/another-feature/
    ./tc/tests/ foo/bar/baz /tests/another-feature/...


==================================================================
2. support booting a test runner 1x to avoid expensive operations such as
connected to dbs, etc, and then processing multiple pairs of inputs/expected

- this could take the form of streaming muttiple files on stdin in jsonl
  format when no filename is given

- or it could take the form of accepting many files on the cli, although this
  might hit argv size / glob limits...  this is an nice interface if it can
  support arbitrary numbers of tests....


==================================================================
3. global, and per-suite, setup and teardown. in fact, this should 'crawl' up,
meaning all setup.sh and teardown.sh are run, in order, top down, in a
hierarchy

==================================================================
4. make the test output best of all time.  this entails two tasks:

a.) fancy in place colored updater with helicopter emojis (when stdout is a
tty)

b.) a clean (no ansi) report that is created for the run run, and perhaps per
test, that functionally captuers what happened, and when, so a grep or opening
up a file to see the history is possible.  this avoides the 'wall of fucking
text the blows your terminal buffer' problem even if you do know how to use
tmux (doc this ;-), and mock this ;-))


==================================================================
5. per lang sdks to make whatever multi-input approach (jsonl or argv) simple
to integrate with.  eg

```ruby
require 'tc'

tc.tests do |input|
end

```

or similar.  note that this needs to pass, at least:

- the input
- the 'name' of the input
- perhaps config

consider using the ENV to relay global info and keeping the interface similar
for go, rust, python, javascript, and ruby.  implement ALL of these as single
file src files for now.  no build, distribution, as an example for these
lang users




