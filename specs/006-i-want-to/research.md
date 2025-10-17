# Research: Multi-Language DAO Implementation Patterns

**Feature**: Multi-Language AI Prompt System
**Date**: 2025-10-15
**Purpose**: Determine implementation patterns for DAO interface across 5 languages

## Summary

Research confirms all 5 languages can implement the DAO pattern with minimal dependencies. Standard libraries sufficient for JSON/UUID handling. KISS approach validated.

## 1. DAO Pattern Per Language

### Ruby (Priority: Make It Really Clean!)

**Decision**: Classic Ruby class with clean method signatures

**Pattern**:
```ruby
class DAO
  def call(operation, params = {})
    # Route to handlers, return {id:, status:, result:, error:}
  end
end
```

**Rationale**:
- Idiomatic Ruby: classes with clear public API
- Use modules for operation namespaces (`Prompts`, `Templates`, `Usage`)
- Leverage Ruby's expressiveness for clean routing logic
- Method chaining for fluid interface optional

**Best Practices**:
- `frozen_string_literal: true` for performance
- Yard docs for public API
- Descriptive method names (`process_prompt` not `pp`)
- Use `Hash` symbol keys for consistency

---

### Go

**Decision**: Interface + struct implementation

**Pattern**:
```go
type DAO interface {
    Call(operation string, params map[string]interface{}) OperationResponse
}

type daoImpl struct {
    store *ResultStore
}

func (d *daoImpl) Call(operation string, params map[string]interface{}) OperationResponse {
    // Route and execute
}
```

**Rationale**:
- Go idiom: interface for contract, struct for implementation
- `map[string]interface{}` for flexible params (JSON compatible)
- Explicit error handling in response struct

**Best Practices**:
- Unexported struct, exported interface
- Package-level `NewDAO()` constructor
- Use `sync.Map` or `map` with `sync.Mutex` for result storage
- Standard library only (no external deps)

---

### Rust

**Decision**: Trait + struct implementation

**Pattern**:
```rust
pub trait DAO {
    fn call(&self, operation: &str, params: serde_json::Value) -> OperationResponse;
}

pub struct DaoImpl {
    store: Arc<Mutex<HashMap<Uuid, OperationResponse>>>,
}

impl DAO for DaoImpl {
    fn call(&self, operation: &str, params: serde_json::Value) -> OperationResponse {
        // Route and execute
    }
}
```

**Rationale**:
- Rust idiom: trait for interface, struct for state
- `serde_json::Value` for dynamic JSON params
- `Arc<Mutex<T>>` for thread-safe shared state
- Ownership model ensures safety

**Best Practices**:
- Use `Result<T, E>` internally for error handling
- `serde` for JSON serialization
- `uuid` crate for UUID generation (well-tested, standard)
- Minimize `unwrap()`, use proper error propagation

**Dependencies** (minimal):
- `serde = { version = "1.0", features = ["derive"] }`
- `serde_json = "1.0"`
- `uuid = { version = "1.6", features = ["v4"] }`

---

### JavaScript (Node.js)

**Decision**: ES6 class

**Pattern**:
```javascript
class DAO {
  constructor() {
    this.store = new Map(); // UUID -> OperationResponse
  }

  call(operation, params = {}) {
    // Route and execute
    return { id, status, result, error };
  }
}
```

**Rationale**:
- Modern JS: ES6 classes widely adopted
- `Map` for result storage (better than plain object)
- Async/await optional (can simulate with immediate return)
- Clean, familiar syntax

**Best Practices**:
- Use `const`/`let`, avoid `var`
- Destructuring for clean parameter handling
- JSDoc comments for public API
- `uuid` npm package for UUID generation

**Dependencies**:
- `uuid` (npm package, standard for UUIDs)

---

### Python 🐍

**Decision**: Class with descriptive methods

**Pattern**:
```python
class DAO:
    def __init__(self):
        self.store = {}  # UUID -> OperationResponse 🐍

    def call(self, operation: str, params: dict = None) -> dict:
        """
        Call an operation with params. Returns operation response. 🐍
        """
        # Route and execute
        return {"id": str(uuid.uuid4()), "status": "pending"}
```

**Rationale**:
- Python idiom: classes with type hints (Python 3.5+)
- Dict for flexible storage
- Snake_case method names (`process_prompt` not `processPrompt`)
- Docstrings for clarity

**Best Practices**:
- Type hints for function signatures
- `from typing import Dict, Any` for clarity
- `dataclasses` for structured responses optional
- Playful 🐍 comments throughout ("Sssss-imple storage!")

**Dependencies**:
- Built-in `uuid` module
- Built-in `json` module
- No external packages needed!

---

## 2. UUID Generation

### Comparison

| Language   | Method                     | Import                          | Example                                           |
|------------|----------------------------|---------------------------------|---------------------------------------------------|
| Ruby       | `SecureRandom.uuid`        | `require 'securerandom'`        | `"550e8400-e29b-41d4-a716-446655440000"`          |
| Go         | `uuid.NewRandom().String()`| `"github.com/google/uuid"` **OR** crypto/rand + formatting | Standard library approach preferable |
| Rust       | `Uuid::new_v4().to_string()`| `uuid` crate                    | Add to Cargo.toml                                 |
| JavaScript | `uuid.v4()`                | `const { v4: uuidv4 } = require('uuid');` | npm install uuid                          |
| Python     | `str(uuid.uuid4())`        | `import uuid`                   | Built-in module 🐍                                |

**Decision for Go**: Use standard library `crypto/rand` to generate random bytes and format as UUID to avoid external dependency.

```go
import (
    "crypto/rand"
    "fmt"
)

func generateUUID() string {
    b := make([]byte, 16)
    rand.Read(b)
    return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:])
}
```

**Alternatives Considered**:
- `google/uuid` package: Well-maintained but adds dependency
- Manual implementation: More control, zero deps

**Final Decision**: Manual UUID v4 generation for Go (KISS principle)

---

## 3. JSON I/O (stdin/stdout)

All languages have excellent built-in JSON support:

### Ruby
```ruby
require 'json'

input = JSON.parse(STDIN.read)
output = { id: uuid, status: 'pending' }
puts JSON.generate(output)
```

### Go
```go
import "encoding/json"

var input OperationRequest
json.NewDecoder(os.Stdin).Decode(&input)
json.NewEncoder(os.Stdout).Encode(response)
```

### Rust
```rust
use serde_json;

let input: OperationRequest = serde_json::from_reader(std::io::stdin())?;
serde_json::to_writer(std::io::stdout(), &response)?;
```

### JavaScript
```javascript
const input = JSON.parse(fs.readFileSync(0, 'utf-8')); // fd 0 = stdin
console.log(JSON.stringify(response));
```

### Python 🐍
```python
import json
import sys

input_data = json.load(sys.stdin)  # Read from stdin 🐍
print(json.dumps(response))  # Write to stdout 🐍
```

**Conclusion**: JSON I/O is straightforward in all languages. No special libraries needed.

---

## 4. Async Simulation Strategy

**Decision**: Synchronous execution with status transitions

**Rationale**:
- Simpler implementation (KISS)
- Demonstrates pattern without concurrency complexity
- Operations complete immediately, status goes: `pending` → `completed`
- Realistic enough for demo purposes

**Pattern**:
```
1. Receive operation request
2. Generate UUID
3. Store result with status="pending"
4. Execute operation (simulated, instant)
5. Update stored result to status="completed" with result data
6. Return initial response {id, status: "pending"}

For /result/poll:
1. Receive {id: uuid}
2. Lookup stored result
3. Return current status + result if completed
```

**Future Enhancement** (out of scope for MVP):
- Goroutines (Go) / Threads (Python/Ruby) / async/await (JS/Rust)
- Actual background processing with delays
- Real pub/sub message queue

**Conclusion**: Sync execution sufficient for proof-of-concept

---

## 5. In-Memory Storage

### Ruby
```ruby
class ResultStore
  def initialize
    @store = {}  # Thread-safe in MRI due to GIL
    @mutex = Mutex.new  # Optional: for thread safety in JRuby/TruffleRuby
  end

  def set(id, response)
    @store[id] = response
  end

  def get(id)
    @store[id]
  end
end
```

**Decision**: Plain Hash with optional Mutex (KISS for MRI Ruby)

---

### Go
```go
type ResultStore struct {
    mu    sync.RWMutex
    store map[string]OperationResponse
}

func (rs *ResultStore) Set(id string, response OperationResponse) {
    rs.mu.Lock()
    defer rs.mu.Unlock()
    rs.store[id] = response
}

func (rs *ResultStore) Get(id string) (OperationResponse, bool) {
    rs.mu.RLock()
    defer rs.mu.RUnlock()
    res, ok := rs.store[id]
    return res, ok
}
```

**Decision**: Map with RWMutex (standard Go concurrency pattern)

---

### Rust
```rust
use std::sync::{Arc, Mutex};
use std::collections::HashMap;

pub struct ResultStore {
    store: Arc<Mutex<HashMap<Uuid, OperationResponse>>>,
}

impl ResultStore {
    pub fn set(&self, id: Uuid, response: OperationResponse) {
        let mut store = self.store.lock().unwrap();
        store.insert(id, response);
    }

    pub fn get(&self, id: &Uuid) -> Option<OperationResponse> {
        let store = self.store.lock().unwrap();
        store.get(id).cloned()
    }
}
```

**Decision**: Arc<Mutex<HashMap>> (standard Rust shared state pattern)

---

### JavaScript
```javascript
class ResultStore {
  constructor() {
    this.store = new Map();
  }

  set(id, response) {
    this.store.set(id, response);
  }

  get(id) {
    return this.store.get(id);
  }
}
```

**Decision**: Map (Node.js is single-threaded, no mutex needed for sync code)

---

### Python 🐍
```python
import threading

class ResultStore:
    """Storage for operation results. Thread-safe! 🐍"""

    def __init__(self):
        self.store = {}
        self.lock = threading.Lock()  # Optional: for thread safety

    def set(self, id: str, response: dict):
        with self.lock:
            self.store[id] = response

    def get(self, id: str) -> dict:
        with self.lock:
            return self.store.get(id)
```

**Decision**: Dict with threading.Lock (optional for demo, included for completeness)

---

## 6. Operation Routing

**Common Pattern Across All Languages**:

```
def/function call(operation, params):
    if operation == "/prompt/generate":
        return generate_prompt(params)
    elif operation == "/template/create":
        return create_template(params)
    elif operation == "/template/render":
        return render_template(params)
    elif operation == "/usage/track":
        return track_usage(params)
    elif operation == "/result/poll":
        return poll_result(params)
    else:
        return { error: "Unknown operation: " + operation }
```

**Alternatives Considered**:
- Hash/map-based dispatch table: More scalable, but overkill for 5 operations
- Pattern matching (Rust): Clean but adds complexity
- Switch/case: Language-dependent availability

**Decision**: Simple if/elif/else chain (KISS, readable, sufficient for 5 operations)

---

## 7. TC Adapter Implementation

**Pattern** (same across all languages):

```
1. Read JSON from stdin
2. Parse into operation + params
3. Call DAO.call(operation, params)
4. Write response JSON to stdout
5. Exit with code 0 (or non-zero on fatal error)
```

**Ruby**:
```ruby
#!/usr/bin/env ruby
require_relative 'lib/dao'
require 'json'

input = JSON.parse(STDIN.read)
dao = DAO.new
response = dao.call(input['operation'], input['params'])
puts JSON.generate(response)
```

**Go**:
```go
package main

import (
    "encoding/json"
    "os"
    "yourproject/dao"
)

func main() {
    var input struct {
        Operation string                 `json:"operation"`
        Params    map[string]interface{} `json:"params"`
    }
    json.NewDecoder(os.Stdin).Decode(&input)

    d := dao.NewDAO()
    response := d.Call(input.Operation, input.Params)

    json.NewEncoder(os.Stdout).Encode(response)
}
```

**Conclusion**: Adapter implementation is straightforward 10-20 lines in all languages

---

## Key Decisions Summary

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| **Ruby DAO** | Clean class with modules | Idiomatic, showcase Ruby elegance |
| **Go DAO** | Interface + struct | Standard Go pattern |
| **Rust DAO** | Trait + struct | Idiomatic Rust with safety |
| **JS DAO** | ES6 class | Modern, familiar |
| **Python DAO** | Class with type hints | Clear, "Pythonic" 🐍 |
| **UUIDs** | Standard libs (Go: crypto/rand) | Minimize dependencies |
| **JSON I/O** | Built-in libraries | Universal support |
| **Async** | Sync execution, status transitions | KISS for demo |
| **Storage** | In-memory maps with appropriate locking | Simple, sufficient |
| **Routing** | If/elif/else chain | Readable, adequate for 5 ops |

---

## Risks & Mitigations

**Risk**: Language-specific JSON handling quirks
**Mitigation**: Test each adapter independently with tc

**Risk**: UUID format inconsistencies
**Mitigation**: Validate UUID v4 format in tests

**Risk**: Ruby "really clean" is subjective
**Mitigation**: Follow Ruby Style Guide, use Rubocop, peer review

**Risk**: Maintaining identical semantics across 5 implementations
**Mitigation**: Shared tc test suite validates behavior consistency

---

## Next Steps

With research complete, proceed to Phase 1:
1. Create `data-model.md` with entity definitions
2. Create `contracts/dao-api.md` with interface specifications
3. Create `quickstart.md` with usage examples
4. Update agent context with technology choices

**Ready for Phase 1**: ✅
