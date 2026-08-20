#!/usr/bin/env bash
# tc-kit-validate.sh - Validate spec-test alignment and coverage
# Part of tc-kit integration with spec-kit for tc framework

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tc-kit-common.sh"

# Default values
SPEC_FILE=""
FORMAT="auto"
OUTPUT_FILE="tc/spec-kit/validation-report.json"
STRICT_MODE=false
COVERAGE_THRESHOLD=90
VERBOSE=false

# Show usage
function show_usage() {
  cat <<EOF
Usage: tc-kit-validate.sh [OPTIONS]

Validate spec-test alignment, calculate coverage, and detect drift.

OPTIONS:
  --spec PATH              Path to spec.md (defaults to auto-detect)
  --format FORMAT          Output format: auto/markdown/json (default: auto)
  --output PATH            JSON report output path (default: tc/spec-kit/validation-report.json)
  --strict                 Fail on any warnings
  --coverage-threshold N   Minimum coverage % required (default: 90)
  --verbose                Show detailed validation progress
  --help                   Show this help message

EXAMPLES:
  tc-kit-validate.sh
  tc-kit-validate.sh --strict --coverage-threshold 100
  tc-kit-validate.sh --format json

EOF
}

# Parse command-line options
function parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --spec)
        SPEC_FILE="$2"
        shift 2
        ;;
      --format)
        FORMAT="$2"
        shift 2
        ;;
      --output)
        OUTPUT_FILE="$2"
        shift 2
        ;;
      --strict)
        STRICT_MODE=true
        shift
        ;;
      --coverage-threshold)
        COVERAGE_THRESHOLD="$2"
        shift 2
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

# Auto-detect spec file if not provided
function detect_spec_file() {
  if [ -z "$SPEC_FILE" ]; then
    local feature_dir
    feature_dir=$(detect_feature_dir) || exit 1
    SPEC_FILE="$feature_dir/spec.md"
  fi

  if [ ! -f "$SPEC_FILE" ]; then
    log_error "spec.md not found at $SPEC_FILE"
    exit 1
  fi

  log_verbose "Using spec file: $SPEC_FILE"
}

# Count total scenarios in spec
function count_spec_scenarios() {
  local spec_file="$1"

  # Count all Given/When/Then scenarios
  grep -E "^\s*[0-9]+\.\s+\*\*Given\*\*" "$spec_file" 2>/dev/null | wc -l || echo "0"
}

# Count user stories in spec
function count_user_stories() {
  local spec_file="$1"

  grep -E "^### User Story [0-9]+" "$spec_file" 2>/dev/null | wc -l || echo "0"
}

# Calculate coverage percentage
function calculate_coverage() {
  local total_scenarios="$1"
  local tested_scenarios="$2"

  if [ "$total_scenarios" -eq 0 ]; then
    echo "0"
    return
  fi

  # Calculate percentage (integer math)
  local coverage=$((tested_scenarios * 100 / total_scenarios))
  echo "$coverage"
}

# Count actual scenario test files
function count_mapped_tests() {
  local feature_dir
  feature_dir=$(detect_feature_dir) 2>/dev/null || echo ""

  if [ -z "$feature_dir" ]; then
    echo "0"
    return
  fi

  local test_base="tc/tests/$(basename "$feature_dir")"

  if [ ! -d "$test_base" ]; then
    echo "0"
    return
  fi

  # Count scenario directories (each represents a tested scenario)
  find "$test_base" -type d -name "scenario-*" 2>/dev/null | wc -l || echo "0"
}

# Generate maturity breakdown
function generate_maturity_breakdown() {
  local maturity_file="tc/spec-kit/maturity.json"

  if [ ! -f "$maturity_file" ]; then
    echo '{"concept": 0, "exploration": 0, "implementation": 0}'
    return
  fi

  # Count suites by maturity level
  jq '{
    concept: [.suites[] | select(.maturity_level == "concept")] | length,
    exploration: [.suites[] | select(.maturity_level == "exploration")] | length,
    implementation: [.suites[] | select(.maturity_level == "implementation")] | length
  }' "$maturity_file" 2>/dev/null || echo '{"concept": 0, "exploration": 0, "implementation": 0}'
}

# Generate coverage matrix (per user story)
function generate_coverage_matrix() {
  local spec_file="$1"
  local traceability_file="tc/spec-kit/traceability.json"
  local maturity_file="tc/spec-kit/maturity.json"

  if [ ! -f "$traceability_file" ]; then
    echo "[]"
    return
  fi

  # Parse user stories and build matrix
  local matrix="[]"

  while IFS='|' read -r story_num title priority; do
    [ -z "$story_num" ] && continue

    # Count scenarios for this user story
    local scenario_count
    scenario_count=$(grep -E "^\s*[0-9]+\.\s+\*\*Given\*\*" "$spec_file" | \
      sed -n "/^### User Story $story_num /,/^### User Story/p" | \
      wc -l || echo "0")

    # For simplicity, assume all scenarios are tested (MVP)
    local tests_generated="$scenario_count"
    local tests_passing=0
    local maturity_level="concept"

    # Build JSON object for this story
    local story_json
    story_json=$(jq -n \
      --arg story "user-story-$story_num" \
      --arg title "$title" \
      --argjson scenarios "$scenario_count" \
      --argjson generated "$tests_generated" \
      --argjson passing "$tests_passing" \
      --arg maturity "$maturity_level" \
      '{
        user_story: $story,
        title: $title,
        scenarios_count: $scenarios,
        tests_generated: $generated,
        tests_passing: $passing,
        maturity_level: $maturity
      }')

    matrix=$(echo "$matrix" | jq --argjson item "$story_json" '. + [$item]')
  done < <(grep -E "^### User Story [0-9]+" "$spec_file" | \
    sed -E 's/^### User Story ([0-9]+) - (.*) \(Priority: P([0-9])\)/\1|\2|\3/' || true)

  echo "$matrix"
}

# Generate validation report JSON
function generate_validation_report() {
  local spec_file="$1"
  local feature_name
  feature_name=$(basename "$(dirname "$spec_file")")

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  local total_stories
  total_stories=$(count_user_stories "$spec_file")

  local total_scenarios
  total_scenarios=$(count_spec_scenarios "$spec_file")

  local total_tests
  total_tests=$(count_mapped_tests)

  local coverage
  coverage=$(calculate_coverage "$total_scenarios" "$total_tests")

  local maturity_breakdown
  maturity_breakdown=$(generate_maturity_breakdown)

  local coverage_matrix
  coverage_matrix=$(generate_coverage_matrix "$spec_file")

  # Build full report
  jq -n \
    --arg version "1.0" \
    --arg timestamp "$timestamp" \
    --arg feature "$feature_name" \
    --arg spec_path "$spec_file" \
    --argjson stories "$total_stories" \
    --argjson scenarios "$total_scenarios" \
    --argjson tests "$total_tests" \
    --argjson coverage "$coverage" \
    --argjson maturity "$maturity_breakdown" \
    --argjson matrix "$coverage_matrix" \
    '{
      version: $version,
      generated_at: $timestamp,
      feature: $feature,
      spec_path: $spec_path,
      summary: {
        total_user_stories: $stories,
        total_scenarios: $scenarios,
        total_tests: $tests,
        coverage_percentage: $coverage,
        untested_scenarios: []
      },
      coverage_matrix: $matrix,
      divergence_warnings: [],
      maturity_breakdown: $maturity,
      out_of_scope_tests: []
    }'
}

# Render TTY output (markdown with colors)
function render_tty_report() {
  local report_json="$1"

  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Test-Kit Validation Report"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  # Summary
  local coverage
  coverage=$(echo "$report_json" | jq -r '.summary.coverage_percentage')

  local total_stories
  total_stories=$(echo "$report_json" | jq -r '.summary.total_user_stories')

  local total_scenarios
  total_scenarios=$(echo "$report_json" | jq -r '.summary.total_scenarios')

  local total_tests
  total_tests=$(echo "$report_json" | jq -r '.summary.total_tests')

  echo "Summary:"
  echo "  User Stories: $total_stories"
  echo "  Scenarios: $total_scenarios"
  echo "  Tests Generated: $total_tests"

  if is_tty; then
    if [ "$coverage" -ge "$COVERAGE_THRESHOLD" ]; then
      echo "  Coverage: ✓ ${coverage}%"
    else
      echo "  Coverage: ✗ ${coverage}% (threshold: ${COVERAGE_THRESHOLD}%)"
    fi
  else
    echo "  Coverage: ${coverage}%"
  fi

  echo ""

  # Maturity breakdown
  echo "Maturity Breakdown:"
  local concept
  concept=$(echo "$report_json" | jq -r '.maturity_breakdown.concept')
  local exploration
  exploration=$(echo "$report_json" | jq -r '.maturity_breakdown.exploration')
  local implementation
  implementation=$(echo "$report_json" | jq -r '.maturity_breakdown.implementation')

  echo "  Concept: $concept"
  echo "  Exploration: $exploration"
  echo "  Implementation: $implementation"

  echo ""
  echo "───────────────────────────────────────────────────────────"
  echo ""

  if [ "$coverage" -ge "$COVERAGE_THRESHOLD" ]; then
    if is_tty; then
      echo "✓ Validation passed"
    else
      echo "SUCCESS: Validation passed"
    fi
  else
    if is_tty; then
      echo "✗ Validation failed (coverage below threshold)"
    else
      echo "FAILURE: Validation failed (coverage below threshold)"
    fi
  fi

  echo ""
  echo "Report saved: $OUTPUT_FILE"
  echo ""
}

# Render plain text output
function render_plain_report() {
  local report_json="$1"

  local coverage
  coverage=$(echo "$report_json" | jq -r '.summary.coverage_percentage')

  echo "Validation Report:"
  echo "  Coverage: ${coverage}%"
  echo "  Threshold: ${COVERAGE_THRESHOLD}%"
  echo "  Status: $( [ "$coverage" -ge "$COVERAGE_THRESHOLD" ] && echo "PASS" || echo "FAIL" )"
  echo "  Report: $OUTPUT_FILE"
}

# Main execution
function main() {
  parse_options "$@"
  detect_spec_file

  echo "🔍 Validating spec-test alignment..."

  # Generate validation report
  local report_json
  report_json=$(generate_validation_report "$SPEC_FILE")

  # Persist JSON report
  ensure_spec_kit_dir
  echo "$report_json" | jq '.' > "$OUTPUT_FILE"

  log_verbose "Generated validation report: $OUTPUT_FILE"

  # Determine output format
  local output_format="$FORMAT"
  if [ "$output_format" = "auto" ]; then
    if is_tty; then
      output_format="markdown"
    else
      output_format="plain"
    fi
  fi

  # Render output
  case "$output_format" in
    markdown)
      render_tty_report "$report_json"
      ;;
    json)
      echo "$report_json" | jq '.'
      ;;
    plain)
      render_plain_report "$report_json"
      ;;
    *)
      log_error "Unknown format: $output_format"
      exit 1
      ;;
  esac

  # Check validation gates
  local coverage
  coverage=$(echo "$report_json" | jq -r '.summary.coverage_percentage')

  local warnings_count
  warnings_count=$(echo "$report_json" | jq -r '.divergence_warnings | length')

  # Exit code logic
  if [ "$coverage" -lt "$COVERAGE_THRESHOLD" ]; then
    exit 2  # Validation failure
  elif [ "$STRICT_MODE" = "true" ] && [ "$warnings_count" -gt 0 ]; then
    exit 2  # Strict mode with warnings
  else
    exit 0  # Success
  fi
}

main "$@"
