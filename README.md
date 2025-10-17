# tc - theodore calvin's testing framework 🚁

language-agnostic testing for unix hackers

<p align="center">
  <img src="docs/tc.jpg" alt="Theodore Calvin - the man, the legend" width="400">
  <br>
  <em>theodore "tc" calvin - helicopter pilot, testing framework namesake, legend</em>
</p>

```
|=o=o=o=o=o=o=o=o=o=o=o=|      tc v1.0.0 - island hopper
           |                   testing any language, anywhere
       ___/ \___      (o)       🚁 fly safe, test well
     (( tc      ))======\
       \_______/        (o)
         ^   ^
      ^-----------^
```

## TL;DR

**What**: Language-agnostic test framework. Write tests once, run against any language (bash, python, rust, go, whatever).

**How**: Tests are directories. Your code reads `input.json` from stdin, writes `expected.json` to stdout. That's it.

**Get Started**:
```bash
# clone and install
git clone https://github.com/ahoward/tc.git
cd tc

# IMPORTANT: Add to PATH (avoids conflict with Unix traffic control command)
echo 'PATH_add ./tc/bin' > .envrc && direnv allow
# OR: export PATH="$PWD/tc/bin:$PATH"

# verify
tc --version

# try the hello-world example
tc examples/hello-world

# create your first test
tc new tests/my-feature
```

**That's it.** See [full docs](docs/readme.md) for advanced features.

---

## ⚠️  PATH Setup (avoid Unix `tc` conflict)

**`tc` conflicts with the Unix traffic control command.** You MUST add this project's `tc` to your PATH.

**Recommended** (direnv):
```bash
echo 'PATH_add ./tc/bin' > .envrc
direnv allow
```

**Alternative** (manual):
```bash
export PATH="$PWD/tc/bin:$PATH"
```

**Verify**:
```bash
which tc        # should show: ./tc/bin/tc (NOT /usr/sbin/tc)
tc --version    # should show: tc v1.0.0 - island hopper
```

---

## what is tc?

tc is a dead-simple testing framework that lets you:
- test any language with the same test suite
- organize tests as directories with json input/output
- run tests with zero dependencies (just jq)
- port code between languages without rewriting tests

### quine-like behavior

tc has a unique self-referential property: it knows the difference between running its own tests and running your tests.

**in the TC development repo:**
- `tc examples --all` → runs example tests only
- `tc tc/tests --all` → runs TC's framework self-tests
- `tc list .` → shows examples (not tc/tests)

**when installed in your project:**
- `tc tests --all` → runs your project's tests
- tc's self-tests (`tc/tests/`) are included in the installation but invisible to discovery
- the same binary behaves contextually based on what it finds

*** this means you can vendor TC into your project, and it naturally adapts to run your tests instead of its own. ***

## philosophy

**simple** • **portable** • **language-agnostic** • **unix** • **spec-driven**

Tests are the spec. Code is disposable. In the AI age, treat your implementation as a build artifact.

## 🔬 experimental: multi-language dao demo

See `projects/` and `examples/multi-lang-dao/` for a working example of identical DAO interfaces in 5 languages (Ruby, Go, Python, JavaScript, Rust) all passing the same test suite.

**Vision**: Disposable applications. Swap languages freely, keep tests forever.

See [docs/THEORY.md](docs/THEORY.md) for the full system adapter pattern vision.

## commands

```bash
# test execution
tc                          # run all tests (KISS!)
tc <suite-path>             # run single test suite
tc <path> --all             # run all suites in directory tree
tc <path> --tags TAG        # run suites matching tag
tc <path> --parallel        # run all suites in parallel (auto CPU detection)
tc <path> --parallel N      # run with N parallel workers

# test generation
tc new <test-path>          # generate new test suite
tc init [directory]         # initialize test directory with README

# discovery & metadata
tc list [path]              # list all test suites with metadata
tc tags [path]              # show all available tags
tc explain <suite>          # explain what a test suite does

# info
tc --version                # show version
tc --help                   # show help
```

## output modes

**TTY mode** (terminal): Clean single-line status with 🚁 spinner, fail-fast behavior
**Non-TTY mode** (CI/CD): Traditional verbose output with full logs
**Override**: `TC_FANCY_OUTPUT=true/false`

## documentation

**[→ full docs](docs/readme.md)** | **[→ tc new guide](docs/tc-new.md)** | **[→ system adapter theory](docs/THEORY.md)** *(WIP)*

## example

```
my-feature/
├── run                    # executable: reads input.json, writes json to stdout
└── data/
    └── scenario-1/
        ├── input.json     # test input
        └── expected.json  # expected output
```

```bash
tc my-feature  # ✓ pass or ✗ fail
```

## features

**test execution:**
- [x] run single test suite
- [x] semantic json comparison (order-independent)
- [x] timeout management
- [x] result persistence (.tc-result files)
- [x] hierarchical test discovery (--all flag)
- [x] tag-based filtering (--tags flag)
- [x] parallel execution (--parallel flag, auto-detect CPU cores)
- [x] single-line animated status (TTY mode: helicopter 🚁, spinner, colors)
- [x] fail-fast on first error (TTY mode stops immediately, shows log path)
- [x] final stats summary (colored counts: passed/failed/errors, cumulative time)
- [x] traditional verbose output (non-TTY mode for CI/CD)
- [x] machine-readable logs (JSONL format in `.tc-reports/report.jsonl`)

**test generation:**
- [x] scaffold generation (`tc new`)
- [x] test directory initialization (`tc init`)
- [x] metadata flags (--tags, --priority, --description)
- [x] template system (--from, --list-examples)
- [x] TDD workflow (tests fail until implemented)

**discovery & metadata:**
- [x] list all tests (`tc list`)
- [x] show available tags (`tc tags`)
- [x] explain test suite (`tc explain`)
- [x] AI-friendly metadata format

**quality:**
- [x] dogfooding (tc tests itself!)

**roadmap:**
- [ ] pattern-based selection
- [ ] distributed test execution

## installation

**Prerequisites**: bash 4.0+, jq, direnv (recommended)

```bash
# Install dependencies
brew install jq direnv              # macOS
sudo apt-get install jq direnv      # Ubuntu/Debian

# Add direnv to shell
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc && source ~/.bashrc

# Clone tc
git clone https://github.com/ahoward/tc.git
cd tc

# Setup PATH (recommended: direnv)
echo 'PATH_add ./tc/bin' > .envrc && direnv allow

# Verify
tc --version
```

See the [TL;DR](#tldr) section above for PATH setup details.

## license

mit license - see LICENSE

---

made with ☕ and helicopters

*"the chopper's fueled up and ready to go. let's test some code."* — tc

🚁 **fly safe, test well**

