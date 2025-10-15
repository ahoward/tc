# Implementation Plan: Multi-Language AI Prompt System with Unified Testing

**Branch**: `006-i-want-to` | **Date**: 2025-10-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-i-want-to/spec.md`

## Summary

Create 5 language implementations (Go, Rust, JavaScript, Python 🐍, Ruby) of an AI prompt management system, each providing identical DAO interface for unified testing. Demonstrates system adapter pattern with language-portable tests. KISS approach: minimal viable implementations showcasing the pattern, not production systems.

## Technical Context

**Languages/Versions**:
- Go 1.21+ (compiled, static, strong concurrency)
- Rust 1.75+ (systems, memory-safe, high performance)
- JavaScript/Node.js 18+ (dynamic, async-native)
- Python 3.11+ 🐍 (scripting, AI-friendly)
- Ruby 3.2+ (elegant, expressive - make it really clean!)

**Primary Dependencies**:
- **Go**: Standard library only (encoding/json, crypto/rand for UUIDs)
- **Rust**: serde_json, uuid crates
- **JavaScript**: Built-in JSON, uuid npm package
- **Python**: Built-in json, uuid modules 🐍
- **Ruby**: Built-in JSON, SecureRandom for UUIDs (clean, idiomatic!)

**Storage**: In-memory only (maps/hashes with correlation UUID keys)
**Testing**: tc framework with shared test suite across all languages
**Target Platform**: CLI/stdio adapters for tc integration
**Project Type**: Multiple standalone projects (one per language)
**Performance Goals**: < 100ms for async operation initiation, handle 50 concurrent ops
**Constraints**: Zero external services, simulated AI operations, KISS implementations
**Scale/Scope**: Proof-of-concept demo - 3 operations per language, ~200-300 LOC each

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simplified Constitution for Demo Project**:

###I. KISS Principle (Keep It Simple, Stupid)
- Minimal viable implementation demonstrating pattern
- No unnecessary frameworks or dependencies
- Each language: core DAO + 3 operations + tc adapter
- Standard library preferred over external packages

### II. Language-Portable Testing
- All languages pass same tc test suite
- Test adapters follow tc runner contract (stdin/stdout JSON)
- Identical response format across languages
- No language-specific test modifications

### III. Clean Code Showcase
- Ruby implementation: gem-quality, idiomatic code
- All implementations: clear, readable, well-commented
- Demonstrate language best practices
- Python 🐍: playful theming in comments

### IV. Demo Focus
- Simulated operations (no real AI APIs)
- In-memory storage only
- CLI adapters for tc integration
- Document adapter creation pattern

**Gates**:
- ✅ Simple: 5 standalone mini-projects, no monorepo complexity
- ✅ Testable: Same tc suite works for all
- ✅ Documented: Each project has README with usage
- ✅ Focused: Proof-of-concept, not production

**Violations**: None - this is inherently a multi-project demo

## Project Structure

### Documentation (this feature)

```
specs/006-i-want-to/
├── plan.md              # This file
├── research.md          # Phase 0: Implementation patterns per language
├── data-model.md        # Phase 1: DAO interface spec
├── quickstart.md        # Phase 1: Quick start guide
├── contracts/           # Phase 1: DAO API contract
│   └── dao-api.md       # Interface specification
└── tasks.md             # Phase 2: Task breakdown (via /speckit.tasks)
```

### Source Code (repository root)

```
projects/
├── ruby/
│   ├── lib/
│   │   ├── dao.rb          # DAO interface (clean, idiomatic!)
│   │   ├── operations.rb   # Prompt, template, usage handlers
│   │   └── result_store.rb # In-memory result storage
│   ├── tc_adapter.rb       # tc test adapter (executable)
│   ├── Gemfile             # Dependencies (minimal)
│   └── README.md           # Usage documentation
│
├── go/
│   ├── dao/
│   │   └── dao.go          # DAO interface
│   ├── operations/
│   │   └── operations.go   # Operation handlers
│   ├── store/
│   │   └── store.go        # Result storage
│   ├── adapter/
│   │   └── main.go         # tc adapter (executable)
│   ├── go.mod              # Module definition
│   └── README.md
│
├── rust/
│   ├── src/
│   │   ├── lib.rs          # Library root
│   │   ├── dao.rs          # DAO interface
│   │   ├── operations.rs   # Handlers
│   │   ├── store.rs        # Result storage
│   │   └── bin/
│   │       └── adapter.rs  # tc adapter (binary)
│   ├── Cargo.toml
│   └── README.md
│
├── javascript/
│   ├── lib/
│   │   ├── dao.js          # DAO interface
│   │   ├── operations.js   # Handlers
│   │   └── store.js        # Result storage
│   ├── adapter.js          # tc adapter (executable with #!/usr/bin/env node)
│   ├── package.json
│   └── README.md
│
└── python/
    ├── dao/
    │   ├── __init__.py
    │   └── dao.py          # DAO interface 🐍
    ├── operations/
    │   ├── __init__.py
    │   └── prompt.py       # Handlers 🐍
    ├── store.py            # Result storage 🐍
    ├── adapter.py          # tc adapter (#!/usr/bin/env python3) 🐍
    ├── requirements.txt    # Dependencies (none or minimal)
    └── README.md

tests/
└── multi-lang-dao/
    ├── README.md           # Test suite documentation
    ├── data/
    │   ├── prompt-generate/
    │   │   ├── input.json      # {operation: "/prompt/generate", params: {text: "hello"}}
    │   │   └── expected.json   # {id: "<uuid-pattern>", status: "pending"}
    │   ├── template-create/
    │   │   ├── input.json
    │   │   └── expected.json
    │   ├── template-render/
    │   │   ├── input.json
    │   │   └── expected.json
    │   ├── usage-track/
    │   │   ├── input.json
    │   │   └── expected.json
    │   └── result-poll/
    │       ├── input.json      # {operation: "/result/poll", params: {id: "..."}}
    │       └── expected.json   # {id: "...", status: "completed", result: {...}}
    └── run                     # Symlink to language adapter (e.g., ../../projects/ruby/tc_adapter.rb)
```

**Structure Decision**: Multiple standalone projects (one per language) under `./projects/` directory. Each project is self-contained with its own dependencies, build system, and tc adapter. Shared tc test suite in `./tests/multi-lang-dao/` can be run against any language by changing the `run` symlink.

**Rationale**:
- Demonstrates language independence clearly
- Each project can be understood in isolation
- Easy to add new languages without affecting existing ones
- Mirrors real-world scenario (different teams, different codebases)

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

N/A - No complexity violations. This is intentionally a multi-project demo showcasing pattern applicability across languages.

## Phase 0: Research & Patterns

**Objective**: Determine implementation patterns for each language

**Research Topics**:

1. **DAO Pattern Per Language**
   - Go: Interface + struct implementation
   - Rust: Trait + struct implementation
   - JavaScript: Class or object with methods
   - Python: Class with __call__ or regular methods
   - Ruby: Class with clean method signatures

2. **UUID Generation**
   - Go: crypto/rand + formatting
   - Rust: uuid crate
   - JavaScript: uuid package
   - Python: uuid module (uuid4())
   - Ruby: SecureRandom.uuid

3. **JSON I/O**
   - All languages: stdin/stdout with standard JSON libraries
   - tc adapter contract: executable, read stdin, write stdout

4. **Async Simulation**
   - All: Immediate UUID return, store pending result
   - Background processing: Goroutine/thread/async optional
   - For demo: Can be synchronous with status transitions

5. **In-Memory Storage**
   - Go: sync.Map or map with mutex
   - Rust: Arc<Mutex<HashMap>>
   - JavaScript: Map or plain object
   - Python: dict with threading.Lock if needed
   - Ruby: Hash (thread-safe in MRI with GIL)

**Deliverable**: `research.md` with implementation patterns for each language

## Phase 1: Design & Contracts

**Prerequisites**: `research.md` complete

### 1. Data Model (`data-model.md`)

**Core Entities**:

**OperationRequest**:
- `operation`: String (hierarchical path, e.g., "/prompt/generate")
- `params`: Object (operation-specific parameters)

**OperationResponse**:
- `id`: UUID (correlation ID)
- `status`: Enum ("pending", "completed", "failed")
- `result`: Object (optional, present when status = "completed")
- `error`: String (optional, present when status = "failed")

**ResultStore Entry**:
- Key: UUID
- Value: OperationResponse
- TTL: 1 hour or on first retrieval

**Entities from Demo Domain**:

**Prompt**:
- `text`: String (input prompt text)
- `processed`: String (simulated AI-processed result)
- `timestamp`: DateTime

**Template**:
- `id`: UUID
- `name`: String
- `pattern`: String (template text with {{variables}})
- `variables`: List of String

**UsageEvent**:
- `operation`: String
- `timestamp`: DateTime
- `duration_ms`: Integer

### 2. API Contracts (`contracts/dao-api.md`)

**DAO Interface**:

```
call(operation_path: String, params: Object) -> OperationResponse

Operations:
- /prompt/generate
  Input: {text: String}
  Output: {id: UUID, status: "pending"}

- /template/create
  Input: {name: String, pattern: String, variables: [String]}
  Output: {id: UUID, status: "pending"}

- /template/render
  Input: {template_id: UUID, values: Object}
  Output: {id: UUID, status: "pending"}

- /usage/track
  Input: {operation: String, duration_ms: Integer}
  Output: {id: UUID, status: "completed", result: {tracked: true}}

- /result/poll
  Input: {id: UUID}
  Output: {id: UUID, status: "completed"|"pending"|"failed", result?: Object, error?: String}
```

**TC Adapter Contract**:

```
Executable: {language}/adapter or tc_adapter.{ext}
Input: JSON via stdin
  {
    "operation": "/prompt/generate",
    "params": {"text": "hello world"}
  }

Output: JSON via stdout
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "pending"
  }

Error: JSON via stdout (not stderr for tc compatibility)
  {
    "error": "Invalid operation: /unknown/path"
  }

Exit Code: 0 for success, non-zero for fatal errors
```

### 3. Quickstart Guide (`quickstart.md`)

**Per Language**:

```
# Ruby
cd projects/ruby
bundle install  # (if needed, likely none)
./tc_adapter.rb < input.json

# Go
cd projects/go
go build -o adapter ./adapter
./adapter < input.json

# Rust
cd projects/rust
cargo build --release
./target/release/adapter < input.json

# JavaScript
cd projects/javascript
npm install  # (uuid package)
./adapter.js < input.json

# Python 🐍
cd projects/python
./adapter.py < input.json
```

**Testing**:

```
# Run tc test suite against Ruby
cd tests/multi-lang-dao
ln -sf ../../projects/ruby/tc_adapter.rb run
tc .

# Run against Go
ln -sf ../../projects/go/adapter run
tc .

# Compare all languages
tc . --adapters ruby,go,rust,javascript,python --compare
```

### 4. Agent Context Update

Run `.specify/scripts/bash/update-agent-context.sh claude` to update agent-specific context with:
- Languages: Go, Rust, JavaScript (Node.js), Python, Ruby
- Pattern: DAO interface with async message passing
- Demo domain: AI prompt management

**Deliverables**:
- `data-model.md`
- `contracts/dao-api.md`
- `quickstart.md`
- Updated `.specify/memory/agent-claude.md` (or similar)

## Phase 2: Task Breakdown

**Done via `/speckit.tasks` command** (not part of this plan)

Task generation will create ordered implementation tasks for:
1. Ruby implementation (P1 - showcase clean code)
2. Go implementation (P2 - performance baseline)
3. Python implementation (P3 - 🐍 theming)
4. JavaScript implementation (P3)
5. Rust implementation (P4)
6. Shared tc test suite
7. Comparison testing capability
8. Documentation updates

## Post-Planning Validation

**Constitution Re-Check**:
- ✅ KISS: Minimal implementations, standard libraries
- ✅ Testable: Same test suite, clear contract
- ✅ Clean: Ruby focus, all readable
- ✅ Focused: Demo purpose clear

**Ready for `/speckit.tasks`**: Yes

**Estimated Complexity**: Low-Medium
- 5 similar implementations (~300 LOC each = 1500 LOC total)
- Shared patterns reduce complexity
- Well-defined DAO contract simplifies integration
- tc test suite provides validation

**Risks**:
- Language-specific quirks in JSON/UUID handling (mitigated by research phase)
- Maintaining identical semantics across languages (mitigated by shared test suite)
- Ruby "really clean" subjective standard (mitigated by code review)

**Next Command**: `/speckit.tasks` to generate detailed task breakdown
