# Theory: Language-Agnostic System Adapter Pattern

**Status**: Concept / Work In Progress
**Created**: 2025-10-15
**Specification**: [specs/005-consider-research-methodlogies/spec.md](../specs/005-consider-research-methodlogies/spec.md)

## Vision

Enable generation of **disposable applications** while maintaining professional engineering practices through language-portable, high-level testing that matches the flexibility of spec-kit's markdown-driven development.

## Core Concept

Create a **brutally consistent interface** to system functionality that enables:
- Writing tests once, running against multiple language implementations
- Comparing correctness and performance across implementations
- Swapping languages/frameworks while preserving test suites
- Liberation from strict TDD through higher-level behavioral testing

## The Problem

Traditional TDD couples tests to implementation details:
- Unit tests are language-specific
- Integration tests depend on framework choices
- Changing languages requires rewriting entire test suites
- Testing becomes a barrier to experimentation

In the age of AI-generated code and spec-driven development, **the specification is the source of truth**, not the implementation. We need tests that reflect this reality.

## The Pattern

### 1. System Adapter Interface

Every language implementation provides an **adapter** - a thin entry point that:
- Accepts operation names and parameters in standard format (JSON)
- Routes to system functionality
- Returns results in standard format
- Follows tc's existing test runner contract (stdin/stdout)

**Example conceptual interface**:
```
# Input (JSON via stdin):
{
  "operation": "user.create",
  "params": {
    "email": "user@example.com",
    "name": "Test User"
  }
}

# Output (JSON via stdout):
{
  "result": {
    "id": "user-123",
    "email": "user@example.com",
    "name": "Test User",
    "created_at": "2025-10-15T00:00:00Z"
  }
}
```

### 2. Test Suite Structure

Tests define system behavior at operation level:
```
tests/user/create/
├── data/
│   ├── valid-email/
│   │   ├── input.json      # {"operation": "user.create", "params": {...}}
│   │   └── expected.json   # {"result": {...}}
│   └── invalid-email/
│       ├── input.json
│       └── expected.json   # {"error": "Invalid email"}
└── run                     # Adapter (different per language)
```

### 3. Synchronous and Asynchronous Operations

**Synchronous** (immediate response):
```json
// Input
{"operation": "math.add", "params": {"a": 5, "b": 3}}

// Output
{"result": 8}
```

**Asynchronous** (deferred response):
```json
// Input
{"operation": "email.send", "params": {"to": "...", "subject": "..."}}

// Output (immediate)
{"correlation_id": "async-job-123", "status": "pending"}

// Poll/retrieve result later
{"operation": "async.result", "params": {"correlation_id": "async-job-123"}}

// Final result
{"result": {"sent": true, "message_id": "msg-456"}, "status": "completed"}
```

### 4. Adapter Discovery

**Primary: Configuration File** (`adapters.json`)
```json
{
  "adapters": [
    {
      "name": "ruby",
      "language": "ruby",
      "version": "3.2.0",
      "path": "./adapters/ruby/run",
      "capabilities": ["sync", "async"]
    },
    {
      "name": "go",
      "language": "go",
      "version": "1.21",
      "path": "./adapters/go/bin/adapter",
      "capabilities": ["sync", "async"]
    }
  ]
}
```

**Override: Environment Variable**
```bash
TC_ADAPTERS=./adapters/rust tc run tests
```

**Rationale**:
- Config file is git-friendly and version controlled
- Explicit registration prevents accidental execution
- Supports rich metadata naturally
- Environment variable enables CI/CD flexibility

### 5. Comparison Testing

Run same test suite against multiple adapters:
```bash
tc run tests --adapters ruby,go,python --compare
```

**Output**:
```
🚁 Comparison Report

Suite: tests/user/create
┌──────────┬────────┬────────┬──────────┐
│ Adapter  │ Passed │ Failed │ Avg Time │
├──────────┼────────┼────────┼──────────┤
│ ruby     │ 10     │ 0      │ 145ms    │
│ go       │ 10     │ 0      │ 12ms     │
│ python   │ 9      │ 1      │ 98ms     │
└──────────┴────────┴────────┴──────────┘

⚠️  Discrepancy: python failed 'invalid-email' test
```

## How It Works With tc

tc already has the foundation:
- **Test runner contract**: Executables accept input.json, output to stdout
- **Directory-based suites**: `suite/data/scenario/input.json` + `expected.json`
- **Language-agnostic harness**: Shell script test runner

**Extensions needed**:
- Operation-based input format (not just arbitrary JSON)
- Adapter discovery and selection
- Async operation support (correlation IDs, polling)
- Multi-adapter execution and comparison reporting

## How It Works With spec-kit

spec-kit generates system implementations from markdown specs. This pattern enables:

1. **Write specification** (markdown) → spec-kit generates system
2. **Generate adapter** (thin wrapper following pattern)
3. **Write tests** (high-level operations, not implementation details)
4. **Iterate freely**:
   - Change implementation language → regenerate + new adapter → same tests
   - Swap frameworks → same tests verify correctness
   - Compare alternatives → parallel testing shows performance differences

**The specification remains the source of truth**, implementations become disposable.

## Practical Example

### Scenario: User Registration System

**Specification** (spec-kit markdown):
```markdown
## User Registration

System allows users to register with email and password.

- User provides email and password
- System validates email format
- System hashes password
- System creates user record
- System returns user ID
```

**Test Suite** (language-agnostic):
```
tests/user/register/
├── data/
│   ├── valid-registration/
│   │   ├── input.json: {"operation": "user.register", "params": {"email": "test@example.com", "password": "secret123"}}
│   │   └── expected.json: {"result": {"id": "<uuid>", "email": "test@example.com"}}
│   └── invalid-email/
│       ├── input.json: {"operation": "user.register", "params": {"email": "not-an-email", "password": "secret123"}}
│       └── expected.json: {"error": "Invalid email format"}
└── run → (symlink to current adapter)
```

**Adapters** (multiple languages):

```ruby
# adapters/ruby/run
require 'json'
require_relative '../../src/ruby/app'

input = JSON.parse(STDIN.read)
operation = input['operation']
params = input['params']

result = case operation
when 'user.register'
  App::UserService.register(params['email'], params['password'])
else
  {error: "Unknown operation: #{operation}"}
end

puts JSON.generate(result)
```

```go
// adapters/go/main.go
package main

import (
    "encoding/json"
    "os"
    "myapp/services"
)

type Request struct {
    Operation string                 `json:"operation"`
    Params    map[string]interface{} `json:"params"`
}

func main() {
    var req Request
    json.NewDecoder(os.Stdin).Decode(&req)

    var result interface{}

    switch req.Operation {
    case "user.register":
        result = services.RegisterUser(req.Params)
    default:
        result = map[string]string{"error": "Unknown operation"}
    }

    json.NewEncoder(os.Stdout).Encode(result)
}
```

**Run tests**:
```bash
# Test Ruby implementation
tc run tests/user/register --adapter ruby

# Test Go implementation
tc run tests/user/register --adapter go

# Compare both
tc run tests/user/register --adapters ruby,go --compare
```

## Benefits

### For Development

- **Experiment freely**: Try different languages without test penalty
- **Validate correctness**: Comparison testing reveals implementation bugs
- **Optimize performance**: Compare implementations empirically
- **Preserve knowledge**: Tests capture business logic, not implementation

### For Testing

- **Higher abstraction**: Test behavior, not implementation details
- **Better durability**: Tests outlive any single implementation
- **Faster iteration**: Change implementation without changing tests
- **Clearer intent**: Operation-based tests read like specifications

### For Teams

- **Polyglot teams**: Share test suites across language boundaries
- **AI generation**: Generate implementations freely, tests validate correctness
- **Technical debt**: Retire old implementations without losing test coverage
- **Knowledge transfer**: Tests document system behavior independently of code

## Implementation Roadmap

### Phase 1: MVP (P1 - Core Pattern)
- Define adapter interface contract
- Extend tc to support operation-based input format
- Implement adapter discovery (config file + env var override)
- Basic adapter execution and test running
- **Deliverable**: Can run same tests against 2+ language implementations

### Phase 2: Async Support (P2)
- Correlation ID generation and tracking
- Result polling mechanism
- Timeout handling for async operations
- **Deliverable**: Can test async operations (email, background jobs, etc.)

### Phase 3: Comparison Testing (P3)
- Multi-adapter parallel execution
- Result aggregation and comparison
- Performance metrics collection
- Discrepancy highlighting
- **Deliverable**: Comparison reports showing correctness and performance differences

### Phase 4: Workflow Integration (P4)
- Adapter scaffolding for new languages
- Documentation and examples
- Integration with spec-kit workflow
- **Deliverable**: Developer can add new language adapter in under 4 hours

## Design Principles

1. **Brutal Consistency**: Same interface, every language, every time
2. **Zero Magic**: Explicit configuration over convention (when it matters)
3. **Unix Philosophy**: Text streams, composability, one thing well
4. **Spec First**: Specifications are source of truth, code is disposable
5. **Fail Visible**: Comparison testing surfaces implementation differences immediately
6. **Git Friendly**: Configuration and tests version controlled together
7. **CI/CD Ready**: Environment variables override for build pipelines

## Technical Constraints

- **Serialization**: JSON only (universal language support)
- **Transport**: stdin/stdout (follows tc's runner contract)
- **Async Model**: Polling with correlation IDs (no callbacks/websockets)
- **State**: Tests are stateless by default
- **Execution**: Local only (no distributed testing)
- **Concurrency**: CPU-bound parallelism (process-level)

## Open Questions

- **State management**: How should adapters handle stateful operations? (Database setup/teardown, test fixtures)
- **Authentication**: How to handle auth-required operations in tests? (Test credentials, mocking)
- **External dependencies**: Mocking strategy for third-party APIs?
- **Error taxonomy**: Standard error format beyond {"error": "message"}?
- **Operation discovery**: Should adapters advertise available operations?
- **Versioning**: How to handle API version differences between implementations?

## Related Patterns

- **Hexagonal Architecture** (Ports & Adapters): System core isolated from external concerns
- **Clean Architecture**: Framework independence through dependency inversion
- **Contract Testing**: Verify implementations match agreed interface
- **Adapter Pattern**: Translate between incompatible interfaces
- **Strategy Pattern**: Swap implementations at runtime

## Prior Art

- **tc framework**: Language-agnostic testing via directory structure and test runner contract
- **spec-kit**: Markdown-driven system generation with AI
- **Cucumber/Gherkin**: Behavior-driven testing with natural language specs
- **JSON-RPC**: Standard protocol for remote procedure calls with JSON
- **GraphQL**: Uniform API across different backend implementations
- **WASM (WebAssembly)**: Run code in multiple languages with common interface

## Success Metrics

From [spec.md Success Criteria](../specs/005-consider-research-methodlogies/spec.md#success-criteria):

- Write test suite once, run against 3+ language implementations ✓
- New adapter creation < 4 hours for experienced developer
- Execute 100 test scenarios in < 30 seconds (excluding operation time)
- Comparison testing identifies discrepancies correctly
- 90% of operations testable via synchronous interface
- Async operations complete within timeout 99% of time
- Support 5+ languages (Ruby, Python, Node, Go, Rust)
- Reports show clear performance differences (min/max/avg)

## Future Vision

**Disposable Applications**:
```bash
# Monday: Generate Ruby app from spec
speckit generate --lang ruby

# Tuesday: Realize Go would be faster
speckit generate --lang go

# Wednesday: Run tests against both
tc run tests --adapters ruby,go --compare

# Thursday: Go is 10x faster, retire Ruby
git rm -rf src/ruby
```

**The tests never changed. The specification didn't change. Only the implementation changed.**

This is the future of spec-driven development.

---

**Next Steps**:
1. Prototype adapter interface with 2 languages (Ruby + Go)
2. Extend tc to support operation-based routing
3. Implement adapter discovery mechanism
4. Build comparison testing harness
5. Document adapter creation pattern
6. Integrate with spec-kit workflow

**See Also**:
- [Feature Specification](../specs/005-consider-research-methodlogies/spec.md)
- [tc Framework Documentation](./readme.md)
- [spec-kit Repository](https://github.com/github/spec-kit)
