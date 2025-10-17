# Feature Specification: Language-Agnostic System Adapter Pattern

**Feature Branch**: `005-consider-research-methodlogies`
**Created**: 2025-10-15
**Status**: Draft
**Input**: User description: "consider/research methodlogies that systems might be designed, a playbook, or design pattern, for being able to iterate on a system using spec-kit (from gh) and keeping tests portable between systems.  i am envisioning a concept like having a unified api/system layer for all functionality, similar to, in ruby code sys.call('/foo/bar/baz', params = {}) => result.  that is to say a brutally consistent interface to high-level logic.  we aim to imagine ways to expose system functionality that can be portable across node, ruby, rust, go, python.  etc.  in the same vein, we should consider higher level concepts like sync/async.  likely, modern systems are going to be async.  so pub/sub is a methodology to consider, with others.  the key concept is that we would like to be able to drop in a system adapter... which is do say a bit of code that represents and entry-point into the system, and then to call it, with intput and immediately, or later, get output, to test.  this could be mean that, not only are tests portable between langs/implimentations but, that it could be simple to toggle between systems and run tests over each.  comparing speed/correctness, etc.  the goal here, is to liberate spec-kit from strict TDD: we still want tests, but we want higher level tests than is normal precisely to facilitate moving bewteen langs or swapping frameworks.  our testing strategy needs to be as agile and felxible at testing, as spec-kit/claude/markdown is, at describing a generated system.  our ultimate goal is none other than to be able to generate disposable applications while still adhering to professional engineering practices and a test friendly development cycle."

## User Scenarios & Testing

### User Story 1 - Unified Test Suite Across Language Implementations (Priority: P1)

A development team maintains a system specification and wants to experiment with different language implementations (Ruby, Go, Python, Rust, Node.js) while keeping the same test suite. They write tests once at a high level and run them against any implementation to verify correctness.

**Why this priority**: This is the core value proposition - enables true language portability through a consistent testing interface. Without this, the entire pattern fails.

**Independent Test**: Can be fully tested by creating a simple "echo" operation with 2-3 language adapters and running the same test suite against each, verifying identical pass/fail results.

**Acceptance Scenarios**:

1. **Given** a test suite defining system behavior with input/output pairs, **When** running tests against Ruby implementation, **Then** all tests execute and report pass/fail status
2. **Given** the same test suite, **When** running tests against Go implementation, **Then** tests execute with identical pass/fail results as Ruby (assuming correct implementation)
3. **Given** test suite with input parameters, **When** adapter receives input, **Then** adapter routes to system entry point and returns output in standard format
4. **Given** multiple language implementations available, **When** developer runs test suite, **Then** developer can select which implementation(s) to test against

---

### User Story 2 - Synchronous and Asynchronous Operation Support (Priority: P2)

A system has operations that complete immediately (synchronous) and operations that complete later (asynchronous). Tests can handle both patterns through a unified interface, waiting for async results when needed without changing test structure.

**Why this priority**: Modern systems are increasingly async. This enables testing realistic system behavior without forcing all operations to be synchronous (which would misrepresent production behavior).

**Independent Test**: Can be tested by implementing sync operation ("add two numbers") and async operation ("send email") with same adapter interface, verifying test harness handles both correctly.

**Acceptance Scenarios**:

1. **Given** a synchronous operation (e.g., "calculate sum"), **When** test calls operation, **Then** result returns immediately in response
2. **Given** an asynchronous operation (e.g., "process order"), **When** test calls operation, **Then** test receives correlation ID and can poll/wait for result
3. **Given** async operation with correlation ID, **When** test waits for completion, **Then** test retrieves final result using correlation ID
4. **Given** async operation that takes 5 seconds, **When** test specifies timeout of 10 seconds, **Then** test waits and receives result successfully

---

### User Story 3 - Adapter Discovery and Comparison (Priority: P3)

A development team has implemented the same system in 3 different languages. They want to run tests against all implementations simultaneously and compare results for correctness, performance, and resource usage.

**Why this priority**: Enables comparison shopping between implementations - valuable for optimization and validation, but system works without it.

**Independent Test**: Can be tested by running same test suite against 2+ adapters concurrently and generating comparison report showing pass/fail rates and performance metrics.

**Acceptance Scenarios**:

1. **Given** multiple adapters available (Ruby, Go, Python), **When** developer runs comparative test suite, **Then** tests execute against all adapters in parallel
2. **Given** test results from multiple adapters, **When** tests complete, **Then** system generates comparison report showing pass rates per adapter
3. **Given** test execution times per adapter, **When** generating report, **Then** report shows performance comparison (e.g., "Go: 150ms, Ruby: 450ms, Python: 320ms")
4. **Given** one adapter passes test that another fails, **When** reviewing results, **Then** report highlights discrepancies for investigation

---

### User Story 4 - Spec-Driven Development Workflow (Priority: P4)

A team uses spec-kit to define system behavior in markdown. They generate a new implementation in a different language, create an adapter following the standard pattern, and immediately run the existing test suite to verify correctness.

**Why this priority**: Enables the "disposable applications" vision - swap implementations while maintaining quality. Nice-to-have workflow optimization.

**Independent Test**: Can be tested by documenting adapter creation process, creating adapter for new language following pattern, and verifying tests run successfully.

**Acceptance Scenarios**:

1. **Given** system specification and test suite, **When** developer creates new language implementation, **Then** developer can create adapter by following standard pattern
2. **Given** new adapter implementing required interface, **When** test suite runs, **Then** tests discover and execute against new adapter without test modifications
3. **Given** spec-kit generated system, **When** developer wants to try different language, **Then** developer regenerates implementation in new language, creates adapter, runs same tests

---

### Edge Cases

- What happens when an adapter crashes or fails to start? (Test should report error, not hang)
- How does system handle operations that timeout? (Return timeout status after threshold)
- What if async operation never completes? (Test framework enforces timeout and fails test)
- How to handle operations that have side effects? (Tests should be able to reset/clean state between runs)
- What if two adapters use different data serialization formats? (Adapter normalizes to standard format - JSON by default)
- How to test operations that require external dependencies? (Adapter pattern allows mocking/stubbing at adapter boundary)
- What if operation semantics differ between languages? (This is a correctness bug - comparison testing should reveal it)

## Requirements

### Functional Requirements

- **FR-001**: System MUST define standard adapter interface that all language implementations follow
- **FR-002**: Adapter interface MUST support synchronous operations (call with input, receive immediate output)
- **FR-003**: Adapter interface MUST support asynchronous operations (call with input, receive correlation ID, poll for result)
- **FR-004**: Test harness MUST accept test suite as input/output pairs in standard format (JSON recommended)
- **FR-005**: Test harness MUST discover available adapters via configuration file (e.g., `adapters.json`) listing adapter paths and metadata, with optional override via `TC_ADAPTERS` environment variable
- **FR-006**: Test harness MUST execute test scenarios against specified adapter(s)
- **FR-007**: Test harness MUST collect results (pass/fail/error) for each test scenario
- **FR-008**: System MUST normalize operation inputs/outputs to standard serialization format
- **FR-009**: Test harness MUST support timeout configuration per operation or globally
- **FR-010**: Test harness MUST report results in machine-readable format (JSONL or similar)
- **FR-011**: Adapter MUST provide metadata (language, version, capabilities)
- **FR-012**: Test harness MUST support running tests against multiple adapters concurrently
- **FR-013**: Test harness MUST generate comparison reports when testing multiple adapters
- **FR-014**: System MUST document standard adapter contract (expected interface, protocols, data formats)
- **FR-015**: Adapter MUST handle both request/response and publish/subscribe patterns

### Key Entities

- **Test Suite**: Collection of test scenarios, each defining operation name, input data, and expected output data
- **Test Scenario**: Single test case with operation identifier, input parameters, expected output, and optional timeout
- **Adapter**: Language-specific implementation providing entry point to system, conforming to standard interface
- **Operation**: Named system capability invoked via adapter (e.g., "user.create", "order.process", "report.generate")
- **Correlation ID**: Unique identifier for async operations, used to retrieve results after completion
- **Test Result**: Outcome of executing scenario against adapter - status (pass/fail/error/timeout), actual output, duration, metadata
- **Comparison Report**: Aggregate results from multiple adapters showing correctness and performance differences

## Success Criteria

### Measurable Outcomes

- **SC-001**: Developer can write test suite once and run it against 3+ different language implementations without modifying tests
- **SC-002**: Creating new adapter for additional language takes under 4 hours for experienced developer (following documented pattern)
- **SC-003**: Test harness executes 100 test scenarios against single adapter in under 30 seconds (excluding operation execution time)
- **SC-004**: Comparison testing correctly identifies discrepancies when one implementation produces different output than others
- **SC-005**: 90% of common operations (CRUD, calculations, transformations) can be tested through synchronous interface
- **SC-006**: Async operations complete and return results within configured timeout 99% of the time under normal conditions
- **SC-007**: Test suite portable across at least 5 popular languages (Ruby, Python, JavaScript/Node, Go, Rust) with adapters following same interface pattern
- **SC-008**: Generated comparison reports clearly show performance differences (min/max/avg execution time) between implementations

## Assumptions

- **Data Format**: JSON will be the default serialization format for inputs/outputs due to universal language support
- **Adapter Location**: Adapters will be executable scripts/binaries that accept input on stdin and write output to stdout (following tc's runner contract)
- **Async Pattern**: Pub/sub will be implemented via polling with correlation IDs initially (not websockets/callbacks) for simplicity
- **Test Organization**: Tests will follow tc's directory structure (suite directories with data/ subdirectories)
- **Error Handling**: Adapters will return errors in standardized JSON format with error field
- **State Management**: Tests are stateless by default; state management is adapter's responsibility if needed
- **Concurrency**: Comparison testing runs adapters in parallel using available CPU cores
- **Operation Naming**: Operations use dot-notation path-like naming (e.g., "user.create", "order.submit.validate")

## Out of Scope

- Building language-specific frameworks (this is a pattern/methodology, not a framework)
- Providing adapter implementations for all languages (pattern documentation only)
- Distributed testing across networked machines (local multi-adapter testing only)
- Performance benchmarking tools beyond basic timing comparison
- Automated code generation from specs (spec-kit handles this separately)
- Test data generation or fuzzing capabilities
- Integration with specific CI/CD platforms

## Dependencies

- Existing tc framework (provides test execution harness and result reporting)
- JSON processing capability in test harness (jq already required by tc)
- spec-kit workflow for system specification and generation

## Design Decisions

### Adapter Discovery Mechanism

**Decision**: Use configuration file (`adapters.json`) as primary discovery mechanism, with environment variable (`TC_ADAPTERS`) as override.

**Rationale**:
- Configuration file is git-friendly and version controlled alongside tests
- Explicit adapter registration prevents accidental execution of wrong binaries
- Supports metadata (language, version, capabilities) naturally in JSON format
- Environment variable override enables CI/CD flexibility without modifying committed config
- Combines best of both approaches: reproducibility (config file) + flexibility (env var)

## Related Work

- tc framework's language-agnostic testing approach (test runner contract)
- spec-kit's markdown-driven system generation
- Industry patterns: Hexagonal Architecture (ports and adapters), Clean Architecture (framework independence)
