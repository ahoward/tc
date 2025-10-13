# tc - theodore calvin's testing framework 🚁

language-agnostic testing for unix hackers

<p align="center">
  <img src="docs/tc.jpg" alt="Theodore Calvin - the man, the legend" width="400">
  <br>
  <em>theodore "tc" calvin - helicopter pilot, testing framework namesake, legend</em>
</p>

```
       ___
      /___\        tc v1.0.0 - island hopper
     |  o  |       testing any language, anywhere
    _|_____|_
   |_________|     "the chopper's fueled up and ready to go"
     |     |
    / \   / \
   🚁  island hopper
```

## quickstart

```bash
# clone and install
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/tc/bin:$PATH"

# generate your first test
tc new tests/my-feature

# run it (will fail with NOT_IMPLEMENTED)
tc run tests/my-feature

# run the hello-world example
tc run examples/hello-world

# run all tests hierarchically
tc run tests --all
```

## what is tc?

tc is a dead-simple testing framework that lets you:
- test any language with the same test suite
- organize tests as directories with json input/output
- run tests with zero dependencies (just jq)
- port code between languages without rewriting tests

## philosophy

- **simple**: if you can write a shell script, you can write tests
- **portable**: runs everywhere bash and jq exist
- **language-agnostic**: same tests work for bash, python, rust, go, whatever
- **unix**: text streams, composable, do one thing well
- **spec-driven**: in the AI age, the dream of language-agnostic development is real - treat your src/ as a build artifact, specs as the source of truth
- **old-school, new-school**: built with timeless unix tools (tmux, shell, text) for a future where implementation languages are fluid

## commands

```bash
# test execution
tc run <suite-path>         # run single test suite
tc run <path> --all         # run all suites in directory tree
tc run <path> --tags TAG    # run suites matching tag
tc run <path> --parallel    # run all suites in parallel (auto CPU detection)
tc run <path> --parallel N  # run with N parallel workers

# test generation (new!)
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

## documentation

**[→ full docs](docs/readme.md)** | **[→ tc new guide](docs/tc-new.md)**

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
tc run my-feature  # ✓ pass or ✗ fail
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

### prerequisites

- bash 4.0+ (or compatible shell)
- jq (for json processing)

### install jq

```bash
# macos
brew install jq

# ubuntu/debian
sudo apt-get install jq

# fedora/rhel
sudo dnf install jq

# arch
sudo pacman -S jq

# or download from https://jqlang.github.io/jq/
```

### install tc

**option 1: add to PATH (recommended for development)**

Best for trying out tc or active development.

```bash
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/tc/bin:$PATH"
echo 'export PATH="'$PWD'/tc/bin:$PATH"' >> ~/.bashrc  # persist
```

*Pros: Easy to update (git pull), no sudo required, keeps everything in one location*
*Use case: Development, testing, personal projects*

**option 2: symlink to /usr/local/bin**

Lightweight system-wide installation.

```bash
git clone https://github.com/ahoward/tc.git
cd tc
sudo ln -s "$PWD/tc/bin/tc" /usr/local/bin/tc
```

*Pros: System-wide access, still connected to repo for updates*
*Note: Library files remain in cloned directory - don't delete the repo*
*Use case: Personal machines, development systems*

**option 3: copy to /usr/local/bin (recommended for production)**

Full system installation, standalone.

```bash
git clone https://github.com/ahoward/tc.git
cd tc
sudo cp -r tc /usr/local/
export PATH="/usr/local/tc/bin:$PATH"
```

*Pros: True system install, works even if you delete the clone, no git dependency*
*Cons: Must manually update (copy again) when upgrading*
*Use case: Production servers, CI/CD systems, containers*

### verify installation

```bash
tc --version
# tc v1.0.0 - island hopper

tc --help
# shows available commands
```

## license

mit license - see LICENSE

---

made with ☕ and helicopters

*"the chopper's fueled up and ready to go. let's test some code."* — tc

🚁 **fly safe, test well**

## upgrading from pre-1.1 structure

if you have tc installed with the old structure (before v1.1), follow these steps to upgrade:

### for PATH installations

```bash
cd /path/to/tc/repo
git pull
# update your PATH in ~/.bashrc or ~/.zshrc
# OLD (pre-1.0): export PATH="$PWD/bin:$PATH"
# OLD (v1.0): export PATH="$PWD/tc:$PATH"
# NEW (v1.1+): export PATH="$PWD/tc/bin:$PATH"
export PATH="$PWD/tc/bin:$PATH"
tc --version  # verify
```

### for symlink installations

```bash
cd /path/to/tc/repo
git pull
# remove old symlink
sudo rm /usr/local/bin/tc
# create new symlink
sudo ln -s "$PWD/tc/bin/tc" /usr/local/bin/tc
tc --version  # verify
```

### for copy installations

```bash
cd /path/to/tc/repo
git pull
# remove old installation
sudo rm -rf /usr/local/tc /usr/local/lib/tc
# copy new structure
sudo cp -r tc /usr/local/
export PATH="/usr/local/tc/bin:$PATH"
echo 'export PATH="/usr/local/tc/bin:$PATH"' >> ~/.bashrc  # persist
tc --version  # verify
```

