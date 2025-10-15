# Ruby DAO Implementation 💎

**Status**: Clean, idiomatic Ruby implementation

## Overview

Multi-language DAO demo - Ruby implementation showcasing clean, expressive code.

## Requirements

- Ruby 3.2+
- Standard library only (no external gems!)

## Usage

```bash
# Run adapter directly
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./tc_adapter.rb

# Run with tc test suite
cd ../../tests/multi-lang-dao
ln -sf ../../projects/ruby/tc_adapter.rb run
tc .
```

## Structure

```
lib/
├── dao.rb           # Main DAO interface
├── operations.rb    # Operation handlers
└── result_store.rb  # In-memory result storage
tc_adapter.rb        # tc test adapter (executable)
```

## Operations

- `/prompt/generate` - Process AI prompt (simulated)
- `/template/create` - Create reusable template
- `/template/render` - Render template with variables
- `/usage/track` - Track operation usage
- `/result/poll` - Retrieve async operation result

## Development

No dependencies to install! Pure Ruby standard library.

```bash
# Make adapter executable
chmod +x tc_adapter.rb

# Test manually
./tc_adapter.rb < test_input.json
```
