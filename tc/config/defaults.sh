#!/usr/bin/env bash
# tc global configuration
# the helicopter's flight plan 🚁
#
# Configuration hierarchy (highest to lowest priority):
#   1. Environment variables (TC_* set before running tc)
#   2. Suite-specific config.sh (optional file in test suite directory)
#   3. This file (global defaults)
#
# To override for a specific suite, create config.sh in the suite directory
# To override for a single run, set environment variables:
#   TC_DEFAULT_TIMEOUT=600 tc run tests/my-suite

# timeout settings (seconds)
: ${TC_DEFAULT_TIMEOUT:=300}          # 5 minutes default
: ${TC_MAX_TIMEOUT:=3600}            # 1 hour max

# comparison modes
: ${TC_DEFAULT_COMPARISON:="semantic_json"}  # order-independent json
: ${TC_COMPARISON_MODES:="semantic_json whitespace_norm fuzzy"}

# fuzzy matching threshold (0.0 to 1.0)
: ${TC_FUZZY_THRESHOLD:=0.9}         # 90% similarity required

# parallel execution
: ${TC_PARALLEL_MODE:="auto"}        # auto-detect cpu cores
: ${TC_PARALLEL_DEFAULT:=4}          # fallback if detection fails

# output settings
: ${TC_OUTPUT_FORMAT:="human"}       # human, json, jsonl
: ${TC_RESULT_FILE:="tc-result"}     # result file name in each suite (no dot prefix)

# fancy output settings (heli-cool-stdout feature)
: ${TC_FANCY_OUTPUT:=""}             # auto-detect TTY if empty, "true"/"false" to override
: ${TC_REPORT_DIR:="tc/tmp"}         # directory for JSONL log files (no dot prefix)
: ${TC_LOG_FILE:="report.jsonl"}     # log filename within TC_REPORT_DIR
: ${TC_NO_ANIMATION:=0}              # disable animation (0=no, 1=yes)
: ${TC_NO_COLOR:=0}                  # disable colors (0=no, 1=yes, also respects NO_COLOR)

# behavior flags
: ${TC_FAIL_FAST:=0}                 # stop on first failure (0=no, 1=yes)
: ${TC_VERBOSE:=0}                   # verbose output (0=no, 1=yes)
: ${TC_DEBUG:=0}                     # debug mode (0=no, 1=yes)

# colors (ansi escape codes)
TC_COLOR_PASS="\033[0;32m"     # green
TC_COLOR_FAIL="\033[0;31m"     # red
TC_COLOR_WARN="\033[0;33m"     # yellow
TC_COLOR_INFO="\033[0;36m"     # cyan
TC_COLOR_RESET="\033[0m"       # reset

# disable colors if not a tty
if [ ! -t 1 ]; then
    TC_COLOR_PASS=""
    TC_COLOR_FAIL=""
    TC_COLOR_WARN=""
    TC_COLOR_INFO=""
    TC_COLOR_RESET=""
fi

# lifecycle hooks settings (007-description-add-lifecycle feature)
: ${TC_HOOK_TIMEOUT:=30}              # hook execution timeout (seconds)
: ${TC_HOOKS_ENABLED:=true}           # enable/disable hooks globally
: ${TC_RUNNER_SHUTDOWN_TIMEOUT:=5}    # stateful runner graceful shutdown timeout (seconds)

# pattern matching - custom patterns for JSON comparison
# format: "pattern_name:regex" - one per line
# built-in patterns: <uuid>, <timestamp>, <number>, <string>, <boolean>, <null>, <any>
# example custom patterns:
#   TC_CUSTOM_PATTERNS="email:^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
#   ipv4:^([0-9]{1,3}\.){3}[0-9]{1,3}$
#   phone:^\+?[0-9]{10,15}$"
: ${TC_CUSTOM_PATTERNS:=""}
