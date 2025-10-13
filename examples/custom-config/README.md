# Custom Configuration Example

This test suite demonstrates suite-specific configuration overrides.

## Configuration Hierarchy

TC supports three levels of configuration (highest to lowest priority):

1. **Environment variables** - Set before running tc
2. **Suite-specific config.sh** - This file
3. **Global config.sh** - tc/config.sh

## This Suite's Config

See `config.sh` in this directory:

```bash
# Override timeout for slower tests
TC_DEFAULT_TIMEOUT=600  # 10 minutes instead of global 5 minutes

# Enable verbose logging for this suite  
TC_VERBOSE=1
```

## Testing

```bash
# Run with suite config (10 minute timeout, verbose)
tc run examples/custom-config

# Override with environment variable (2 minute timeout)
TC_DEFAULT_TIMEOUT=120 tc run examples/custom-config
```

## Use Cases

- Slow integration tests that need longer timeouts
- Debugging specific test suites with verbose logging
- Different comparison modes for specific tests
- Custom parallel worker counts
