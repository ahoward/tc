# Quickstart: Multi-Language DAO System

**Feature**: Multi-Language AI Prompt System
**Date**: 2025-10-15
**Purpose**: Get started quickly with any language implementation

## Overview

This project demonstrates the System Adapter Pattern with 5 language implementations of an AI prompt management system. Each language provides identical functionality through a unified DAO interface.

**Languages**: Ruby 💎 | Go | Rust 🦀 | JavaScript | Python 🐍

---

## Ruby 💎 (Really Clean!)

### Setup
```bash
cd projects/ruby
# No dependencies needed (uses standard library)!
```

### Run Adapter
```bash
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./tc_adapter.rb
```

### Expected Output
```json
{"id":"550e8400-e29b-41d4-a716-446655440000","status":"pending"}
```

### Run Tests
```bash
cd ../../examples/multi-lang-dao
ln -sf ../../projects/ruby/tc_adapter.rb run
tc .
```

---

## Go

### Setup
```bash
cd projects/go
go mod init github.com/yourname/dao-demo  # if go.mod doesn't exist
```

### Build Adapter
```bash
go build -o adapter ./adapter
```

### Run Adapter
```bash
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./adapter
```

### Run Tests
```bash
cd ../../examples/multi-lang-dao
ln -sf ../../projects/go/adapter run
tc .
```

---

## Rust 🦀

### Setup
```bash
cd projects/rust
cargo build --release
```

### Run Adapter
```bash
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./target/release/adapter
```

### Run Tests
```bash
cd ../../examples/multi-lang-dao
ln -sf ../../projects/rust/target/release/adapter run
tc .
```

---

## JavaScript (Node.js)

### Setup
```bash
cd projects/javascript
npm install  # installs uuid package
```

### Run Adapter
```bash
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./adapter.js
```

### Run Tests
```bash
cd ../../examples/multi-lang-dao
ln -sf ../../projects/javascript/adapter.js run
tc .
```

---

## Python 🐍

### Setup
```bash
cd projects/python
# No dependencies needed! Built-in modules only 🐍
```

### Run Adapter
```bash
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./adapter.py
```

### Run Tests
```bash
cd ../../examples/multi-lang-dao
ln -sf ../../projects/python/adapter.py run
tc .
```

---

## Testing All Languages

### Run Against Single Language
```bash
cd examples/multi-lang-dao

# Ruby
ln -sf ../../projects/ruby/tc_adapter.rb run
tc .

# Go
ln -sf ../../projects/go/adapter run
tc .

# And so on...
```

### Compare All Languages (Future Feature)
```bash
cd examples/multi-lang-dao
tc . --adapters ruby,go,rust,javascript,python --compare
```

**Expected Output**:
```
🚁 Comparison Report

Suite: examples/multi-lang-dao
┌────────────┬────────┬────────┬──────────┐
│ Adapter    │ Passed │ Failed │ Avg Time │
├────────────┼────────┼────────┼──────────┤
│ ruby       │ 5      │ 0      │ 45ms     │
│ go         │ 5      │ 0      │ 12ms     │
│ rust       │ 5      │ 0      │ 8ms      │
│ javascript │ 5      │ 0      │ 35ms     │
│ python     │ 5      │ 0      │ 50ms     │
└────────────┴────────┴────────┴──────────┘

✓ All implementations pass identical test suite
```

---

## Example Operations

### Prompt Generation

**Input**:
```json
{
  "operation": "/prompt/generate",
  "params": {
    "text": "hello world"
  }
}
```

**Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending"
}
```

### Template Creation

**Input**:
```json
{
  "operation": "/template/create",
  "params": {
    "name": "greeting",
    "pattern": "Hello {{name}}!",
    "variables": ["name"]
  }
}
```

**Response**:
```json
{
  "id": "abc12345-...",
  "status": "pending"
}
```

### Result Polling

**Input**:
```json
{
  "operation": "/result/poll",
  "params": {
    "id": "550e8400-..."
  }
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

---

## Test Suite Structure

```
examples/multi-lang-dao/
├── README.md
├── data/
│   ├── prompt-generate/
│   │   ├── input.json      # Operation input
│   │   └── expected.json   # Expected response (pattern match for UUID)
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
│       ├── input.json
│       └── expected.json
└── run                     # Symlink to active adapter
```

---

## Troubleshooting

### Ruby: "Permission denied"
```bash
chmod +x projects/ruby/tc_adapter.rb
```

### Go: "package not found"
```bash
cd projects/go
go mod tidy
```

### Rust: "cargo not found"
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### JavaScript: "Cannot find module 'uuid'"
```bash
cd projects/javascript
npm install uuid
```

### Python: "No module named 'dao'"
```bash
# Make sure you're in projects/python directory
cd projects/python
# Run from this directory
```

### Test Failure: UUID Mismatch
This is expected! UUIDs are random. Tests use pattern matching:
```json
{
  "id": "<uuid>",  # Matches any valid UUID v4
  "status": "pending"
}
```

---

## Next Steps

1. ✅ **Run tests**: Verify each language implementation passes tc test suite
2. ✅ **Compare**: Use comparison mode to validate identical behavior
3. ✅ **Modify**: Try adding a new operation to one language
4. ✅ **Port**: Implement new operation in all other languages
5. ✅ **Test**: Verify tests still pass across all implementations

---

## Development Workflow

### Adding a New Operation

1. **Update contracts**: Add operation spec to `specs/006-i-want-to/contracts/dao-api.md`
2. **Create tests**: Add test scenario to `examples/multi-lang-dao/data/`
3. **Implement in Ruby** (showcase clean code):
   - Add handler to `lib/operations.rb`
   - Update routing in `lib/dao.rb`
4. **Verify Ruby tests pass**: `tc examples/multi-lang-dao` (with Ruby adapter)
5. **Port to other languages**: Go, Rust, JavaScript, Python
6. **Verify all tests pass**: Test each language separately
7. **Run comparison**: Validate identical behavior across all

---

## Language-Specific Notes

### Ruby 💎
- **Focus**: Clean, idiomatic code
- **Style**: Rubocop-compliant, YARD docs
- **Features**: Modules for namespacing, expressive method names

### Go
- **Focus**: Performance baseline
- **Style**: gofmt-compliant, godoc comments
- **Features**: Interfaces, goroutines (optional for demo)

### Rust 🦀
- **Focus**: Memory safety, high performance
- **Style**: rustfmt-compliant, rustdoc comments
- **Features**: Traits, ownership model, Arc<Mutex<T>>

### JavaScript
- **Focus**: Async-native patterns
- **Style**: ESLint-compliant, JSDoc comments
- **Features**: ES6 classes, promises (optional for demo)

### Python 🐍
- **Focus**: Readability, playful theming
- **Style**: PEP 8-compliant, type hints
- **Features**: Dataclasses, snake_case, 🐍 emoji comments

---

## Resources

- [System Adapter Pattern Spec](../005-consider-research-methodlogies/spec.md)
- [DAO API Contract](./contracts/dao-api.md)
- [Data Model](./data-model.md)
- [tc Framework Docs](../../docs/readme.md)

---

**Happy Testing! 🚁**
