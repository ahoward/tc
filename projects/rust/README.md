# Rust DAO Implementation 🦀

**Status**: Memory-safe, high-performance implementation

## Overview

Multi-language DAO demo - Rust implementation demonstrating safety and speed.

## Requirements

- Rust 1.75+
- Dependencies: serde, serde_json, uuid (minimal, standard crates)

## Usage

```bash
# Build adapter (release mode recommended)
cargo build --release

# Run adapter
echo '{"operation": "/prompt/generate", "params": {"text": "hello"}}' | ./target/release/adapter

# Run with tc test suite
cd ../../examples/multi-lang-dao
ln -sf ../../projects/rust/target/release/adapter run
tc .
```

## Structure

```
src/
├── lib.rs          # Library root
├── dao.rs          # DAO trait and implementation
├── operations.rs   # Operation handlers
├── store.rs        # Thread-safe result storage
└── bin/
    └── adapter.rs  # tc adapter binary
```

## Operations

- `/prompt/generate` - Process AI prompt (simulated)
- `/template/create` - Create reusable template
- `/template/render` - Render template with variables
- `/usage/track` - Track operation usage
- `/result/poll` - Retrieve async operation result

## Development

```bash
# Build (debug)
cargo build

# Build (release - recommended for testing)
cargo build --release

# Format code
cargo fmt

# Lint
cargo clippy

# Run tests
cargo test
```
