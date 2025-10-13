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

## ⚠️  IMPORTANT: `tc` is a Unix builtin command!

**`tc` is a traffic control command on many Unix systems.** You MUST ensure your project's `tc` comes first in PATH.

### Recommended Setup (direnv)

Create `.envrc` in your project root:
```bash
# .envrc
PATH_add ./tc/bin
```

Then run `direnv allow` once. Your shell will automatically use the correct `tc` when you `cd` into your project.

**Without direnv**, you'll need to manually set PATH per-project:
```bash
export PATH="$PWD/tc/bin:$PATH"
```

**Verify you're using the right tc:**
```bash
which tc
# Should show: /your/project/tc/bin/tc (NOT /usr/sbin/tc)

tc --version
# Should show: tc v1.0.0 - island hopper (NOT traffic control info)
```

## quickstart

```bash
# clone and install
git clone https://github.com/ahoward/tc.git
cd tc

# CRITICAL: Add tc to PATH for this project
export PATH="$PWD/tc/bin:$PATH"
# Better: use direnv (see above)

# verify you're running the right tc
which tc  # should show ./tc/bin/tc

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

### quine-like behavior

tc has a unique self-referential property: it knows the difference between running its own tests and running your tests.

**in the TC development repo:**
- `tc run examples --all` → runs example tests only
- `tc run tc/tests --all` → runs TC's framework self-tests
- `tc list .` → shows examples (not tc/tests)

**when installed in your project:**
- `tc run tests --all` → runs your project's tests
- tc's self-tests (`tc/tests/`) are included in the installation but invisible to discovery
- the same binary behaves contextually based on what it finds

this means you can vendor TC into your project, and it naturally adapts to run your tests instead of its own.

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
- [x] fancy animated output (TTY-aware with colors, emoji, spinner)
- [x] machine-readable logs (JSONL format for analysis)

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

### ⚠️  Name Collision Warning

**CRITICAL**: `tc` conflicts with the Unix traffic control command (`/usr/sbin/tc`).

You MUST use per-project PATH management to ensure the correct `tc` runs:

**✅ RECOMMENDED: Use direnv**
```bash
# In your project root:
echo 'PATH_add ./tc/bin' > .envrc
direnv allow
```

**⚠️  ALTERNATIVE: Manual PATH per shell session**
```bash
export PATH="$PWD/tc/bin:$PATH"
```

**❌ DO NOT install to /usr/local/bin or system-wide locations** - this will conflict with system `tc` command.

**Always verify:**
```bash
which tc          # must show: ./tc/bin/tc
tc --version      # must show: tc v1.0.0 - island hopper
```

### prerequisites

- bash 4.0+ (or compatible shell)
- jq (for json processing)
- **direnv** (highly recommended for PATH management)

### install direnv (recommended)

```bash
# macos
brew install direnv

# ubuntu/debian
sudo apt-get install direnv

# fedora/rhel
sudo dnf install direnv

# arch
sudo pacman -S direnv

# then add to your shell (bash example):
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc

# for other shells: https://direnv.net/docs/hook.html
```

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

**RECOMMENDED: per-project installation with direnv**

Best practice to avoid conflicts with Unix `tc` command.

```bash
# In your project root:
git clone https://github.com/ahoward/tc.git

# Create .envrc for automatic PATH management
echo 'PATH_add ./tc/bin' > .envrc
direnv allow

# Verify
which tc          # should show: ./tc/bin/tc
tc --version      # should show: tc v1.0.0 - island hopper
```

*Pros: No conflicts, automatic PATH switching, clean per-project isolation*
*Use case: ALL projects - this is the recommended approach*

**ALTERNATIVE: manual PATH per-project**

Without direnv, you'll need to set PATH manually:

```bash
# In your project root:
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/tc/bin:$PATH"

# Add to shell config (optional, but remember - this affects ALL projects):
echo 'export PATH="'$PWD'/tc/bin:$PATH"' >> ~/.bashrc
```

*Pros: Simple, no extra tools*
*Cons: Manual PATH management, easy to forget*
*Use case: Quick testing, single project*

**❌ NOT RECOMMENDED: system-wide installation**

Installing tc system-wide creates conflicts with Unix traffic control command.

If you absolutely must:
```bash
git clone https://github.com/ahoward/tc.git
cd tc
# Option: Copy to /opt/tc and add to PATH
sudo cp -r tc /opt/tc
export PATH="/opt/tc/bin:$PATH"
```

*⚠️  Warning: May conflict with system tc command*
*⚠️  You'll need to always use full path: /opt/tc/bin/tc*
*Use case: Containers, CI systems where you control the environment*

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

### ⚠️  IMPORTANT: Switch to direnv (recommended)

The old global PATH approach conflicts with Unix `tc` command. Switch to per-project direnv:

```bash
cd /path/to/tc/repo
git pull

# Remove old global PATH from shell config
# Delete these lines from ~/.bashrc or ~/.zshrc:
#   export PATH="/path/to/tc/bin:$PATH"
#   export PATH="/path/to/tc/tc:$PATH"

# Install direnv (if not already)
brew install direnv  # or apt-get, dnf, etc.
eval "$(direnv hook bash)"  # add to ~/.bashrc

# Create .envrc in tc repo
echo 'PATH_add ./tc/bin' > .envrc
direnv allow

# Verify
which tc        # should show ./tc/bin/tc
tc --version    # verify
```

### for manual PATH installations (not recommended)

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

**⚠️  Warning**: This still conflicts with system `tc`. Use direnv instead.

### for symlink installations (migrate to direnv)

**Old symlink approach conflicts with system tc. Switch to direnv:**

```bash
cd /path/to/tc/repo
git pull

# Remove old symlink
sudo rm /usr/local/bin/tc

# Use direnv instead (see above)
echo 'PATH_add ./tc/bin' > .envrc
direnv allow
```

### for copy installations (migrate to direnv)

**Old copy approach conflicts with system tc. Switch to direnv:**

```bash
cd /path/to/tc/repo
git pull

# Remove old installation
sudo rm -rf /usr/local/tc

# Use direnv instead (see above)
echo 'PATH_add ./tc/bin' > .envrc
direnv allow
```

