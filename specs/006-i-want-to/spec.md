# Feature Specification: Multi-Language AI Prompt System with Unified Testing

**Feature Branch**: `006-i-want-to`
**Created**: 2025-10-15
**Status**: Draft
**Input**: User description: "i want to generate sample projects in go, rust, js, python (tease this pythong, w emoji), and ruby.  make the ruby one *really* clean.  create these in ./projects/$lang.  each one should implmenet the same demo system, something modern, ai, and/or crypto related, from a vhhl (very high level).   we want a unified 'api' (dao/ data access object) implemented for each lang that 1. supports a simple, hierarchical namespaced, interface for exercising all functions in the system.  eg `dao.call('/user/login/google', params = {}) #=> result (hash)`  we need to consider the 'best' interface for concurrency.  i think this is going to come down to a pub/sub msg passing interface where everything is just sending messages, thus, the result should come back with a uuid, key'd to it's initial call.  essentially, an async or status=201 style interface.  this supports modern frameworks which lean towards being async.  our aim is to test all $lang systems *with the same tc suite*, providing nothing but the adapter that calls into the $lang system, as glue.  we may need to do dedicated runs in each of these systems independently later, but we do aim to get a working, very simple, implementation for each with this spec."

## User Scenarios & Testing

### User Story 1 - Unified DAO Interface Across Languages (Priority: P1)

A developer wants to implement the same AI prompt system in multiple languages (Go, Rust, JavaScript, Python 🐍, Ruby). Each implementation provides identical functionality through a uniform DAO (Data Access Object) interface that accepts hierarchical operation paths and returns consistent results.

**Why this priority**: This is the core value - proving the system adapter pattern works by having identical interfaces across 5 different languages.

**Independent Test**: Can be tested by calling a single operation (e.g., `dao.call('/prompt/generate', params)`) in each language and verifying identical response structure across all implementations.

**Acceptance Scenarios**:

1. **Given** a prompt generation request, **When** calling `dao.call('/prompt/generate', {text: "hello"})` in Go, **Then** system returns `{id: "<uuid>", status: "pending"}`
2. **Given** the same request, **When** calling in Ruby, Python, JavaScript, Rust, **Then** all return identical response structure
3. **Given** hierarchical operation path `/user/auth/google`, **When** called with valid params, **Then** DAO routes to correct handler
4. **Given** invalid operation path `/invalid/path`, **When** called, **Then** returns error with consistent format across all languages

---

### User Story 2 - Async Message-Based Results (Priority: P2)

The system handles operations asynchronously using message-passing. When an operation is invoked, the caller receives a correlation UUID immediately. The caller can poll or subscribe to get the final result when the operation completes.

**Why this priority**: Modern systems are async-first. This enables realistic testing of concurrent operations and matches how production systems work.

**Independent Test**: Can be tested by invoking a long-running operation, verifying immediate UUID response, then polling with the UUID to retrieve the completed result.

**Acceptance Scenarios**:

1. **Given** a prompt generation request, **When** operation is invoked, **Then** caller receives `{id: "<uuid>", status: "pending"}` immediately (< 100ms)
2. **Given** correlation UUID from previous call, **When** caller polls with UUID, **Then** system returns current status (`pending`, `completed`, `failed`)
3. **Given** completed operation, **When** retrieving result by UUID, **Then** system returns `{id: "<uuid>", status: "completed", result: {...}}`
4. **Given** multiple concurrent operations, **When** invoked with different params, **Then** each receives unique UUID and results don't interfere

---

### User Story 3 - Shared Test Suite Across Implementations (Priority: P3)

A QA engineer wants to run the same tc test suite against all 5 language implementations. Each language provides a thin adapter that translates tc's input/output format to the DAO interface. Tests verify functional correctness and can compare performance across languages.

**Why this priority**: Validates the system adapter pattern - tests outlive implementations, enabling language portability.

**Independent Test**: Can be tested by running tc test suite against 2+ language adapters and verifying identical pass/fail results (assuming correct implementations).

**Acceptance Scenarios**:

1. **Given** tc test suite with 10 test scenarios, **When** run against Go adapter, **Then** all 10 tests execute and report pass/fail
2. **Given** same test suite, **When** run against Ruby, Python, JavaScript, Rust adapters, **Then** test results are identical (if implementations correct)
3. **Given** test adapter for a language, **When** adapter receives tc input JSON, **Then** adapter calls DAO and returns result in tc format
4. **Given** comparison mode enabled, **When** running against all adapters, **Then** tc generates report showing pass rates and performance per language

---

### User Story 4 - AI Prompt System Demo Application (Priority: P4)

Each language implementation demonstrates an AI prompt management system with operations for generating prompts, managing templates, and tracking usage. The demo showcases modern AI workflows at a high level without requiring actual AI API integration.

**Why this priority**: Provides realistic, modern demo context. Nice-to-have for demonstration, but system works without specific domain logic.

**Independent Test**: Can be tested by invoking prompt operations (`/prompt/generate`, `/template/create`, `/usage/track`) and verifying expected business logic behavior.

**Acceptance Scenarios**:

1. **Given** prompt text, **When** calling `/prompt/generate`, **Then** system processes prompt and returns generated result
2. **Given** template definition, **When** calling `/template/create`, **Then** system stores template with UUID identifier
3. **Given** template UUID and variables, **When** calling `/template/render`, **Then** system renders template with provided variables
4. **Given** usage event, **When** calling `/usage/track`, **Then** system records event for analytics

---

### Edge Cases

- What happens when DAO receives malformed operation path (e.g., `//double/slash`, `/trailing/`)? (Return validation error)
- How does system handle operation that doesn't exist? (Return 404-style error with available operations list)
- What if async operation never completes (hangs)? (Timeout mechanism, return timeout status after threshold)
- How to handle operations that return very large results? (Stream results or paginate response)
- What if two operations try to modify same resource concurrently? (Use message queue ordering or optimistic locking)
- How are correlation UUIDs stored and retrieved? (In-memory store with TTL, cleaned up after retrieval or timeout)
- What if caller polls with invalid/expired UUID? (Return error indicating UUID not found or expired)

## Requirements

### Functional Requirements

- **FR-001**: Each language implementation MUST provide DAO interface accepting operation path and parameters
- **FR-002**: DAO interface MUST support hierarchical operation paths (e.g., `/category/subcategory/operation`)
- **FR-003**: DAO MUST return results asynchronously with correlation UUID
- **FR-004**: System MUST support polling for operation results using correlation UUID
- **FR-005**: Operation responses MUST include status field (`pending`, `completed`, `failed`)
- **FR-006**: System MUST implement at least 3 demo operations for AI prompt management (generate, template, usage tracking)
- **FR-007**: Each language MUST provide tc adapter that translates tc input/output to DAO calls
- **FR-008**: Adapters MUST accept input via stdin (JSON) and output via stdout (JSON)
- **FR-009**: Error responses MUST include error field with descriptive message
- **FR-010**: System MUST validate operation paths and reject invalid formats
- **FR-011**: Correlation UUIDs MUST be unique across all operations
- **FR-012**: System MUST clean up completed operation results after retrieval or timeout
- **FR-013**: Each implementation MUST provide same set of operations with identical semantics
- **FR-014**: Implementations SHOULD demonstrate language-specific best practices (Ruby particularly clean/idiomatic)
- **FR-015**: Python implementation SHOULD include playful 🐍 theming in code/comments

### Key Entities

- **Operation**: Named system capability with hierarchical path (e.g., `/prompt/generate`)
- **DAO (Data Access Object)**: Unified interface providing `call(operation_path, params)` method
- **Correlation UUID**: Unique identifier linking async operation request to its result
- **Operation Result**: Response containing status, optional result data, and optional error
- **Test Adapter**: Language-specific wrapper translating tc I/O format to DAO interface
- **Prompt**: User input text for AI processing (demo domain entity)
- **Template**: Reusable prompt pattern with variable placeholders (demo domain entity)
- **Usage Event**: Record of operation invocation for analytics (demo domain entity)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Developer can implement DAO interface in new language following pattern in under 8 hours
- **SC-002**: Same tc test suite runs successfully against all 5 language implementations without modification
- **SC-003**: Async operations return correlation UUID in under 100ms
- **SC-004**: System correctly handles 50 concurrent async operations without result interference
- **SC-005**: Test adapters for all languages follow identical input/output contract
- **SC-006**: Comparison testing accurately identifies when one implementation produces different result than others
- **SC-007**: All implementations provide minimum 3 operations (prompt generate, template render, usage track)
- **SC-008**: Ruby implementation receives positive feedback for code quality and idiomaticity from Ruby developers

## Assumptions

### Implementation Assumptions

- **Demo Domain**: AI prompt management system chosen for modern, relevant demo context
- **Languages**: Five languages selected for diversity: Go (compiled, static), Rust (systems, safety), JavaScript (dynamic, ubiquitous), Python 🐍 (scripting, AI-friendly), Ruby (elegant, expressive)
- **DAO Interface**: `dao.call(operation_path, params) => {id: uuid, status: string, result?: any, error?: string}`
- **Async Pattern**: Immediate UUID return + polling (not callbacks/promises), matching system adapter pattern spec
- **Serialization**: JSON for all I/O (universal language support)
- **Operation Paths**: Slash-delimited hierarchical naming (e.g., `/category/action`)
- **Status Values**: `pending`, `completed`, `failed` (standard async status states)
- **UUID Format**: Standard UUID v4 (universally supported)
- **Adapter Contract**: Follows tc test runner contract (executable, stdin/stdout, JSON)

### Storage & State

- **Result Storage**: In-memory by default (production would use Redis/similar)
- **TTL**: Completed results expire after 1 hour or on first retrieval
- **Cleanup**: Background process or lazy cleanup on access
- **Concurrency**: Message queue ensures operation ordering within same resource

### Demo Operations

- **`/prompt/generate`**: Takes text param, returns processed prompt (simulated AI)
- **`/template/create`**: Takes template definition, returns UUID
- **`/template/render`**: Takes template UUID + variables, returns rendered result
- **`/usage/track`**: Takes event data, returns acknowledgment

## Out of Scope

- Actual AI API integration (OpenAI, Anthropic, etc.) - operations are simulated
- Authentication/authorization (demo focuses on interface pattern)
- Persistence to database (in-memory storage only)
- Production deployment configurations
- Load balancing or distributed operation execution
- Real-time websocket/SSE result streaming (polling only)
- Admin UI or dashboards
- Metrics/observability beyond basic logging
- Rate limiting or quota enforcement
- Crypto/blockchain functionality (AI chosen as demo domain instead)

## Dependencies

- Existing tc framework (test execution and comparison)
- System adapter pattern spec (005-consider-research-methodlogies)
- nozombie.sh for process management
- JSON processing capability (each language's standard library)
- UUID generation (each language's standard library or common package)

## Design Decisions

### Demo Domain: AI Prompt Management (Not Crypto)

**Decision**: Use AI prompt management system as demo domain

**Rationale**:
- More relevant in 2025 than crypto
- Familiar to developers (everyone uses AI tools)
- Simple business logic, focuses on interface pattern
- Async-friendly operations (prompt generation can be slow)
- Natural hierarchical operations (`/prompt/x`, `/template/y`, `/usage/z`)

### Language Selection

**Languages**: Go, Rust, JavaScript (Node.js), Python 🐍, Ruby

**Rationale**:
- **Go**: Popular for systems programming, strong concurrency
- **Rust**: Represents high-performance, memory-safe systems language
- **JavaScript**: Ubiquitous, async-native with promises
- **Python 🐍**: AI ecosystem standard, approachable syntax
- **Ruby**: Elegant, expressive, showcase of clean OOP

**Ruby Quality Goal**: "Really clean" = idiomatic Ruby style, readable, gem-quality code

### Async Interface Design

**Pattern**: Immediate UUID return + status polling

```
Request:  dao.call('/prompt/generate', {text: "hello"})
Response: {id: "550e8400-...", status: "pending"}

Poll:     dao.call('/result/poll', {id: "550e8400-..."})
Response: {id: "550e8400-...", status: "completed", result: {...}}
```

**Rationale**:
- Matches system adapter pattern (005 spec)
- Works across all languages without language-specific async primitives
- Testable with tc's synchronous test runner
- Realistic production pattern (HTTP 202 Accepted + polling)

## Project Structure

```
./projects/
├── go/
│   ├── dao/
│   │   └── dao.go          # DAO interface implementation
│   ├── operations/
│   │   └── prompt.go       # Operation handlers
│   ├── adapter/
│   │   └── tc_adapter.go   # tc test adapter
│   └── README.md
├── rust/
│   ├── src/
│   │   ├── dao.rs          # DAO interface
│   │   ├── operations.rs   # Handlers
│   │   └── adapter.rs      # tc adapter
│   ├── Cargo.toml
│   └── README.md
├── javascript/
│   ├── lib/
│   │   ├── dao.js          # DAO interface
│   │   └── operations.js   # Handlers
│   ├── adapter.js          # tc adapter
│   ├── package.json
│   └── README.md
├── python/
│   ├── dao/
│   │   ├── __init__.py
│   │   └── dao.py          # DAO interface 🐍
│   ├── operations/
│   │   └── prompt.py       # Handlers 🐍
│   ├── adapter.py          # tc adapter 🐍
│   ├── requirements.txt
│   └── README.md
└── ruby/
    ├── lib/
    │   ├── dao.rb          # DAO interface (clean!)
    │   └── operations.rb   # Handlers (idiomatic!)
    ├── tc_adapter.rb       # tc adapter
    ├── Gemfile
    └── README.md
```

## Shared Test Suite

```
tests/multi-lang-dao/
├── README.md
├── data/
│   ├── prompt-generate/
│   │   ├── input.json      # {operation: "/prompt/generate", params: {...}}
│   │   └── expected.json   # {id: "<uuid>", status: "pending"}
│   ├── template-create/
│   │   ├── input.json
│   │   └── expected.json
│   └── async-poll/
│       ├── input.json      # {operation: "/result/poll", params: {id: "..."}}
│       └── expected.json   # {status: "completed", result: {...}}
└── run                     # Symlink to language adapter
```

## Related Work

- [System Adapter Pattern](../005-consider-research-methodlogies/spec.md) - Core pattern being demonstrated
- [tc Framework](../../README.md) - Test harness for multi-language testing
- [nozombie.sh](../../docs/nozombie.md) - Process management for test runners

---

**Next Steps**:
1. Implement minimal DAO in Ruby (showcase clean code)
2. Implement Go version (performance baseline)
3. Port to Python 🐍, JavaScript, Rust
4. Create shared tc test suite
5. Build comparison testing capability
6. Document adapter creation pattern
