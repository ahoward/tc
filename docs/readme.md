# tc - theodore calvin's testing framework 🚁

> "i know what you're thinking... and you're right."
> — theodore "tc" calvin, test pilot extraordinaire

<p align="center">
  <img src="tc.jpg" alt="Theodore Calvin - the man, the legend" width="400">
  <br>
  <em>meet theodore "tc" calvin - vietnam vet, helicopter pilot, best friend a guy could have</em>
</p>

**tc** is a language-agnostic testing framework for unix hackers who value simplicity over complexity, portability over dependencies, and helicopters over... well, everything else.

```
     _____
    /     \      tc v1.0.0 - island hopper
   | () () |     testing any language, anywhere
    \  ^  /
     |||||
     |||||
```

## philosophy

test your code the unix way:
- **language-agnostic**: same test suite works for bash, python, rust, go, whatever
- **directory-based**: tests are just folders with a `run` script and data
- **json i/o**: structured input/output using the universal interchange format
- **zero deps**: just jq (and you already have it)
- **portable**: runs on linux, macos, windows/wsl
- **simple**: if you can write a shell script, you can write tests

## quickstart

install tc in <2 minutes:

```bash
# clone the repo
git clone https://github.com/ahoward/tc
cd tc

# add to PATH (or symlink tc/tc to /usr/local/bin)
export PATH="$PWD/bin:$PATH"

# verify jq is installed
which jq || echo "install jq: brew install jq / apt install jq"

# run the hello-world example
tc run examples/hello-world
```

you should see:

```
tc test results
================
suite: hello-world

  ✓ add-negative (18ms)
  ✓ add-positive (22ms)
  ✓ add-zero (15ms)

summary: 3 passed, 0 failed, 0 errors (3 total)
```

🚁 **you just ran your first test suite!**

## anatomy of a test suite

a test suite is dead simple:

```
my-feature/
├── run                    # executable that accepts input.json, outputs json
└── data/
    ├── scenario-1/
    │   ├── input.json     # input to your runner
    │   └── expected.json  # what you expect back
    └── scenario-2/
        ├── input.json
        └── expected.json
```

that's it. no xml, no yaml, no framework cruft.

## writing your first test

let's test a simple "double the number" feature:

```bash
# create test suite
mkdir -p my-app/data/double-five

# write the runner (in any language!)
cat > my-app/run << 'EOF'
#!/usr/bin/env bash
input_file="$1"
n=$(jq -r '.number' "$input_file")
result=$((n * 2))
jq -n --argjson result "$result" '{result: $result}'
EOF
chmod +x my-app/run

# create test scenario
echo '{"number": 5}' > my-app/data/double-five/input.json
echo '{"result": 10}' > my-app/data/double-five/expected.json

# run it!
tc run my-app
```

## test runner contract

your `run` script must follow these rules:

1. **accept one argument**: path to `input.json`
2. **output valid json** to stdout
3. **exit 0** on success, non-zero on error
4. **log to stderr** (tc captures this for debugging)

example runners in different languages:

### bash
```bash
#!/usr/bin/env bash
input_file="$1"
value=$(jq -r '.value' "$input_file")
# do stuff...
jq -n --arg result "$output" '{result: $result}'
```

### python
```python
#!/usr/bin/env python3
import sys, json
with open(sys.argv[1]) as f:
    data = json.load(f)
result = process(data)
print(json.dumps({"result": result}))
```

### go
```go
#!/usr/bin/env go run
// see examples/polyglot/ for full example
```

### rust, ruby, whatever
if it can read json and write json, tc can test it.

## usage

```bash
# run single test suite
tc run ./tests/auth/login

# run all suites in directory tree
tc run ./tests --all

# run all unit tests
tc run ./tests/unit --all

# parallel execution (coming soon)
tc run ./tests --all --parallel=4

# version info
tc --version

# help
tc --help
```

## comparison modes

tc compares output using **semantic json** by default (order-independent for objects):

```json
{"a": 1, "b": 2}  ==  {"b": 2, "a": 1}  ✓ same!
```

arrays are order-sensitive:

```json
[1, 2, 3]  !=  [3, 2, 1]  ✗ different!
```

other modes (configurable):
- `semantic_json`: smart json comparison (default)
- `whitespace_norm`: ignore whitespace differences
- `fuzzy`: approximate matching (coming soon)

## results

tc writes test results to `.tc-result` (jsonl format) in each suite directory:

```json
{"suite":"hello-world","scenario":"add-positive","status":"pass","duration_ms":22,"timestamp":"2025-10-11T23:29:59Z"}
{"suite":"hello-world","scenario":"add-negative","status":"pass","duration_ms":18,"timestamp":"2025-10-11T23:29:59Z"}
```

this lets you debug failures without re-running tests.

## timeouts

tests have a default timeout of 300s (5 minutes). override per-suite:

```bash
# create .tc-config in suite directory
echo "timeout=60" > my-suite/.tc-config
```

if a test times out, tc sends SIGTERM, waits 2s, then SIGKILL if needed.

## installation (detailed)

### requirements
- bash 4.0+ (or compatible shell)
- jq (for json processing)
- linux, macos, or windows/wsl

### install jq
```bash
# macos
brew install jq

# debian/ubuntu
sudo apt install jq

# arch
sudo pacman -S jq

# windows (wsl)
# use your distro's package manager
```

### install tc
```bash
# option 1: add to PATH
git clone https://github.com/ahoward/tc
export PATH="$PWD/tc:$PATH"

# option 2: symlink
git clone https://github.com/ahoward/tc
ln -s "$PWD/tc/tc" /usr/local/bin/tc

# option 3: copy to bin
git clone https://github.com/ahoward/tc
sudo cp -r tc /opt/tc
sudo ln -s /opt/tc/tc /usr/local/bin/tc
```

verify:
```bash
tc --version
```

## why tc?

### before tc:
- write tests in each language's framework
- different test runners for each project
- complicated setup, deps, configs
- can't reuse tests when porting code

### with tc:
- one test suite, any language
- same runner everywhere
- zero-config by default
- port your app, keep your tests

### the helicopter difference 🚁

theodore calvin (tc) wasn't just a pilot—he was a philosopher of the skies. he knew that the best solutions are the simplest ones, that flexibility beats rigidity, and that sometimes you just need to trust your instincts and fly.

tc the framework embodies this: simple, flexible, portable. no framework lock-in, no complex DSLs, just good old unix principles and json.

## hierarchical test organization

organize tests in directories, run them all at once:

```
tests/
├── unit/
│   ├── json-comparison/
│   └── validation/
└── integration/
    ├── single-suite/
    └── hierarchical/
```

```bash
tc run tests --all               # run everything
tc run tests/unit --all          # just unit tests
tc run tests/integration --all   # just integration
```

results are aggregated:
```
====================================
overall results
====================================

suites run: 5
✓ all 12 tests passed
```

## examples

check out `examples/` for:
- `hello-world/` - basic arithmetic (you've seen this)
- `tests/` - tc tests itself! (dogfooding at its finest)
- `polyglot/` - same tests, multiple languages (coming soon)
- `parallel/` - fast parallel execution (coming soon)

## roadmap

- [x] run single test suite (mvp!)
- [x] semantic json comparison
- [x] timeout management
- [x] result persistence
- [x] hierarchical test discovery (--all flag)
- [x] self-tests (dogfooding - tc tests tc!)
- [ ] parallel execution
- [ ] pattern-based selection
- [ ] fuzzy matching mode
- [ ] performance benchmarks

## philosophy (extended)

tc follows unix philosophy:
1. **do one thing well**: run tests, compare outputs
2. **text streams**: json in, json out, results in jsonl
3. **composable**: chain with other tools (jq, grep, etc)
4. **portable**: posix-compatible, minimal deps
5. **hackable**: it's just shell scripts, read the source

test suites are data, not code. this means:
- version control friendly (just files)
- easy to generate programmatically
- language-agnostic by design
- no framework lock-in

## faq

**q: why json and not yaml/toml/xml?**
a: json is universal, fast, and jq exists. plus yaml is a minefield.

**q: why bash and not $LANGUAGE?**
a: portability. bash is everywhere. your test runners can be in any language.

**q: what if i don't have jq?**
a: install it. it's worth it. trust me.

**q: can i use this in ci/cd?**
a: yes! exit codes are standard (0=pass, 1=fail). pipe to whatever you want.

**q: is this production-ready?**
a: it's v1.0, island hopper edition. we're flying! 🚁

**q: what about [feature x]?**
a: probably coming. or send a pr. keep it simple though.

## contributing

found a bug? want a feature? got a better helicopter reference?

1. check if it aligns with unix philosophy
2. keep it simple
3. don't break portability
4. include tests (dogfood!)
5. send a pr

## license

mit license - see LICENSE file

made with ☕ and helicopters

---

*"the chopper's fueled up and ready to go. let's test some code."*
— tc

🚁 **fly safe, test well**
