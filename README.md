# tc - theodore calvin's testing framework 🚁

language-agnostic testing for unix hackers

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
# add to PATH
export PATH="$PWD/bin:$PATH"

# run the hello-world example
tc run examples/hello-world
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

## documentation

**[→ read the full docs](docs/readme.md)**

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

- [x] run single test suite
- [x] semantic json comparison (order-independent)
- [x] timeout management
- [x] result persistence (.tc-result files)
- [ ] hierarchical test discovery
- [ ] parallel execution
- [ ] pattern-based selection

## installation

```bash
# clone
git clone https://github.com/you/tc
cd tc

# install jq if needed
brew install jq  # or apt/pacman/etc

# add to PATH or symlink
export PATH="$PWD/bin:$PATH"

# verify
tc --version
```

## license

mit license - see LICENSE

---

made with ☕ and helicopters

*"the chopper's fueled up and ready to go. let's test some code."* — tc

🚁 **fly safe, test well**
