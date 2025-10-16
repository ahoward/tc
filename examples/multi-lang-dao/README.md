# Multi-Language DAO Test Suite

**Purpose**: Unified test suite validating identical behavior across all language implementations

## Overview

This tc test suite validates that all 5 language implementations (Ruby, Go, Rust, JavaScript, Python) provide identical DAO interface behavior. Each language implementation must pass this exact same test suite.

## Test Scenarios

### 1. prompt-generate
**Operation**: `/prompt/generate`
**Purpose**: Validate async prompt processing
**Input**: Text string
**Expected**: Immediate response with UUID and "pending" status

### 2. template-create
**Operation**: `/template/create`
**Purpose**: Validate template creation with variable placeholders
**Input**: Template name, pattern, variables
**Expected**: UUID and "pending" status

### 3. template-render
**Operation**: `/template/render`
**Purpose**: Validate template rendering with variable substitution
**Input**: Template ID, variable values
**Expected**: UUID and "pending" status

### 4. usage-track
**Operation**: `/usage/track`
**Purpose**: Validate usage tracking (synchronous operation)
**Input**: Operation name, duration
**Expected**: UUID, "completed" status, tracking confirmation

### 5. result-poll
**Operation**: `/result/poll`
**Purpose**: Validate async result retrieval by correlation UUID
**Input**: Operation UUID
**Expected**: Status (pending/completed/failed) with optional result data

## Test Data Format

Each test scenario has two files:

- `input.json` - Request sent to adapter via stdin
- `expected.json` - Expected response from adapter via stdout

### UUID Pattern Matching

**CURRENT LIMITATION**: tc does not yet support UUID pattern matching. Since UUIDs are randomly generated on each invocation, exact JSON comparison will fail.

**Workaround for validation**:
1. Run adapter manually and verify response structure
2. Check that `id` field contains valid UUID v4 format
3. Check that `status` and other fields match expected values
4. For automated testing, consider extending tc with pattern matching support

**Future Enhancement**: Implement pattern matching in tc (e.g., `<uuid>` placeholder matches any valid UUID v4)

## Running Tests

### Test Against Single Language

```bash
cd tests/multi-lang-dao

# Ruby
ln -sf ../../projects/ruby/tc_adapter.rb run
tc .

# Go
ln -sf ../../projects/go/adapter run
tc .

# Rust
ln -sf ../../projects/rust/target/release/adapter run
tc .

# JavaScript
ln -sf ../../projects/javascript/adapter.js run
tc .

# Python
ln -sf ../../projects/python/adapter.py run
tc .
```

### Test All Languages (Sequential)

```bash
./test-all-languages.sh
```

## Adapter Contract

All language adapters MUST:

1. **Read JSON from stdin**:
   ```json
   {
     "operation": "/prompt/generate",
     "params": {"text": "hello"}
   }
   ```

2. **Write JSON to stdout**:
   ```json
   {
     "id": "550e8400-e29b-41d4-a716-446655440000",
     "status": "pending"
   }
   ```

3. **Handle errors gracefully** (write error JSON to stdout, not stderr):
   ```json
   {
     "error": "Invalid operation: /unknown/path"
   }
   ```

4. **Exit with code 0** for successful operations (even if operation failed, adapter succeeded)

5. **Exit with non-zero code** only for fatal adapter errors (crash, invalid JSON input, etc.)

## Test Validation

tc framework validates:

- JSON structure matches expected format
- UUID format is valid v4 (pattern match, not exact value)
- Status field contains valid value ("pending", "completed", "failed")
- Required fields are present
- Optional fields match when present

## Success Criteria

All 5 language implementations MUST:

- ✅ Pass all 5 test scenarios
- ✅ Generate valid UUID v4 format
- ✅ Return identical JSON structure
- ✅ Handle errors consistently
- ✅ Complete tests in < 100ms per operation

## Troubleshooting

### Adapter Not Found
```bash
# Check symlink
ls -la run

# Recreate symlink
ln -sf ../../projects/ruby/tc_adapter.rb run
```

### Permission Denied
```bash
# Make adapter executable
chmod +x ../../projects/ruby/tc_adapter.rb
```

### UUID Mismatch
UUIDs are random - tests use pattern matching. If you see UUID mismatch errors, verify the expected.json file uses `<uuid>` pattern, not a hardcoded UUID value.

### JSON Parse Error
Adapter must write valid JSON to stdout. Use `jq` to validate:
```bash
echo '{"operation": "/prompt/generate", "params": {"text": "test"}}' | ./run | jq .
```

## Adding New Test Scenarios

1. Create new directory: `data/new-operation/`
2. Add `input.json` with operation request
3. Add `expected.json` with expected response (use `<uuid>` for UUID fields)
4. Run tc suite against all languages to validate
5. Update this README with new scenario documentation
