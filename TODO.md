
TODO
====
- world class zombie prevention via monitor
- /slash commands
- Run ./scripts/slack_export --hours 24
<internal:/opt/hostedtoolcache/Ruby/3.2.9/x64/lib/ruby/3.2.0/rubygems/core_ext/kernel_require.rb>:86:in `require': cannot load such file -- parallel (LoadError)
	from <internal:/opt/hostedtoolcache/Ruby/3.2.9/x64/lib/ruby/3.2.0/rubygems/core_ext/kernel_require.rb>:86:in `require'
	from ./scripts/slack_export:97:in `<main>'
Error: Process completed with exit code 1.
- ensure streaming inputs is compatible with logs fmt/jsonl

- tc init should `cd ./bin/ && ln -s ../tc/bin/tc ./` iff ./bin/ is present.  aka.  'tc init installs a symlink binstub`.  alternatively, it would write a one line binstub bash script.  most devs have ./bin/ in thier path.

> i want to compact things.  ***K.I.S.S***.  1. 'tc run' should be the default mode, therefore, one can type `./tc/bin/tc`, or, if in $PATH, simply `tc`, to run all tests.

./tc/bin/tc tc/tests --all

DOIN
====

> next, i want to add the following logic to the $path argument (argv[0]) to run.  1. paths are either relative to ./tc/tests, or absolute.  absolute paths start with '.' or '/'.  2. when no tests are specified, or the specic alias @all,
all tests will be run.  later, we will support groups of tests, such as 'tc @auth' or 'tc @feature' to run a configured sub-set of tests

1. heli-cool $stdout : single status line with animating helicopters and shit for test runners

we want ultra simple, ultra sick, output while running tests.  we want a
SINGLE UPDATING status line to log all output.  it should be super clean,
formatting, with animation only varying the width at the last part.  use a
status line like:

single-char-emoji : LOUD-COLORED-LABEL : ... whatever else needed that is uniform width : dangling messages in simple colors that will be nice in all terminals.

keep this status line SIMPLE and KISS.  it MUST work in all shells

this fancy output line should ONLY run when STDOUT is a tty.  otherwise, similar, but no anci colors, esc chars, etc, will be output line oriented.

finally, the fancy output is a HIGH LEVEL SUMMARY of what the test suite is
doing.  we want a super simple, machine readable, log, of the details (path
being run, etc), to be output into a sane location (report.json).  this log
should perhaps be jsonl, or whatever steaming format 'tc' itself handled.
aka, whatever format would be easy to filter with the same strategy as multi
input tests.


DONE
====
