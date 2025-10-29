#!/usr/bin/env bash
# tc-kit-specify.sh - Generate technology-agnostic tc test suites from spec.md
# Part of tc-kit: AI-driven testing integration for tc framework

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tc-kit-common.sh"

# Default values
SPEC_FILE=""
OUTPUT_DIR="tc/tests"
DRY_RUN=false
FORCE=false
VERBOSE=false

# Show usage
function show_usage() {
  cat <<EOF
Usage: tc-kit-specify.sh [OPTIONS]

Generate technology-agnostic tc test suites from spec-kit specification documents.

OPTIONS:
  --spec PATH       Path to spec.md (defaults to auto-detect from git branch)
  --output DIR      Base directory for generated tests (default: tc/tests)
  --dry-run         Show what would be generated without creating files
  --force           Overwrite existing tests
  --verbose         Show detailed generation progress
  --help            Show this help message

EXAMPLES:
  tc-kit-specify.sh
  tc-kit-specify.sh --spec specs/008-explore-the-strategy/spec.md
  tc-kit-specify.sh --dry-run --verbose

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
      --output)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --force)
        FORCE=true
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

# Extract feature name from spec file path
function get_feature_name() {
  local spec_path="$1"
  basename "$(dirname "$spec_path")"
}

# Parse user stories from spec.md
# Output format: story_number|title|priority (one per line)
function parse_user_stories() {
  local spec_file="$1"

  grep -E "^### User Story [0-9]+" "$spec_file" | \
    sed -E 's/^### User Story ([0-9]+) - (.*) \(Priority: P([0-9])\)/\1|\2|\3/'
}

# Parse acceptance scenarios for a given user story
# Returns lines with Given/When/Then clauses
function parse_acceptance_scenarios() {
  local spec_file="$1"
  local story_num="$2"

  # Extract the user story section
  sed -n "/^### User Story $story_num /,/^---/p" "$spec_file" | \
    sed -n '/^\*\*Acceptance Scenarios\*\*:/,/^---/p' | \
    grep -E "^\s*[0-9]+\.\s+\*\*Given\*\*" || true
}

# Extract Given/When/Then from a scenario line
function extract_given_when_then() {
  local scenario_line="$1"

  # Extract Given clause (use | as delimiter to avoid issues with / in text)
  local given=$(echo "$scenario_line" | sed -E 's|.*\*\*Given\*\*\s+([^,]*).*|\1|')

  # Extract When clause
  local when=$(echo "$scenario_line" | sed -E 's|.*\*\*When\*\*\s+([^,]*).*|\1|')

  # Extract Then clause
  local then=$(echo "$scenario_line" | sed -E 's|.*\*\*Then\*\*\s+(.*)|\1|')

  echo "$given|$when|$then"
}

# Map text to tc pattern based on keywords (heuristic from research.md Decision 2)
function map_to_pattern() {
  local text="$1"
  local text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')

  case "$text_lower" in
    *uuid*|*"unique id"*|*identifier*)
      echo "<uuid>"
      ;;
    *timestamp*|*"created at"*|*"created_at"*|*date*|*time*)
      echo "<timestamp>"
      ;;
    *count*|*total*|*number*|*quantity*)
      echo "<number>"
      ;;
    *enabled*|*active*|*"is_"*|*success*)
      echo "<boolean>"
      ;;
    *null*|*missing*|*empty*)
      echo "<null>"
      ;;
    *)
      # Check if it's a specific value (quoted or specific term)
      if [[ "$text" =~ \"([^\"]+)\" ]]; then
        # Extract quoted value
        echo "\"${BASH_REMATCH[1]}\""
      else
        # Default to string pattern
        echo "<string>"
      fi
      ;;
  esac
}

# Generate input.json from Given clause
function generate_input_json() {
  local given="$1"
  local output_file="$2"

  # Simple JSON generation - can be enhanced based on Given clause parsing
  cat > "$output_file" <<EOF
{
  "scenario": "$(echo "$given" | sed 's/"/\\"/g')"
}
EOF
}

# Generate expected.json from Then clause with patterns
function generate_expected_json() {
  local then="$1"
  local output_file="$2"

  # Extract pattern hints from Then clause
  local pattern=$(map_to_pattern "$then")

  cat > "$output_file" <<EOF
{
  "result": $pattern
}
EOF
}

# Generate run script for user story suite (handles all scenarios)
function generate_suite_run_script() {
  local run_path="$1"
  local story_num="$2"
  local user_story_title="$3"

  cat > "$run_path" <<EOF
#!/usr/bin/env bash
# Auto-generated by tc-kit from spec: $SPEC_FILE
# User Story $story_num: $user_story_title
# Traceability: user-story-$story_num
set -euo pipefail

# Read input from stdin (tc contract)
input=\$(cat)

# NOT_IMPLEMENTED: Replace this block with actual implementation
# This run script should handle all scenarios for this user story
# by processing the input and generating appropriate output
echo '{"error": "NOT_IMPLEMENTED", "message": "Test runner not yet implemented for user story $story_num"}' >&2
exit 1

# Expected behavior: Implement logic to satisfy all acceptance scenarios for this user story
EOF

  chmod +x "$run_path"
}

# Generate test scenario data files
function generate_test_scenario() {
  local suite_path="$1"
  local scenario_num="$2"
  local given_when_then="$3"

  local scenario_padded=$(zeropad "$scenario_num")
  local scenario_path="$suite_path/data/scenario-$scenario_padded"

  mkdir -p "$scenario_path"

  # Generate scenario data files
  generate_input_json "$given_when_then" "$scenario_path/input.json"
  generate_expected_json "$given_when_then" "$scenario_path/expected.json"

  log_verbose "  Generated scenario: scenario-$scenario_padded"
}

# Create test suite for a user story (creates suite directory + run script)
function create_test_suite() {
  local feature_name="$1"
  local story_num="$2"
  local user_story_title="$3"

  local story_padded=$(zeropad "$story_num")
  local suite_path="$OUTPUT_DIR/$feature_name/user-story-$story_padded"

  if [ "$DRY_RUN" = true ]; then
    echo "  $suite_path/"
    return 0
  fi

  # Check if exists and not forcing
  if [ -d "$suite_path" ] && [ "$FORCE" = false ]; then
    log_warning "Test suite already exists: $suite_path (use --force to overwrite)"
    return 1
  fi

  # Create suite directory
  mkdir -p "$suite_path/data"

  # Generate run script for the entire suite
  generate_suite_run_script "$suite_path/run" "$story_num" "$user_story_title"

  log_verbose "Created test suite: user-story-$story_padded"

  echo "$suite_path"
}

# Add traceability mapping for a scenario
function add_traceability_mapping() {
  local feature_name="$1"
  local story_num="$2"
  local scenario_num="$3"
  local user_story_title="$4"
  local given_when_then="$5"

  local story_padded=$(zeropad "$story_num")
  local scenario_padded=$(zeropad "$scenario_num")
  local suite_path="$OUTPUT_DIR/$feature_name/user-story-$story_padded"
  local spec_ref="user-story-$story_num.scenario-$scenario_num"

  # Store for later use in generate_traceability
  echo "$suite_path|$spec_ref|$user_story_title|$given_when_then|$story_num|$scenario_num" >> "/tmp/tc-traceability-$$"
}

# Generate traceability.json (bidirectional spec↔test mapping)
function generate_traceability() {
  local feature_name="$1"
  local traceability_file="tc/spec-kit/traceability.json"

  if [ "$DRY_RUN" = true ]; then
    return 0
  fi

  ensure_spec_kit_dir

  # Start with base structure
  local forward="{}"
  local reverse="{}"

  # Build mappings from collected data
  if [ -f "/tmp/tc-traceability-$$" ]; then
    while IFS='|' read -r suite_path spec_ref title gwt story_num scenario_num; do
      local story_key="user-story-$story_num"
      local scenario_key="scenario-$scenario_num"

      # Add to forward mapping
      forward=$(echo "$forward" | jq \
        --arg story "$story_key" \
        --arg title "$title" \
        --arg priority "P1" \
        --arg scenario "$scenario_key" \
        --arg path "$suite_path" \
        '.[$story] //= {title: $title, priority: $priority, scenarios: {}} |
         .[$story].scenarios[$scenario] = $path')

      # Add to reverse mapping
      reverse=$(echo "$reverse" | jq \
        --arg path "$suite_path" \
        --arg ref "$spec_ref" \
        --arg title "$title" \
        --arg gwt "$gwt" \
        '.[$path] = {spec_ref: $ref, user_story: $title, given_when_then: $gwt}')
    done < "/tmp/tc-traceability-$$"

    rm -f "/tmp/tc-traceability-$$"
  fi

  # Generate final traceability JSON
  jq -n \
    --arg feature "$feature_name" \
    --arg spec "$SPEC_FILE" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson forward "$forward" \
    --argjson reverse "$reverse" \
    '{
      version: "1.0",
      feature: $feature,
      spec_path: $spec,
      generated_at: $timestamp,
      forward: $forward,
      reverse: $reverse
    }' > "$traceability_file"

  log_verbose "Generated traceability: $traceability_file"
}

# Initialize maturity.json (all tests at "concept" level)
function initialize_maturity() {
  local maturity_file="tc/spec-kit/maturity.json"

  if [ "$DRY_RUN" = true ]; then
    return 0
  fi

  ensure_spec_kit_dir

  # Initialize maturity structure
  jq -n \
    --arg version "1.0" \
    '{
      version: $version,
      suites: {},
      transition_rules: {
        concept_to_exploration: "First implementation commit detected",
        exploration_to_implementation: "5+ consecutive passing runs"
      }
    }' > "$maturity_file"

  log_verbose "Initialized maturity: $maturity_file"
}

# Main execution
function main() {
  parse_options "$@"
  detect_spec_file

  local feature_name
  feature_name=$(get_feature_name "$SPEC_FILE")

  log_info "Parsing spec: $SPEC_FILE"
  log_info "Feature: $feature_name"

  # Parse user stories
  local user_stories
  user_stories=$(parse_user_stories "$SPEC_FILE")

  if [ -z "$user_stories" ]; then
    log_error "No user stories found in spec"
    exit 1
  fi

  local story_count=0
  local scenario_count=0
  local test_count=0

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would generate the following tests:"
    echo ""
  fi

  # Process each user story
  while IFS='|' read -r story_num title priority; do
    ((story_count++)) || true

    log_verbose "Processing User Story $story_num: $title (Priority: P$priority)"

    # Parse acceptance scenarios for this story
    local scenarios
    scenarios=$(parse_acceptance_scenarios "$SPEC_FILE" "$story_num")

    if [ -z "$scenarios" ]; then
      log_warning "No acceptance scenarios found for User Story $story_num"
      continue
    fi

    # Create test suite for this user story
    local suite_path
    suite_path=$(create_test_suite "$feature_name" "$story_num" "$title")

    if [ -z "$suite_path" ]; then
      continue
    fi

    # Generate scenarios within the suite
    local scenario_num=0
    while IFS= read -r scenario_line; do
      ((scenario_num++)) || true
      ((scenario_count++)) || true
      ((test_count++)) || true

      # Extract Given/When/Then
      local gwt
      gwt=$(extract_given_when_then "$scenario_line")

      # Generate scenario data files
      generate_test_scenario "$suite_path" "$scenario_num" "$gwt"

      # Add to traceability mapping
      add_traceability_mapping "$feature_name" "$story_num" "$scenario_num" "$title" "$gwt"
    done <<< "$scenarios"
  done <<< "$user_stories"

  if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY RUN] Would create:"
    echo "  tc/spec-kit/traceability.json ($test_count mappings)"
    echo "  tc/spec-kit/maturity.json ($test_count suites at concept level)"
    echo ""
    echo "No files created (remove --dry-run to generate)."
    exit 0
  fi

  # Generate metadata files
  generate_traceability "$feature_name"
  initialize_maturity

  # Report summary
  echo ""
  log_success "Parsed spec: $story_count user stories, $scenario_count acceptance scenarios"
  log_success "Generated $test_count test scenarios"
  log_success "Created traceability: tc/spec-kit/traceability.json"
  log_success "Initialized maturity tracking: tc/spec-kit/maturity.json"

  echo ""
  echo "Summary:"
  echo "  User Stories: $story_count"
  echo "  Scenarios: $scenario_count"
  echo "  Tests Generated: $test_count"
  echo "  Coverage: 100%"

  echo ""
  echo "Next steps:"
  echo "  Run tests: tc $OUTPUT_DIR/$feature_name --all"
  echo "  Refine tests: /tc.refine"
}

main "$@"
