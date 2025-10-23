# tc-kit: AI-Driven Testing ⚠️ **EXPERIMENTAL**

> **⚠️ WARNING**: tc-kit is experimental and under active development. APIs may change without notice. Use in production at your own risk.

**tc-kit** integrates tc with spec-kit for automatic test generation from specifications, enabling AI-driven development workflows.

## philosophy

In the AI age, specifications and tests are permanent while implementations are disposable. tc-kit bridges this gap:

- **Spec-first**: Write specs, generate tests automatically
- **Language-agnostic**: Tests work with any language implementation
- **Progressive refinement**: Start abstract, refine as you learn
- **Bidirectional traceability**: Always know which tests map to which requirements

## installation

If you're already using [spec-kit](https://github.com/github/spec-kit) in your project, adding tc-kit is simple:

**Option 1: Copy from tc repo** (if you cloned tc):
```bash
# From your project root (where you have .specify/ directory)
cp -r path/to/tc/.specify/scripts/bash/tc-kit-*.sh .specify/scripts/bash/
cp -r path/to/tc/.specify/templates/commands/tc-*.md .specify/templates/commands/

# Optional: Install slash commands for Claude Code
cp .specify/templates/commands/tc-*.md .claude/commands/
```

**Option 2: Manual setup** (create the scripts):
```bash
# Create required directories
mkdir -p .specify/scripts/bash
mkdir -p .specify/templates/commands
mkdir -p tc/spec-kit

# Download scripts (or copy from tc repository)
# - tc-kit-common.sh
# - tc-kit-specify.sh
# - tc-kit-refine.sh
# - tc-kit-validate.sh
```

**Prerequisites**:
- spec-kit already set up in your project (`.specify/` directory exists)
- tc framework installed and in PATH
- bash 4.0+
- jq

**Verify installation**:
```bash
.specify/scripts/bash/tc-kit-specify.sh --help
# Should show usage information
```

## quick start (from scratch)

If you're starting a new project with both spec-kit and tc-kit:

```bash
# 1. Install tc (this repo)
git clone https://github.com/ahoward/tc.git
cd tc
export PATH="$PWD/bin:$PATH"
tc --version  # verify

# 2. Navigate to your project
cd /path/to/your/project

# 3. Install spec-kit (if not already installed)
# See: https://github.com/github/spec-kit

# 4. Copy tc-kit scripts
cp -r /path/to/tc/.specify/scripts/bash/tc-kit-*.sh .specify/scripts/bash/
cp -r /path/to/tc/.specify/templates/commands/tc-*.md .specify/templates/commands/

# 5. Create a feature spec
mkdir -p specs/001-my-feature
cat > specs/001-my-feature/spec.md << 'EOF'
# Feature: My Feature

## User Scenarios

### User Story 1 - Basic Functionality (Priority: P1)

As a user, I want basic functionality so that I can accomplish my goal.

**Acceptance Scenarios**:
1. **Given** valid input, **When** I run the feature, **Then** it returns success
EOF

# 6. Generate tests
.specify/scripts/bash/tc-kit-specify.sh --spec specs/001-my-feature/spec.md

# Output:
# ✓ Generated 1 test scenario
# ✓ Coverage: 100%
# Tests created in: tc/tests/001-my-feature/

# 7. Run tests (they will fail - NOT_IMPLEMENTED)
tc tc/tests/001-my-feature/user-story-01

# 8. Implement the test runner
edit tc/tests/001-my-feature/user-story-01/run

# 9. Run again (should pass after implementation)
tc tc/tests/001-my-feature/user-story-01

# 10. Track maturity
.specify/scripts/bash/tc-kit-refine.sh --suggest

# 11. Validate coverage
.specify/scripts/bash/tc-kit-validate.sh
```

## slash commands

```bash
/tc.specify    # generate tc tests from spec.md
/tc.refine     # track test maturity (concept→exploration→implementation)
/tc.validate   # validate spec-test alignment and coverage
```

## workflow

```bash
# 1. Generate tests from spec
.specify/scripts/bash/tc-kit-specify.sh --spec specs/my-feature/spec.md

# 2. Implement run scripts (tests fail until implemented)
edit tc/tests/my-feature/user-story-01/run

# 3. Analyze maturity progression
.specify/scripts/bash/tc-kit-refine.sh --suggest

# 4. Validate coverage
.specify/scripts/bash/tc-kit-validate.sh
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

tc-kit metadata lives in `tc/spec-kit/`:
- `traceability.json` - bidirectional spec↔test mapping
- `maturity.json` - test maturity levels and signals
- `validation-report.json` - coverage and divergence analysis

## example

```bash
# Start with spec.md containing user stories
cat specs/my-feature/spec.md

# Generate tests
/tc.specify

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
.specify/scripts/bash/tc-kit-specify.sh --dry-run --verbose
# Shows what would be generated without creating files
```

### force regeneration
```bash
.specify/scripts/bash/tc-kit-specify.sh --force
# Overwrites existing tests
```

### strict validation
```bash
.specify/scripts/bash/tc-kit-validate.sh --strict --coverage-threshold 100
# Fails on any warnings or if coverage < 100%
```

### interactive refinement
```bash
.specify/scripts/bash/tc-kit-refine.sh --interactive
# Prompts for each refinement decision
```

## dogfooding

tc-kit tests itself! See `specs/008-explore-the-strategy/` for the full spec and `tc/tests/008-explore-the-strategy/` for the generated tests.

## documentation

- **[Full spec](specs/008-explore-the-strategy/spec.md)** - Complete tc-kit specification
- **[tc framework](README.md)** - Core testing framework
- **[spec-kit](https://github.com/github/spec-kit)** - Specification framework

## contributing

tc-kit is experimental. Feedback, bug reports, and contributions welcome!

## license

MIT License - see LICENSE

---

🚁 **fly safe, test well, stay abstract**
