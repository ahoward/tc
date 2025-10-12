# tc - theodore calvin's testing framework 🚁

language-agnostic testing for unix hackers

<p align="center">
  <img src="docs/tc.jpg" alt="Theodore Calvin - the man, the legend" width="400">
  <br>
  <em>theodore "tc" calvin - helicopter pilot, testing framework namesake, legend</em>
</p>

```
     _____
    /     \      tc v1.0.0 - island hopper
   | () () |     testing any language, anywhere
    \  ^  /
     |||||
     |||||
```

## quickstart

```bash
# clone and install
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/bin:$PATH"

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

## commands

```bash
# test execution
tc run <suite-path>         # run single test suite
tc run <path> --all         # run all suites in directory tree
tc run <path> --tags TAG    # run suites matching tag

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
- [ ] parallel execution
- [ ] pattern-based selection

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

**option 1: add to PATH (development)**

```bash
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/bin:$PATH"
echo 'export PATH="'$PWD'/bin:$PATH"' >> ~/.bashrc  # persist
```

**option 2: symlink to /usr/local/bin**

```bash
git clone https://github.com/ahoward/tc.git
cd tc
sudo ln -s "$PWD/bin/tc" /usr/local/bin/tc
```

**option 3: copy to /usr/local/bin**

```bash
git clone https://github.com/ahoward/tc.git
cd tc
sudo cp -r bin lib /usr/local/
```

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
