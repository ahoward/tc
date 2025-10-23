#!/usr/bin/env bash
# tc-kit-refine.sh - Incrementally refine abstract tests
# Part of tc-kit integration with spec-kit for tc framework

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tc-kit-common.sh"

# Default values
SUITE_PATH=""
MATURITY_LEVEL=""
INTERACTIVE=false
SUGGEST_ONLY=true
APPLY_CHANGES=false
DRY_RUN=false
VERBOSE=false

# Show usage
function show_usage() {
  cat <<EOF
Usage: tc-kit-refine.sh [OPTIONS]

Incrementally refine abstract tests into technology-specific assertions.

OPTIONS:
  --level LEVEL     Force maturity level: concept/exploration/implementation
  --suite PATH      Refine specific test suite only
  --interactive     Prompt for each refinement decision
  --suggest         Show refinement suggestions without applying (default)
  --apply           Apply suggested refinements
  --dry-run         Show changes without modifying files
  --verbose         Show detailed analysis progress
  --help            Show this help message

EXAMPLES:
  tc-kit-refine.sh --suggest
  tc-kit-refine.sh --suite tc/tests/my-feature/user-story-01 --apply
  tc-kit-refine.sh --level exploration --apply
  tc-kit-refine.sh --interactive

EOF
}

# Parse command-line options
function parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --level)
        MATURITY_LEVEL="$2"
        shift 2
        ;;
      --suite)
        SUITE_PATH="$2"
        shift 2
        ;;
      --interactive)
        INTERACTIVE=true
        shift
        ;;
      --suggest)
        SUGGEST_ONLY=true
        APPLY_CHANGES=false
        shift
        ;;
      --apply)
        SUGGEST_ONLY=false
        APPLY_CHANGES=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

# Validate maturity level value
function validate_maturity_level() {
  local level="$1"
  case "$level" in
    concept|exploration|implementation|"")
      return 0
      ;;
    *)
      log_error "Invalid level '$level' (must be concept/exploration/implementation)"
      exit 1
      ;;
  esac
}

# Find all test suites
function find_test_suites() {
  local base_dir="${1:-tc/tests}"

  if [ ! -d "$base_dir" ]; then
    log_error "Test directory not found: $base_dir"
    exit 1
  fi

  # Find all directories containing a 'run' script
  find "$base_dir" -type f -name "run" -executable | while read -r run_script; do
    dirname "$run_script"
  done
}

# Detect if run script has been modified beyond template
function detect_implementation() {
  local run_script="$1"

  if [ ! -f "$run_script" ]; then
    echo "false"
    return
  fi

  # Check if run script still contains NOT_IMPLEMENTED marker
  if grep -q "NOT_IMPLEMENTED" "$run_script" 2>/dev/null; then
    echo "false"
  else
    echo "true"
  fi
}

# Count patterns in expected.json files
function count_patterns() {
  local suite_path="$1"
  local pattern_count=0

  # Find all expected.json files in the suite's data directory
  if [ -d "$suite_path/data" ]; then
    while IFS= read -r expected_file; do
      if [ -n "$expected_file" ] && [ -f "$expected_file" ]; then
        # Count occurrences of pattern markers like <uuid>, <timestamp>, etc.
        local count
        count=$(grep -o '<[a-z_]*>' "$expected_file" 2>/dev/null | wc -l || echo "0")
        # Trim whitespace and ensure it's a number
        count=$(echo "$count" | tr -d '[:space:]')
        count=${count:-0}
        pattern_count=$((pattern_count + count))
      fi
    done < <(find "$suite_path/data" -name "expected.json" 2>/dev/null || true)
  fi

  echo "$pattern_count"
}

# Detect maturity signals for a test suite
function detect_maturity_signals() {
  local suite_path="$1"
  local run_script="$suite_path/run"

  # Check if implementation exists
  local has_implementation
  has_implementation=$(detect_implementation "$run_script")

  # Count pattern usage
  local pattern_count
  pattern_count=$(count_patterns "$suite_path")

  # For now, we don't count passing runs (would require tc execution history)
  local passing_runs=0

  # Output as JSON-like string for parsing
  echo "$has_implementation|$passing_runs|$pattern_count"
}

# Suggest maturity level based on signals
function suggest_maturity_level() {
  local current_level="$1"
  local has_implementation="$2"
  local passing_runs="${3:-0}"
  local pattern_count="${4:-0}"

  # Ensure numeric values
  passing_runs=${passing_runs:-0}
  pattern_count=${pattern_count:-0}

  # Apply transition rules from research.md
  case "$current_level" in
    concept)
      if [ "$has_implementation" = "true" ]; then
        echo "exploration"
      else
        echo "concept"
      fi
      ;;
    exploration)
      # Would need 5+ passing runs for implementation level
      # For MVP, we'll use pattern count as a heuristic
      if [ "$passing_runs" -ge 5 ] || [ "$pattern_count" -lt 2 ]; then
        echo "implementation"
      else
        echo "exploration"
      fi
      ;;
    implementation)
      echo "implementation"
      ;;
    *)
      echo "concept"
      ;;
  esac
}

# Load current maturity level for a suite
function get_current_maturity() {
  local suite_path="$1"
  local maturity_file="tc/spec-kit/maturity.json"

  if [ ! -f "$maturity_file" ]; then
    echo "concept"
    return
  fi

  # Extract maturity level for this suite
  local level
  level=$(jq -r --arg suite "$suite_path" '.suites[$suite].maturity_level // "concept"' "$maturity_file" 2>/dev/null || echo "concept")
  echo "$level"
}

# Update maturity.json with new level and signals
function update_maturity() {
  local suite_path="$1"
  local new_level="$2"
  local has_implementation="$3"
  local passing_runs="$4"
  local pattern_count="$5"
  local manual_override="${6:-}"

  local maturity_file="tc/spec-kit/maturity.json"

  if [ ! -f "$maturity_file" ]; then
    log_error "maturity.json not found (run /tc.specify first)"
    exit 1
  fi

  # Get pattern types from expected.json
  local pattern_types
  pattern_types=$(get_pattern_types "$suite_path")

  # Update maturity.json using jq
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  jq --arg suite "$suite_path" \
     --arg level "$new_level" \
     --argjson has_impl "$([ "$has_implementation" = "true" ] && echo true || echo false)" \
     --argjson passing "$passing_runs" \
     --arg timestamp "$timestamp" \
     --argjson patterns "$pattern_types" \
     --arg override "$manual_override" \
     '.suites[$suite] = {
       maturity_level: $level,
       detected_signals: {
         has_implementation: $has_impl,
         passing_runs: $passing,
         last_modified: $timestamp,
         pattern_types: $patterns
       },
       manual_override: (if $override != "" then $override else null end),
       last_transition: $timestamp
     }' "$maturity_file" > "$maturity_file.tmp"

  mv "$maturity_file.tmp" "$maturity_file"
}

# Get pattern types from expected.json files
function get_pattern_types() {
  local suite_path="$1"
  local patterns=()

  if [ -d "$suite_path/data" ]; then
    while IFS= read -r expected_file; do
      # Extract unique patterns
      while IFS= read -r pattern; do
        patterns+=("\"$pattern\"")
      done < <(grep -o '<[a-z_]*>' "$expected_file" 2>/dev/null | sort -u || true)
    done < <(find "$suite_path/data" -name "expected.json" 2>/dev/null || true)
  fi

  # Return as JSON array
  if [ ${#patterns[@]} -eq 0 ]; then
    echo "[]"
  else
    echo "[$(IFS=, ; echo "${patterns[*]}")]"
  fi
}

# Analyze and report on a single test suite
function analyze_suite() {
  local suite_path="$1"

  log_verbose "Analyzing: $suite_path"

  # Get current maturity level
  local current_level
  current_level=$(get_current_maturity "$suite_path")

  # Detect signals
  local signals
  signals=$(detect_maturity_signals "$suite_path")

  IFS='|' read -r has_implementation passing_runs pattern_count <<< "$signals"

  # Suggest new level (unless manually overridden)
  local suggested_level
  if [ -n "$MATURITY_LEVEL" ]; then
    suggested_level="$MATURITY_LEVEL"
  else
    suggested_level=$(suggest_maturity_level "$current_level" "$has_implementation" "$passing_runs" "$pattern_count")
  fi

  # Report findings
  echo ""
  echo "Suite: $suite_path"
  echo "  Current Level: $current_level"
  echo "  Detected Signals:"

  if [ "$has_implementation" = "true" ]; then
    echo "    ✓ Implementation detected (run script modified)"
  else
    echo "    ✗ No implementation (run script unchanged)"
  fi

  echo "    • Passing runs: $passing_runs"
  echo "    • Pattern count: $pattern_count"

  if [ "$suggested_level" != "$current_level" ]; then
    echo ""
    echo "  Suggested Level: $suggested_level (transition: $current_level → $suggested_level)"

    if [ "$APPLY_CHANGES" = "true" ] && [ "$DRY_RUN" = "false" ]; then
      # Apply the transition
      local manual_flag=""
      if [ -n "$MATURITY_LEVEL" ]; then
        manual_flag="$MATURITY_LEVEL"
      fi

      update_maturity "$suite_path" "$suggested_level" "$has_implementation" "$passing_runs" "$pattern_count" "$manual_flag"
      echo "  ✓ Maturity level updated: $current_level → $suggested_level"
    fi
  else
    echo "  Suggested Level: $suggested_level (no change)"
  fi

  # Return 1 if transition suggested, 0 otherwise
  if [ "$suggested_level" != "$current_level" ]; then
    return 1
  else
    return 0
  fi
}

# Main execution
function main() {
  parse_options "$@"
  validate_maturity_level "$MATURITY_LEVEL"

  # Determine which suites to analyze
  local suites=()
  if [ -n "$SUITE_PATH" ]; then
    if [ ! -d "$SUITE_PATH" ]; then
      log_error "Suite not found: $SUITE_PATH"
      exit 1
    fi
    suites=("$SUITE_PATH")
  else
    # Find all test suites
    local feature_dir
    feature_dir=$(detect_feature_dir) || exit 1
    local test_base="tc/tests/$(basename "$feature_dir")"

    if [ ! -d "$test_base" ]; then
      log_error "No tests found for feature (run /tc.specify first)"
      exit 1
    fi

    while IFS= read -r suite; do
      suites+=("$suite")
    done < <(find_test_suites "$test_base")
  fi

  if [ ${#suites[@]} -eq 0 ]; then
    log_error "No test suites found"
    exit 1
  fi

  echo "🔍 Analyzing test maturity signals..."

  local analyzed=0
  local transitions=0

  # Analyze each suite
  for suite in "${suites[@]}"; do
    if ! analyze_suite "$suite"; then
      ((transitions++)) || true
    fi
    ((analyzed++)) || true
  done

  # Report summary
  echo ""
  echo "Summary:"
  echo "  Tests analyzed: $analyzed"
  echo "  Transitions suggested: $transitions"

  if [ "$APPLY_CHANGES" = "true" ] && [ "$DRY_RUN" = "false" ]; then
    echo "  Changes applied: ✓"
    log_success "Updated maturity tracking: tc/spec-kit/maturity.json"
  elif [ "$DRY_RUN" = "true" ]; then
    echo "  Changes applied: ✗ (dry-run mode)"
  else
    echo "  Changes applied: ✗ (use --apply to apply changes)"
    echo ""
    echo "Next steps:"
    echo "  Apply refinements: tc-kit-refine.sh --apply"
  fi
}

main "$@"
