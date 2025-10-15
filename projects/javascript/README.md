# JavaScript DAO Implementation

**Status**: Node.js async-native implementation

## Overview

Multi-language DAO demo - JavaScript/Node.js implementation with modern ES6+ patterns.

## Requirements

- Node.js 18+
- Dependencies: uuid (standard npm package)

## Usage

```bash
# Install dependencies
npm install

# Run adapter
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./adapter.js

# Run with tc test suite
cd ../../tests/multi-lang-dao
ln -sf ../../projects/javascript/adapter.js run
tc .
```

## Structure

```
lib/
├── dao.js           # DAO class
├── operations.js    # Operation handlers
└── store.js         # Result storage
adapter.js           # tc adapter (executable)
```

## Operations

- `/prompt/generate` - Process AI prompt (simulated)
- `/template/create` - Create reusable template
- `/template/render` - Render template with variables
- `/usage/track` - Track operation usage
- `/result/poll` - Retrieve async operation result

## Development

```bash
# Install dependencies
npm install

# Make adapter executable
chmod +x adapter.js

# Test manually
./adapter.js < test_input.json
```
