#!/usr/bin/env bash
# tc-kit-common.sh - Shared utilities for tc-kit slash commands
# Part of tc-kit: AI-driven testing integration for tc framework

set -euo pipefail

# Detect TTY mode (reuse tc's logic)
function is_tty() {
  [ -t 1 ] && [ "${TC_FANCY_OUTPUT:-auto}" != "false" ]
}

# Auto-detect feature directory from git branch or explicit path
function detect_feature_dir() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  if [ -n "$branch" ] && [ -d "specs/$branch" ]; then
    echo "specs/$branch"
  elif [ -d "specs" ]; then
    # Fall back to finding most recent spec directory
    local latest=$(find specs -maxdepth 1 -type d -name "[0-9]*" | sort -r | head -1)
    if [ -n "$latest" ]; then
      echo "$latest"
    else
      echo "ERROR: Cannot auto-detect feature directory" >&2
      return 1
    fi
  else
    echo "ERROR: specs/ directory not found" >&2
    return 1
  fi
}

# Validate JSON file
function validate_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  if ! jq empty "$file" 2>/dev/null; then
    echo "ERROR: Invalid JSON in $file" >&2
    return 1
  fi

  return 0
}

# Zero-pad numbers for directory names
function zeropad() {
  printf '%02d' "$1"
}

# Check if tc/spec-kit directory exists, create if needed
function ensure_spec_kit_dir() {
  if [ ! -d "tc/spec-kit" ]; then
    mkdir -p "tc/spec-kit"
  fi
}

# Log message with timestamp (if verbose mode)
function log_verbose() {
  if [ "${VERBOSE:-false}" == "true" ]; then
    echo "[$(date '+%H:%M:%S')] $*" >&2
  fi
}

# Log info message
function log_info() {
  echo "$*" >&2
}

# Log error message
function log_error() {
  echo "ERROR: $*" >&2
}

# Log warning message
function log_warning() {
  echo "WARNING: $*" >&2
}

# Success indicator (with emoji if TTY)
function log_success() {
  if is_tty; then
    echo "✓ $*"
  else
    echo "SUCCESS: $*"
  fi
}

# Failure indicator (with emoji if TTY)
function log_failure() {
  if is_tty; then
    echo "✗ $*" >&2
  else
    echo "FAILURE: $*" >&2
  fi
}

# Warning indicator (with emoji if TTY)
function log_warn_indicator() {
  if is_tty; then
    echo "⚠ $*"
  else
    echo "WARNING: $*"
  fi
}
