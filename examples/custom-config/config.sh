#!/usr/bin/env bash
# Custom configuration for this test suite
# Demonstrates suite-specific config overrides

# Override timeout for slower tests
TC_DEFAULT_TIMEOUT=600  # 10 minutes instead of global 5 minutes

# Enable verbose logging for this suite
TC_VERBOSE=1
