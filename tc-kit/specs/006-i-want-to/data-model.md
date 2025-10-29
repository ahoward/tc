# Data Model: Multi-Language DAO System

**Feature**: Multi-Language AI Prompt System
**Date**: 2025-10-15
**Purpose**: Define data structures for DAO interface and domain entities

## Core DAO Entities

### OperationRequest

**Purpose**: Input to DAO.call() method

**Structure**:
```json
{
  "operation": "/prompt/generate",
  "params": {
    "text": "hello world"
  }
}
```

**Fields**:
- `operation` (String, required): Hierarchical path identifying the operation (e.g., "/prompt/generate")
  - Format: `"/category/action"` or `"/category/subcategory/action"`
  - Validation: Must start with "/", no trailing slash, alphanumeric + hyphen only
- `params` (Object, optional): Operation-specific parameters
  - Type: JSON object (map/dict/hash depending on language)
  - Default: `{}` if omitted

**Validation Rules**:
- `operation` must match pattern: `^/[a-z0-9/-]+[a-z0-9]$`
- `params` must be valid JSON object (not array or primitive)

---

### OperationResponse

**Purpose**: Output from DAO.call() method and result storage

**Structure**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending",
  "result": {},
  "error": null
}
```

**Fields**:
- `id` (String/UUID, required): Correlation ID for async result retrieval
  - Format: UUID v4 (lowercase with hyphens)
  - Example: `"550e8400-e29b-41d4-a716-446655440000"`
- `status` (Enum, required): Current operation status
  - Values: `"pending"`, `"completed"`, `"failed"`
  - Initial: `"pending"`
  - Transitions: `pending` → `completed` OR `pending` → `failed`
- `result` (Object, optional): Operation result data (present when status = "completed")
  - Type: JSON object
  - Content varies by operation
  - Absent (null/undefined/omitted) when status = "pending" or "failed"
- `error` (String, optional): Error message (present when status = "failed")
  - Content: Human-readable error description
  - Absent when status = "pending" or "completed"

**State Transitions**:
```
[Initial]
    ↓
pending (id assigned, operation queued)
    ↓
    ├─→ completed (result present, error absent)
    └─→ failed (error present, result absent)
```

**Invariants**:
- Exactly one of {result, error, neither} is present based on status
- `pending`: result = null, error = null
- `completed`: result present, error = null
- `failed`: result = null, error present
- Status never transitions backwards (no `completed` → `pending`)

---

### ResultStore Entry

**Purpose**: In-memory storage of operation results for polling

**Structure**:
```
Key: UUID (string)
Value: OperationResponse
TTL: 1 hour OR first retrieval
```

**Storage Semantics**:
- **Set**: Store operation response by UUID key
- **Get**: Retrieve operation response by UUID key
  - Returns response if found
  - Returns null/nil/None if not found or expired
  - Optional: Remove entry after retrieval (single-read pattern)
- **Cleanup**: Remove entries after 1 hour or first successful retrieval

**Concurrency**:
- **Ruby**: Hash with optional Mutex (MRI: GIL provides safety)
- **Go**: map with sync.RWMutex
- **Rust**: Arc<Mutex<HashMap<Uuid, OperationResponse>>>
- **JavaScript**: Map (single-threaded, no locking needed)
- **Python**: dict with threading.Lock 🐍

---

## Demo Domain Entities

### Prompt

**Purpose**: AI prompt processing result

**Structure**:
```json
{
  "text": "hello world",
  "processed": "HELLO WORLD [AI-processed]",
  "timestamp": "2025-10-15T12:00:00Z"
}
```

**Fields**:
- `text` (String, required): Original input prompt text
- `processed` (String, required): Simulated AI-processed result
  - Demo logic: Uppercase + " [AI-processed]" suffix
- `timestamp` (DateTime/String, required): Processing timestamp (ISO 8601)

**Validation**:
- `text` must be non-empty string (1-10000 characters)
- `timestamp` must be valid ISO 8601 format

**Returned By**: `/prompt/generate` operation

---

### Template

**Purpose**: Reusable prompt template with variable substitution

**Structure**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "greeting",
  "pattern": "Hello {{name}}, welcome to {{place}}!",
  "variables": ["name", "place"]
}
```

**Fields**:
- `id` (UUID, required): Unique template identifier
  - Generated on creation
- `name` (String, required): Template name/label
  - Validation: 1-100 alphanumeric characters + hyphens
- `pattern` (String, required): Template text with {{variable}} placeholders
  - Format: `{{variable_name}}` for substitution points
  - Example: `"Hello {{name}}, you have {{count}} messages"`
- `variables` (Array[String], required): List of variable names in template
  - Extracted from pattern or provided explicitly
  - Used for validation during rendering

**Operations**:
- **Create**: `/template/create` → Returns template with generated UUID
- **Render**: `/template/render` → Substitutes variables, returns rendered text

---

### RenderedTemplate

**Purpose**: Result of template rendering with variable substitution

**Structure**:
```json
{
  "template_id": "550e8400-e29b-41d4-a716-446655440000",
  "rendered": "Hello Alice, welcome to Wonderland!",
  "variables_used": {
    "name": "Alice",
    "place": "Wonderland"
  }
}
```

**Fields**:
- `template_id` (UUID, required): Reference to original template
- `rendered` (String, required): Final text with variables substituted
- `variables_used` (Object, required): Map of variable names to values used

**Returned By**: `/template/render` operation

---

### UsageEvent

**Purpose**: Operation usage tracking for analytics

**Structure**:
```json
{
  "operation": "/prompt/generate",
  "timestamp": "2025-10-15T12:00:00Z",
  "duration_ms": 45
}
```

**Fields**:
- `operation` (String, required): Operation path that was invoked
- `timestamp` (DateTime/String, required): When operation occurred (ISO 8601)
- `duration_ms` (Integer, required): How long operation took in milliseconds

**Validation**:
- `duration_ms` must be non-negative integer
- `operation` must match valid operation path pattern

**Returned By**: `/usage/track` operation

---

## Operation-Specific Models

### /prompt/generate

**Input (`params`)**:
```json
{
  "text": "hello world"
}
```

**Output (`result`)**:
```json
{
  "text": "hello world",
  "processed": "HELLO WORLD [AI-processed]",
  "timestamp": "2025-10-15T12:00:00Z"
}
```

---

### /template/create

**Input (`params`)**:
```json
{
  "name": "greeting",
  "pattern": "Hello {{name}}!",
  "variables": ["name"]
}
```

**Output (`result`)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "greeting",
  "pattern": "Hello {{name}}!",
  "variables": ["name"]
}
```

---

### /template/render

**Input (`params`)**:
```json
{
  "template_id": "550e8400-e29b-41d4-a716-446655440000",
  "values": {
    "name": "Alice"
  }
}
```

**Output (`result`)**:
```json
{
  "template_id": "550e8400-e29b-41d4-a716-446655440000",
  "rendered": "Hello Alice!",
  "variables_used": {
    "name": "Alice"
  }
}
```

---

### /usage/track

**Input (`params`)**:
```json
{
  "operation": "/prompt/generate",
  "duration_ms": 45
}
```

**Output (`result`)**:
```json
{
  "tracked": true,
  "operation": "/prompt/generate",
  "timestamp": "2025-10-15T12:00:00Z"
}
```

---

### /result/poll

**Input (`params`)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Output (`result`)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "result": {
    "text": "hello world",
    "processed": "HELLO WORLD [AI-processed]",
    "timestamp": "2025-10-15T12:00:00Z"
  }
}
```

---

## Entity Relationships

```
OperationRequest
    ↓ (input to)
DAO.call()
    ↓ (returns)
OperationResponse
    ↓ (stored in)
ResultStore
    ↑ (retrieved by)
/result/poll

Template
    ↓ (used by)
/template/render
    ↓ (produces)
RenderedTemplate

OperationRequest
    ↓ (triggers)
/usage/track
    ↓ (creates)
UsageEvent
```

---

## Implementation Notes

### Language-Specific Representations

**Ruby**:
```ruby
class OperationResponse
  attr_reader :id, :status, :result, :error

  def initialize(id:, status:, result: nil, error: nil)
    @id = id
    @status = status
    @result = result
    @error = error
  end

  def to_json(*args)
    { id: @id, status: @status, result: @result, error: @error }.compact.to_json(*args)
  end
end
```

**Go**:
```go
type OperationResponse struct {
    ID     string                 `json:"id"`
    Status string                 `json:"status"`
    Result map[string]interface{} `json:"result,omitempty"`
    Error  string                 `json:"error,omitempty"`
}
```

**Rust**:
```rust
#[derive(Serialize, Deserialize, Clone)]
pub struct OperationResponse {
    pub id: String,
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}
```

**JavaScript**:
```javascript
class OperationResponse {
  constructor({ id, status, result = null, error = null }) {
    this.id = id;
    this.status = status;
    if (result !== null) this.result = result;
    if (error !== null) this.error = error;
  }

  toJSON() {
    const obj = { id: this.id, status: this.status };
    if (this.result !== null) obj.result = this.result;
    if (this.error !== null) obj.error = this.error;
    return obj;
  }
}
```

**Python 🐍**:
```python
from dataclasses import dataclass, asdict
from typing import Optional, Dict, Any

@dataclass
class OperationResponse:
    """Response from a DAO operation. Simple like a snake! 🐍"""
    id: str
    status: str
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

    def to_dict(self) -> dict:
        return {k: v for k, v in asdict(self).items() if v is not None}
```

---

## Validation Rules Summary

| Entity | Field | Rule |
|--------|-------|------|
| OperationRequest | operation | Matches `/[a-z0-9/-]+[a-z0-9]` |
| OperationRequest | params | Valid JSON object |
| OperationResponse | id | Valid UUID v4 format |
| OperationResponse | status | One of: pending, completed, failed |
| OperationResponse | result/error | Mutually exclusive based on status |
| Prompt | text | 1-10000 characters, non-empty |
| Template | name | 1-100 chars, alphanumeric + hyphens |
| Template | pattern | Contains {{variable}} placeholders |
| UsageEvent | duration_ms | Non-negative integer |

---

**Next**: Create contracts/dao-api.md with operation specifications
