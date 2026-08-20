# Quickstart Guide: TC Source Layout Refactoring

**Feature**: TC Source Layout Refactoring
**Branch**: `003-refactor-tc-source`
**Date**: 2025-10-12

## Overview

This guide explains how to use TC after the source layout refactoring. The good news: **all commands work exactly the same**. Only installation paths have changed.

---

## What Changed

### Before (Old Structure)

```
project/
├── bin/
│   └── tc                # CLI entry point
└── lib/
    ├── config/
    │   └── defaults.sh
    ├── core/
    │   └── *.sh
    └── utils/
        └── *.sh
```

**Installation**: `export PATH="$PWD/bin:$PATH"`

### After (New Structure)

```
project/
└── tc/                   # NEW: Framework root
    ├── tc                # CLI entry point (renamed from run)
    ├── config.sh         # Global config
    ├── lib/              # Framework libraries
    │   ├── core/
    │   └── utils/
    └── tests/            # Framework self-tests
```

**Installation**: `export PATH="$PWD/tc:$PATH"`

**Key Changes**:
- ✅ All framework code organized under `tc/` directory
- ✅ Executable is `tc/tc` instead of `bin/tc`
- ✅ Config is `tc/config.sh` instead of `lib/config/defaults.sh`
- ✅ Framework self-tests moved to `tc/tests/`

---

## Installation

### Method 1: PATH Installation (Recommended for Development)

```bash
# Clone repository
git clone https://github.com/ahoward/tc.git
cd tc

# Add to PATH
export PATH="$PWD/tc:$PATH"

# Make persistent
echo 'export PATH="'$PWD'/tc:$PATH"' >> ~/.bashrc

# Verify
tc --version
# tc v1.0.0 - island hopper
```

**Pros**: Easy to update (git pull), no sudo required
**Use case**: Development, testing, personal projects

---

### Method 2: Symlink Installation

```bash
# Clone repository
git clone https://github.com/ahoward/tc.git
cd tc

# Create symlink
sudo ln -s "$PWD/tc/tc" /usr/local/bin/tc

# Verify
tc --version
which tc
# /usr/local/bin/tc
```

**Pros**: System-wide access, still connected to repo for updates
**Note**: Library files remain in cloned directory - don't delete the repo
**Use case**: Personal machines, development systems

---

### Method 3: Copy Installation (Recommended for Production)

```bash
# Clone repository
git clone https://github.com/ahoward/tc.git
cd tc

# Copy entire framework directory
sudo cp -r tc /usr/local/

# Add to PATH
export PATH="/usr/local/tc:$PATH"

# Make persistent
echo 'export PATH="/usr/local/tc:$PATH"' >> ~/.bashrc

# Verify
tc --version
```

**Pros**: True system install, no git dependency
**Cons**: Must manually update (copy again) when upgrading
**Use case**: Production servers, CI/CD systems, containers

---

## Quick Verification

After installation, verify everything works:

```bash
# 1. Check version
tc --version

# 2. Show help
tc --help

# 3. Run hello-world example (if cloned from repo)
tc run examples/hello-world

# 4. Create a new test suite
tc new /tmp/my-test
tc run /tmp/my-test  # Should fail with NOT_IMPLEMENTED (expected)

# 5. Run framework self-tests (if available)
tc run tc/tests --all
```

If all commands work, installation is successful! 🚁

---

## Usage Examples

### Running Tests

```bash
# Run a single test suite
tc run tests/auth/login

# Run all tests in directory tree
tc run tests --all

# Run tests matching specific tag
tc run tests --tags api

# Run tests in parallel (auto-detect cores)
tc run tests --all --parallel

# Run tests in parallel with 4 workers
tc run tests --all --parallel 4
```

### Generating Tests

```bash
# Create basic test suite
tc new tests/my-feature

# Create test with metadata
tc new tests/auth/login \
  --tags "auth,api" \
  --priority high \
  --description "Test user login flow"

# Create from template
tc new tests/my-calc --from hello-world

# List available templates
tc new --list-examples

# Initialize tests directory
tc init tests
```

### Discovering Tests

```bash
# List all test suites
tc list tests

# Show all available tags
tc tags tests

# Explain specific test suite
tc explain tests/auth/login
```

---

## Configuration

### Global Configuration

Located at `tc/config.sh` (automatically loaded).

**Common Settings**:
```bash
TC_DEFAULT_TIMEOUT=300       # Test timeout (seconds)
TC_DEFAULT_COMPARISON="semantic_json"  # Comparison mode
TC_FUZZY_THRESHOLD=0.9       # Fuzzy match threshold
TC_PARALLEL_DEFAULT=4        # Parallel workers
TC_VERBOSE=0                 # Verbose output (0=off, 1=on)
```

**To customize**: Edit `tc/config.sh` directly.

---

### Suite-Specific Configuration

Create `config.sh` in any test suite to override global settings.

**Example** (`tests/slow-integration/config.sh`):
```bash
#!/usr/bin/env bash
# Override timeout for slow integration tests

TC_DEFAULT_TIMEOUT=1800      # 30 minutes (override global 5 minutes)
TC_VERBOSE=1                 # Enable verbose logging for this suite
```

**Usage**: No changes needed - TC automatically loads suite config when running tests.

```bash
tc run tests/slow-integration
# Automatically uses 30-minute timeout from suite config.sh
```

---

### Environment Variable Overrides

Override any setting at runtime:

```bash
# One-time timeout override
TC_DEFAULT_TIMEOUT=600 tc run tests/my-suite

# Verbose output for debugging
TC_VERBOSE=1 tc run tests --all

# JSON output format
TC_OUTPUT_FORMAT=json tc run tests/api
```

**Precedence** (highest to lowest):
1. Environment variables (highest)
2. Suite-specific `config.sh`
3. Global `tc/config.sh` (default)

---

## Migration from Old Structure

### For Developers

If you have an existing clone:

```bash
# Pull latest changes (includes refactoring)
git pull origin main

# Update PATH (if you were using old path)
# OLD: export PATH="$PWD/bin:$PATH"
# NEW:
export PATH="$PWD/tc:$PATH"

# Update your ~/.bashrc if you had it there
sed -i 's|bin:$PATH|tc:$PATH|g' ~/.bashrc

# Verify
tc --version
```

---

### For System Installations

**If you used symlink method**:

```bash
# Remove old symlink
sudo rm /usr/local/bin/tc

# Create new symlink
cd /path/to/tc/repo
sudo ln -s "$PWD/tc/tc" /usr/local/bin/tc

# Verify
tc --version
```

**If you used copy method**:

```bash
# Remove old files
sudo rm /usr/local/bin/tc
sudo rm -rf /usr/local/lib/tc  # If you had lib files there

# Copy new structure
cd /path/to/tc/repo
sudo cp -r tc /usr/local/

# Update PATH
export PATH="/usr/local/tc:$PATH"
echo 'export PATH="/usr/local/tc:$PATH"' >> ~/.bashrc

# Verify
tc --version
```

---

## Troubleshooting

### "tc: command not found"

**Problem**: `tc` not in PATH

**Solution**:
```bash
# Check PATH
echo $PATH

# Add tc directory to PATH
export PATH="/path/to/tc:$PATH"

# Or for copy installation
export PATH="/usr/local/tc:$PATH"
```

---

### "jq: command not found"

**Problem**: jq not installed (required dependency)

**Solution**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Fedora/RHEL
sudo dnf install jq

# Arch
sudo pacman -S jq
```

---

### "library not found" or source errors

**Problem**: TC_ROOT not resolving correctly

**Debug**:
```bash
# Check where tc is located
which tc
ls -l $(which tc)  # Shows symlink target if applicable

# Run with debug logging
TC_DEBUG=1 tc --version
```

**Solution**: Verify installation method matches directory structure:
- PATH method: `tc` executable at `tc/tc`
- Symlink: Link points to correct `tc/tc` location
- Copy: Entire `tc/` directory copied, not just executable

---

### Tests suddenly failing after upgrade

**Problem**: Test suites unchanged, but behavior differs

**Verify regression**:
```bash
# Run a specific test that was passing before
tc run tests/known-passing-test

# Check for version mismatch
tc --version

# Run framework self-tests to verify TC itself
tc run tc/tests --all
```

**Report**: If functionality genuinely differs, this is a bug - report at https://github.com/ahoward/tc/issues

---

## FAQ

### Q: Do I need to modify my existing test suites?

**A**: No! Test suites are unchanged. The refactoring only reorganizes TC framework code.

---

### Q: Can I still use `bin/tc`?

**A**: No, `bin/` directory no longer exists. Update your installation to use `tc/tc`.

---

### Q: Where are my test results stored?

**A**: Same place - `.tc-result` file in each test suite directory (unchanged).

---

### Q: Does this affect test execution performance?

**A**: No, performance is identical. Only file organization changed.

---

### Q: Can I have both old and new versions installed?

**A**: Not recommended. Uninstall old version before installing new one to avoid conflicts.

---

### Q: How do I know which version I have?

**A**: Run `tc --version`. If it works, check the directory structure:
- Old: `bin/tc` exists
- New: `tc/tc` exists

---

### Q: Do I need to update my CI/CD scripts?

**A**: Yes, update installation paths:
- Old: `export PATH="$PWD/bin:$PATH"`
- New: `export PATH="$PWD/tc:$PATH"`

---

## Next Steps

1. ✅ Install TC using one of the three methods
2. ✅ Verify installation with `tc --version`
3. ✅ Run hello-world example: `tc run examples/hello-world`
4. ✅ Create your first test: `tc new tests/my-feature`
5. ✅ Read full docs: [docs/readme.md](../../docs/readme.md)

---

## Resources

- **Full Documentation**: [docs/readme.md](../../docs/readme.md)
- **Test Generation Guide**: [docs/tc-new.md](../../docs/tc-new.md)
- **Feature Specification**: [spec.md](./spec.md)
- **Technical Contracts**: [contracts/](./contracts/)
- **GitHub Issues**: https://github.com/ahoward/tc/issues

---

**Made with ☕ and helicopters**

*"The chopper's fueled up and ready to go. Let's test some code."* — TC 🚁
