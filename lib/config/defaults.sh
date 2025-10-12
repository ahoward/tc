#!/usr/bin/env bash
# tc defaults configuration
# the helicopter's flight plan 🚁

# timeout settings (seconds)
TC_DEFAULT_TIMEOUT=300          # 5 minutes default
TC_MAX_TIMEOUT=3600            # 1 hour max

# comparison modes
TC_DEFAULT_COMPARISON="semantic_json"  # order-independent json
TC_COMPARISON_MODES="semantic_json whitespace_norm fuzzy"

# fuzzy matching threshold (0.0 to 1.0)
TC_FUZZY_THRESHOLD=0.9         # 90% similarity required

# parallel execution
TC_PARALLEL_MODE="auto"        # auto-detect cpu cores
TC_PARALLEL_DEFAULT=4          # fallback if detection fails

# output settings
TC_OUTPUT_FORMAT="human"       # human, json, jsonl
TC_RESULT_FILE=".tc-result"    # result file name in each suite

# behavior flags
TC_FAIL_FAST=0                 # stop on first failure (0=no, 1=yes)
TC_VERBOSE=0                   # verbose output (0=no, 1=yes)
TC_DEBUG=0                     # debug mode (0=no, 1=yes)

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
