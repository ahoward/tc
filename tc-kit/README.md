# tc-kit: Spec-Driven Testing Addon ⚠️ **EXPERIMENTAL**

> **⚠️ WARNING**: tc-kit is experimental and under active development. APIs may change without notice. Use in production at your own risk.

**tc-kit** is an optional addon for tc that integrates with spec-kit for automatic test generation from specifications, enabling AI-driven development workflows.

## philosophy

In the AI age, specifications and tests are permanent while implementations are disposable. tc-kit bridges this gap:

- **Spec-first**: Write specs, generate tests automatically
- **Language-agnostic**: Tests work with any language implementation
- **Progressive refinement**: Start abstract, refine as you learn
- **Bidirectional traceability**: Always know which tests map to which requirements

## installation

tc-kit lives in the `tc-kit/` subdirectory of the tc repository. To use it:

**Option 1: Link tc-kit into your project** (recommended):
```bash
# From your project root
ln -s path/to/tc/tc-kit/.specify .specify
ln -s path/to/tc/tc-kit/.claude .claude

# Create directories for your specs and data
mkdir -p specs data
```

**Option 2: Copy tc-kit files**:
```bash
# From your project root
cp -r path/to/tc/tc-kit/.specify .
cp -r path/to/tc/tc-kit/.claude .
mkdir -p specs data
```

**Option 3: Use tc-kit in-place**:
```bash
# Work directly in tc repo
cd path/to/tc
# Everything is already set up
# specs/ → tc-kit/specs/
# data/ → tc-kit/data/
```

**Prerequisites**:
- tc framework installed and in PATH
- bash 4.0+
- jq
- (optional) Claude Code for slash commands

**Verify installation**:
```bash
tc-kit/.specify/scripts/bash/tc-kit-specify.sh --help
# Should show usage information
```

## quick start

```bash
# 1. Ensure tc is in PATH
export PATH="$PWD/tc/bin:$PATH"
tc --version

# 2. Create a feature spec
mkdir -p tc-kit/specs/001-my-feature
cat > tc-kit/specs/001-my-feature/spec.md << 'EOF'
# Feature: My Feature

## User Scenarios

### User Story 1 - Basic Functionality (Priority: P1)

As a user, I want basic functionality so that I can accomplish my goal.

**Acceptance Scenarios**:
1. **Given** valid input, **When** I run the feature, **Then** it returns success
EOF

# 3. Generate tests
tc-kit/.specify/scripts/bash/tc-kit-specify.sh --spec tc-kit/specs/001-my-feature/spec.md

# Output:
# ✓ Generated 1 test scenario
# ✓ Coverage: 100%
# Tests created in: tc/tests/001-my-feature/

# 4. Run tests (they will fail - NOT_IMPLEMENTED)
tc tc/tests/001-my-feature/user-story-01

# 5. Implement the test runner
vim tc/tests/001-my-feature/user-story-01/run

# 6. Run again (should pass after implementation)
tc tc/tests/001-my-feature/user-story-01
```

## slash commands

If using Claude Code with the tc-kit `.claude/commands/` directory:

```bash
/speckit.specify    # create/update feature specification
/speckit.plan       # generate implementation plan
/speckit.tasks      # break down into tasks
/speckit.implement  # execute implementation

/tc-specify         # generate tc tests from spec.md
/tc-refine          # track test maturity
/tc-validate        # validate spec-test alignment
```

## workflow

```bash
# 1. Generate tests from spec
tc-kit/.specify/scripts/bash/tc-kit-specify.sh --spec tc-kit/specs/my-feature/spec.md

# 2. Implement run scripts (tests fail until implemented)
vim tc/tests/my-feature/user-story-01/run

# 3. Analyze maturity progression
tc-kit/.specify/scripts/bash/tc-kit-refine.sh --suggest

# 4. Validate coverage
tc-kit/.specify/scripts/bash/tc-kit-validate.sh
```

## features

- **Language-agnostic test generation** from spec-kit user stories
- **Pattern-based test scaffolding** (<uuid>, <timestamp>, etc.)
- **Maturity tracking** (concept → exploration → implementation)
- **Bidirectional traceability** (spec ↔ test links)
- **Coverage validation** with thresholds and gates
- **Progressive refinement** without breaking baseline tests

## maturity levels

tc-kit tracks tests through three maturity levels:

1. **concept**: Initial tests using patterns (`<uuid>`, `<string>`, etc.)
   - Generated automatically from spec
   - All tests are NOT_IMPLEMENTED
   - Abstract, technology-agnostic

2. **exploration**: Tests with initial implementation
   - Run script has real code
   - May still use patterns for dynamic values
   - Technology-specific but evolving

3. **implementation**: Production-ready tests
   - 5+ consecutive passing runs
   - Concrete assertions where appropriate
   - Stable, well-understood behavior

## state storage

tc-kit metadata lives in `tc-kit/data/`:
- `traceability.json` - bidirectional spec↔test mapping
- `maturity.json` - test maturity levels and signals
- `validation-report.json` - coverage and divergence analysis

## example

```bash
# Start with spec.md containing user stories
cat tc-kit/specs/my-feature/spec.md

# Generate tests
tc-kit/.specify/scripts/bash/tc-kit-specify.sh

# Output:
tc/tests/my-feature/
├── user-story-01/
│   ├── run                    # NOT_IMPLEMENTED template
│   └── data/
│       ├── scenario-01/
│       │   ├── input.json     # generated from Given clause
│       │   └── expected.json  # patterns from Then clause
│       └── scenario-02/
│           ├── input.json
│           └── expected.json
└── user-story-02/
    ├── run
    └── data/...

# Coverage: 100%
# Maturity: concept (all tests use patterns, not yet implemented)
```

## ai-driven development workflow

tc-kit is designed for modern AI-assisted development:

1. **Human writes specs** - Clear requirements in spec-kit format
2. **tc-kit generates tests** - Automatic test scaffolding from specs
3. **AI implements code** - Language models write implementation to pass tests
4. **tc validates** - Language-agnostic verification
5. **Repeat or refactor** - Port to new languages without rewriting tests

This workflow treats implementation as a build artifact while preserving specs and tests as source of truth.

## advanced usage

### dry-run mode
```bash
tc-kit/.specify/scripts/bash/tc-kit-specify.sh --dry-run --verbose
# Shows what would be generated without creating files
```

### force regeneration
```bash
tc-kit/.specify/scripts/bash/tc-kit-specify.sh --force
# Overwrites existing tests
```

### strict validation
```bash
tc-kit/.specify/scripts/bash/tc-kit-validate.sh --strict --coverage-threshold 100
# Fails on any warnings or if coverage < 100%
```

### interactive refinement
```bash
tc-kit/.specify/scripts/bash/tc-kit-refine.sh --interactive
# Prompts for each refinement decision
```

## directory structure

```
tc-kit/
├── .specify/              # Templates and scripts
│   ├── memory/           # Project constitution
│   ├── scripts/bash/     # Workflow automation
│   └── templates/        # Spec/plan/task templates
├── .claude/commands/      # Claude Code slash commands
├── specs/                # Example feature specifications
├── data/                 # Traceability and maturity data
└── docs/                 # Additional documentation
```

## dogfooding

tc-kit tests itself! See `specs/008-explore-the-strategy/` for the full spec.

## documentation

- **[tc framework](../README.md)** - Core testing framework
- **[spec-kit](https://github.com/github/spec-kit)** - Specification framework
- **[Full spec](specs/008-explore-the-strategy/spec.md)** - Complete tc-kit specification

## when to use tc-kit

**Use tc-kit if**:
- You want spec-first development
- You're using AI to generate code
- You need bidirectional traceability
- You work with multiple languages
- You want progressive test refinement

**Skip tc-kit if**:
- You just want a simple test runner (use tc core)
- You prefer test-first over spec-first
- You don't need specification tooling
- You find it adds unnecessary complexity

## contributing

tc-kit is experimental. Feedback, bug reports, and contributions welcome!

## license

MIT License - see LICENSE

---

🚁 **fly safe, test well, stay abstract**
