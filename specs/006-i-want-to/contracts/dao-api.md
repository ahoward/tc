# DAO API Contract

**Feature**: Multi-Language AI Prompt System
**Date**: 2025-10-15
**Purpose**: Define standard DAO interface and operation contracts across all languages

## DAO Interface

### Method Signature

**All Languages Must Implement**:

```
call(operation: String, params: Object) -> OperationResponse
```

**Parameters**:
- `operation`: Hierarchical path identifying the operation (e.g., "/prompt/generate")
- `params`: Operation-specific parameters as JSON object

**Returns**:
- `OperationResponse` with fields: `id`, `status`, `result` (optional), `error` (optional)

**Behavior**:
- Validates operation path
- Routes to appropriate handler
- Generates correlation UUID
- Stores pending result
- Executes operation (simulated)
- Updates stored result to completed/failed
- Returns initial response (status = "pending")

---

## Operations

### POST /prompt/generate

**Description**: Generate AI-processed prompt from input text (simulated)

**Input**:
```json
{
  "operation": "/prompt/generate",
  "params": {
    "text": "hello world"
  }
}
```

**Immediate Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending"
}
```

**Completed Result** (via `/result/poll`):
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

**Validation**:
- `params.text` must be non-empty string (1-10000 characters)

**Error Responses**:
```json
{
  "error": "Missing required parameter: text"
}
```

```json
{
  "error": "Text must be between 1 and 10000 characters"
}
```

---

### POST /template/create

**Description**: Create reusable template with variable placeholders

**Input**:
```json
{
  "operation": "/template/create",
  "params": {
    "name": "greeting",
    "pattern": "Hello {{name}}, welcome to {{place}}!",
    "variables": ["name", "place"]
  }
}
```

**Immediate Response**:
```json
{
  "id": "abc12345-...",
  "status": "pending"
}
```

**Completed Result**:
```json
{
  "id": "abc12345-...",
  "status": "completed",
  "result": {
    "id": "550e8400-...",
    "name": "greeting",
    "pattern": "Hello {{name}}, welcome to {{place}}!",
    "variables": ["name", "place"]
  }
}
```

**Validation**:
- `params.name`: 1-100 characters, alphanumeric + hyphens
- `params.pattern`: non-empty string with {{variable}} placeholders
- `params.variables`: array of strings matching placeholders in pattern

**Error Responses**:
```json
{
  "error": "Invalid template name: must be alphanumeric with hyphens"
}
```

---

### POST /template/render

**Description**: Render template with variable substitution

**Input**:
```json
{
  "operation": "/template/render",
  "params": {
    "template_id": "550e8400-...",
    "values": {
      "name": "Alice",
      "place": "Wonderland"
    }
  }
}
```

**Immediate Response**:
```json
{
  "id": "xyz67890-...",
  "status": "pending"
}
```

**Completed Result**:
```json
{
  "id": "xyz67890-...",
  "status": "completed",
  "result": {
    "template_id": "550e8400-...",
    "rendered": "Hello Alice, welcome to Wonderland!",
    "variables_used": {
      "name": "Alice",
      "place": "Wonderland"
    }
  }
}
```

**Validation**:
- `params.template_id`: valid UUID of existing template
- `params.values`: object with keys matching template variables

**Error Responses**:
```json
{
  "error": "Template not found: 550e8400-..."
}
```

```json
{
  "error": "Missing required variable: name"
}
```

---

### POST /usage/track

**Description**: Track operation usage for analytics

**Input**:
```json
{
  "operation": "/usage/track",
  "params": {
    "operation": "/prompt/generate",
    "duration_ms": 45
  }
}
```

**Immediate Response** (completes synchronously):
```json
{
  "id": "def45678-...",
  "status": "completed",
  "result": {
    "tracked": true,
    "operation": "/prompt/generate",
    "timestamp": "2025-10-15T12:00:00Z"
  }
}
```

**Validation**:
- `params.operation`: valid operation path
- `params.duration_ms`: non-negative integer

**Note**: This operation completes immediately (synchronous) for demo simplicity

---

### POST /result/poll

**Description**: Retrieve operation result by correlation UUID

**Input**:
```json
{
  "operation": "/result/poll",
  "params": {
    "id": "550e8400-..."
  }
}
```

**Response** (pending):
```json
{
  "id": "550e8400-...",
  "status": "pending"
}
```

**Response** (completed):
```json
{
  "id": "550e8400-...",
  "status": "completed",
  "result": {
    "text": "hello world",
    "processed": "HELLO WORLD [AI-processed]",
    "timestamp": "2025-10-15T12:00:00Z"
  }
}
```

**Response** (failed):
```json
{
  "id": "550e8400-...",
  "status": "failed",
  "error": "Operation failed: invalid input"
}
```

**Response** (not found):
```json
{
  "error": "Result not found or expired: 550e8400-..."
}
```

**Validation**:
- `params.id`: valid UUID format

---

## TC Adapter Contract

### Interface

**All Language Adapters Must Conform**:

**Executable**: Script or compiled binary accepting stdin

**Input Format**: JSON via stdin
```json
{
  "operation": "/prompt/generate",
  "params": {
    "text": "hello world"
  }
}
```

**Output Format**: JSON via stdout
```json
{
  "id": "550e8400-...",
  "status": "pending"
}
```

**Error Format**: JSON via stdout (not stderr for tc compatibility)
```json
{
  "error": "Invalid operation: /unknown/path"
}
```

**Exit Codes**:
- `0`: Success (operation accepted or error returned in JSON)
- Non-zero: Fatal adapter error (adapter crashed, not operation failure)

### Example Adapters

**Ruby** (`tc_adapter.rb`):
```ruby
#!/usr/bin/env ruby
require_relative 'lib/dao'
require 'json'

begin
  input = JSON.parse(STDIN.read)
  dao = DAO.new
  response = dao.call(input['operation'], input['params'] || {})
  puts JSON.generate(response)
rescue => e
  puts JSON.generate({ error: "Adapter error: #{e.message}" })
  exit 1
end
```

**Go** (`adapter/main.go`):
```go
package main

import (
    "encoding/json"
    "os"
    "yourproject/dao"
)

type Request struct {
    Operation string                 `json:"operation"`
    Params    map[string]interface{} `json:"params"`
}

func main() {
    var req Request
    if err := json.NewDecoder(os.Stdin).Decode(&req); err != nil {
        json.NewEncoder(os.Stdout).Encode(map[string]string{
            "error": "Invalid input JSON",
        })
        os.Exit(1)
    }

    d := dao.NewDAO()
    response := d.Call(req.Operation, req.Params)
    json.NewEncoder(os.Stdout).Encode(response)
}
```

**Python 🐍** (`adapter.py`):
```python
#!/usr/bin/env python3
import json
import sys
from dao import DAO

try:
    input_data = json.load(sys.stdin)  # Read from stdin 🐍
    dao = DAO()
    response = dao.call(
        input_data.get('operation'),
        input_data.get('params', {})
    )
    print(json.dumps(response))  # Write to stdout 🐍
except Exception as e:
    print(json.dumps({"error": f"Adapter error: {e}"}))
    sys.exit(1)
```

---

## Cross-Language Consistency Requirements

All implementations MUST:

1. **Accept identical input format** (JSON with `operation` and `params` fields)
2. **Return identical output format** (JSON with `id`, `status`, `result`, `error` fields)
3. **Generate UUIDs** in standard v4 format (lowercase with hyphens)
4. **Use consistent operation paths** (exact string match across languages)
5. **Return same error messages** for equivalent error conditions
6. **Follow same validation rules** (e.g., text length 1-10000 chars)

### Validation via TC Test Suite

The tc test suite will verify:
- Input → Output mapping is identical across languages
- UUID format is consistent (pattern match, not exact value match)
- Error handling produces equivalent error messages
- All operations complete successfully with valid input
- All operations fail appropriately with invalid input

---

## Operation Summary Table

| Operation | Method | Async | Validation | Returns |
|-----------|--------|-------|------------|---------|
| `/prompt/generate` | POST | Yes | text: 1-10000 chars | Processed prompt |
| `/template/create` | POST | Yes | name: alphanum+hyphen, pattern: non-empty | Template with UUID |
| `/template/render` | POST | Yes | template_id: exists, values: complete | Rendered text |
| `/usage/track` | POST | **No** | operation: valid, duration: ≥0 | Tracking confirmation |
| `/result/poll` | POST | N/A | id: UUID format | Operation result |

---

## Error Codes (Informal)

Since this is a demo without formal HTTP status codes, errors are distinguished by message content:

| Error Type | Message Pattern | Example |
|------------|-----------------|---------|
| Invalid Operation | `"Invalid operation: ..."` | `"Invalid operation: /unknown/path"` |
| Missing Parameter | `"Missing required parameter: ..."` | `"Missing required parameter: text"` |
| Validation Failure | `"... must be ..."` | `"Text must be between 1 and 10000 characters"` |
| Not Found | `"... not found ..."` | `"Template not found: 550e8400-..."` |
| Adapter Error | `"Adapter error: ..."` | `"Adapter error: Invalid JSON"` |

---

**Next**: Create quickstart.md with usage examples
