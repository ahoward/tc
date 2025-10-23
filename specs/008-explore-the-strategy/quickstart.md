# Test-Kit Quickstart: Developer Guide

**Feature**: Test-Kit Integration with Spec-Kit
**For**: Developers implementing tc-kit slash commands
**Last Updated**: 2025-10-18

## Overview

Test-kit is a slash command companion to spec-kit that generates, refines, and validates language-agnostic acceptance tests from specifications. This guide walks you through implementing the three core commands.

---

## Prerequisites

Before implementing tc-kit, ensure you have:

1. **tc framework** - Existing test runner with pattern matching
2. **spec-kit** - Specification-driven development toolchain
3. **jq** - JSON processing (`brew install jq` or `apt-get install jq`)
4. **Bash 4.0+** - POSIX-compatible shell
5. **Git** (optional) - For commit detection and maturity signals

**Verify Prerequisites**:
```bash
# Check tc framework
tc --version  # Should show: tc v1.0.0 - island hopper

# Check jq
jq --version  # Should show: jq-1.6 or later

# Check bash
bash --version  # Should show: 4.0 or later

# Check spec-kit structure
ls .specify/templates/commands/  # Should show spec-kit slash commands
```

---

## Quick Start: 3-Step Workflow

### Step 1: Generate Tests from Spec

```bash
# From repository root
/tc.specify

# Output:
# ✓ Generated 9 test scenarios
# ✓ Created traceability: tc/spec-kit/traceability.json
# Summary: 3 user stories, 9 scenarios, 100% coverage
```

**What This Does**:
- Parses `spec.md` to extract user stories and acceptance scenarios
- Generates tc test suites in `tc/tests/{feature}/user-story-NN/scenario-NN/`
- Creates `run` scripts (NOT_IMPLEMENTED), `input.json`, `expected.json`
- Builds bidirectional traceability in `tc/spec-kit/traceability.json`
- Initializes maturity tracking in `tc/spec-kit/maturity.json` (all at "concept" level)

### Step 2: Implement and Refine Tests

```bash
# Implement run scripts (manually edit generated files)
vim tc/tests/008-explore-the-strategy/user-story-01/scenario-01/run

# Run tests to verify
tc tc/tests/008-explore-the-strategy --all

# Check for refinement suggestions
/tc.refine --suggest

# Output:
# Suite: .../scenario-01
#   Current: concept
#   Suggested: exploration (implementation detected, 3 passing runs)
#   Refinements: Consider concrete UUID instead of <uuid>
```

**What This Does**:
- Detects maturity level signals (implementation commits, passing runs)
- Suggests transitions (concept→exploration, exploration→implementation)
- Offers refinement opportunities (patterns→concrete values)
- Preserves original tests as baselines when applying refinements

### Step 3: Validate Spec-Test Alignment

```bash
# Validate coverage and detect drift
/tc.validate

# Output:
# 📊 Coverage: 100.0% ✅ (9/9 scenarios)
# 📈 Maturity: 6 concept, 3 exploration, 0 implementation
# ✅ Validation Status: PASS
# Report saved to: tc/spec-kit/validation-report.json
```

**What This Does**:
- Calculates test coverage (% of spec scenarios with tests)
- Detects spec-test divergence (refined tests with unchanged specs)
- Identifies out-of-scope tests (tests not mapped to spec)
- Generates coverage matrix showing which specs are tested
- Outputs TTY-friendly markdown or machine-readable JSON

---

## Implementation Guide

### Phase 1: Implement `/tc.specify`

**File**: `.specify/scripts/bash/tc-kit-specify.sh`

**Core Functions** (from research.md):

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Parse spec.md to extract user stories
function parse_user_stories() {
  local spec_file="$1"
  grep -E "^### User Story [0-9]+" "$spec_file" | \
    sed 's/### User Story \([0-9]\+\) - \(.*\) (Priority: P\([0-9]\))/\1|\2|\3/'
}

# 2. Parse acceptance scenarios (Given/When/Then)
function parse_acceptance_scenarios() {
  local spec_file="$1"
  local user_story_num="$2"

  sed -n '/^### User Story '"$user_story_num"'/,/^---/p' "$spec_file" | \
    sed -n '/^\*\*Acceptance Scenarios\*\*/,/^---/p' | \
    grep -E "^\s*[0-9]+\.\s+\*\*Given\*\*" -A 2
}

# 3. Map acceptance criteria to tc patterns (heuristic)
function map_to_pattern() {
  local text="$1"

  case "$text" in
    *uuid*|*unique*id*|*identifier*) echo "<uuid>" ;;
    *timestamp*|*created*|*date*|*time*) echo "<timestamp>" ;;
    *count*|*total*|*number*|*quantity*) echo "<number>" ;;
    *enabled*|*active*|*is_*|*success*) echo "<boolean>" ;;
    *null*|*missing*|*empty*) echo "<null>" ;;
    *) echo "<string>" ;;  # Default: most permissive
  esac
}

# 4. Generate test directory structure
function generate_test_suite() {
  local feature_name="$1"
  local user_story_num="$2"
  local scenario_num="$3"
  local suite_path="tc/tests/$feature_name/user-story-$(printf '%02d' "$user_story_num")/scenario-$(printf '%02d' "$scenario_num")"

  mkdir -p "$suite_path/data"
  generate_run_script "$suite_path/run" "$user_story_num" "$scenario_num"
  generate_input_json "$suite_path/data/input.json" "$given_clause"
  generate_expected_json "$suite_path/data/expected.json" "$then_clause"
  chmod +x "$suite_path/run"
}

# 5. Generate NOT_IMPLEMENTED run script template
function generate_run_script() {
  local run_path="$1"
  local story_num="$2"
  local scenario_num="$3"

  cat > "$run_path" <<'EOF'
#!/usr/bin/env bash
# Auto-generated by tc-kit from spec: specs/008-explore-the-strategy/spec.md
# User Story: {user_story_title}
# Scenario: {scenario_num}
# Traceability: user-story-{story_num}.scenario-{scenario_num}

set -euo pipefail

input=$(cat)

echo '{"error": "NOT_IMPLEMENTED", "message": "Test runner not yet implemented"}' >&2
exit 1

# Expected behavior (from spec):
# {given_when_then_text}
EOF
}

# 6. Generate traceability.json (bidirectional mapping)
function generate_traceability() {
  local feature_name="$1"
  local spec_path="$2"

  jq -n \
    --arg feature "$feature_name" \
    --arg spec "$spec_path" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      version: "1.0",
      feature: $feature,
      spec_path: $spec,
      generated_at: $timestamp,
      forward: {},
      reverse: {}
    }' > tc/spec-kit/traceability.json

  # Populate forward and reverse maps in loop (pseudocode)
  # for each user_story:
  #   forward[user-story-N] = { scenarios: { scenario-1: path, ... }}
  # for each test:
  #   reverse[test_path] = { spec_ref: "user-story-N.scenario-M", ... }
}

# Main execution flow
main() {
  # 1. Auto-detect feature directory
  # 2. Parse spec.md
  # 3. For each user story:
  #      For each scenario:
  #        Generate test suite
  # 4. Generate traceability.json
  # 5. Generate maturity.json (all at "concept" level)
  # 6. Report summary
}

main "$@"
```

**Contract Reference**: See [`contracts/tc-kit-specify.md`](contracts/tc-kit-specify.md)

---

### Phase 2: Implement `/tc.refine`

**File**: `.specify/scripts/bash/tc-kit-refine.sh`

**Core Functions**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Detect maturity signals
function detect_maturity_signals() {
  local suite_path="$1"
  local run_script="$suite_path/run"

  # Check if run script modified beyond template
  local has_implementation=false
  if ! grep -q "NOT_IMPLEMENTED" "$run_script"; then
    has_implementation=true
  fi

  # Count consecutive passing runs (from tc execution logs)
  local passing_runs=0
  if [ -f "tc/tmp/report.jsonl" ]; then
    passing_runs=$(jq -r \
      --arg suite "$suite_path" \
      'select(.suite == $suite and .status == "pass") | .timestamp' \
      tc/tmp/report.jsonl | wc -l)
  fi

  # Analyze pattern types in expected.json
  local pattern_types=()
  if [ -f "$suite_path/data/expected.json" ]; then
    pattern_types=($(jq -r '.. | strings | select(startswith("<") and endswith(">"))' "$suite_path/data/expected.json"))
  fi

  echo "$has_implementation|$passing_runs|${pattern_types[*]}"
}

# 2. Suggest maturity level based on signals
function suggest_maturity_level() {
  local has_implementation="$1"
  local passing_runs="$2"
  local current_level="$3"

  # Concept → Exploration: implementation detected
  if [ "$current_level" == "concept" ] && [ "$has_implementation" == "true" ]; then
    echo "exploration"
    return
  fi

  # Exploration → Implementation: 5+ passing runs
  if [ "$current_level" == "exploration" ] && [ "$passing_runs" -ge 5 ]; then
    echo "implementation"
    return
  fi

  echo "$current_level"  # No change
}

# 3. Preserve baseline when refining
function preserve_baseline() {
  local suite_path="$1"
  local current_level="$2"
  local baseline_path="${suite_path}-${current_level}-baseline"

  if [ -d "$suite_path" ]; then
    cp -r "$suite_path" "$baseline_path"
    echo "✓ Backed up original test: $(basename "$baseline_path")/"
  fi
}

# 4. Apply refinements to expected.json
function apply_refinements() {
  local expected_json="$1"
  local refinements="$2"  # JSON array of { path: "$.field", value: "new_value" }

  echo "$refinements" | jq -r '.[] | "\(.path)=\(.value)"' | while IFS='=' read -r json_path new_value; do
    jq --arg path "$json_path" --arg value "$new_value" \
      'setpath($path | split("."); $value)' \
      "$expected_json" > "$expected_json.tmp"
    mv "$expected_json.tmp" "$expected_json"
  done
}

# 5. Update maturity.json
function update_maturity() {
  local suite_path="$1"
  local new_level="$2"
  local signals="$3"  # JSON object

  jq --arg suite "$suite_path" \
     --arg level "$new_level" \
     --argjson signals "$signals" \
    '.suites[$suite].maturity_level = $level |
     .suites[$suite].detected_signals = $signals |
     .suites[$suite].last_transition = now | strftime("%Y-%m-%dT%H:%M:%SZ")' \
    tc/spec-kit/maturity.json > tc/spec-kit/maturity.json.tmp
  mv tc/spec-kit/maturity.json.tmp tc/spec-kit/maturity.json
}

# Main execution flow
main() {
  # 1. Load maturity.json and traceability.json
  # 2. For each test suite:
  #      Detect maturity signals
  #      Suggest maturity level
  #      If --apply and level changed:
  #        Preserve baseline
  #        Apply refinements
  #        Update maturity.json
  # 3. Report summary (tests analyzed, refinements suggested/applied)
}

main "$@"
```

**Contract Reference**: See [`contracts/tc-kit-refine.md`](contracts/tc-kit-refine.md)

---

### Phase 3: Implement `/tc.validate`

**File**: `.specify/scripts/bash/tc-kit-validate.sh`

**Core Functions**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Calculate coverage
function calculate_coverage() {
  local spec_file="$1"
  local traceability_file="tc/spec-kit/traceability.json"

  # Count total acceptance scenarios in spec
  local total_scenarios=$(grep -cE "^\s*[0-9]+\.\s+\*\*Given\*\*" "$spec_file")

  # Count mapped tests from traceability
  local mapped_tests=$(jq '[.forward[].scenarios | length] | add' "$traceability_file")

  # Coverage percentage
  local coverage=$(awk "BEGIN {printf \"%.1f\", ($mapped_tests / $total_scenarios) * 100}")

  echo "$total_scenarios|$mapped_tests|$coverage"
}

# 2. Detect spec-test divergence
function detect_divergence() {
  local spec_file="$1"
  local traceability_file="tc/spec-kit/traceability.json"
  local maturity_file="tc/spec-kit/maturity.json"

  local warnings=()

  # For each test at exploration/implementation level:
  jq -r '.suites | to_entries[] | select(.value.maturity_level != "concept") | .key' "$maturity_file" | while read -r suite_path; do
    # Check if spec modified after test creation
    local spec_mtime=$(stat -c %Y "$spec_file")
    local test_mtime=$(stat -c %Y "$suite_path/run")

    if [ "$spec_mtime" -lt "$test_mtime" ]; then
      warnings+=("Test refined but spec unchanged: $suite_path")
    fi
  done

  # Identify out-of-scope tests (in reverse map but not in spec)
  # (pseudocode - compare traceability.reverse keys with current spec scenarios)

  printf '%s\n' "${warnings[@]}"
}

# 3. Generate coverage matrix
function generate_coverage_matrix() {
  local traceability_file="tc/spec-kit/traceability.json"
  local maturity_file="tc/spec-kit/maturity.json"

  jq -r '.forward | to_entries[] |
    {
      user_story: .key,
      title: .value.title,
      priority: .value.priority,
      scenarios_count: (.value.scenarios | length),
      tests_generated: (.value.scenarios | length)
    }' "$traceability_file"
}

# 4. Render TTY output (markdown with colors)
function render_tty_report() {
  local coverage="$1"
  local matrix="$2"
  local warnings="$3"

  echo "🔍 Test-Kit Validation Report"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "📊 Coverage Summary"
  echo "──────────────────────────────────────────────────────────"
  echo "  Coverage: $coverage% ✅"
  echo ""
  echo "📋 Coverage Matrix"
  echo "$matrix" | jq -r '"\(.user_story) | \(.priority) | \(.scenarios_count) | \(.tests_generated)"'

  if [ -n "$warnings" ]; then
    echo ""
    echo "⚠️  Divergence Warnings"
    echo "$warnings"
  fi
}

# 5. Generate JSON report
function generate_json_report() {
  local output_file="tc/spec-kit/validation-report.json"

  jq -n \
    --arg version "1.0" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson summary "$summary_json" \
    --argjson matrix "$matrix_json" \
    --argjson warnings "$warnings_json" \
    '{
      version: $version,
      generated_at: $timestamp,
      summary: $summary,
      coverage_matrix: $matrix,
      divergence_warnings: $warnings,
      validation_status: (if $summary.coverage_percentage >= 90 then "pass" else "fail" end)
    }' > "$output_file"

  echo "Report saved to: $output_file"
}

# Main execution flow
main() {
  # 1. Load inputs (spec.md, traceability.json, maturity.json)
  # 2. Calculate coverage
  # 3. Detect divergence warnings
  # 4. Generate coverage matrix
  # 5. Render output:
  #      TTY mode: colored markdown
  #      Non-TTY: plain text + JSON file
  # 6. Apply gates (coverage threshold, --strict)
  # 7. Exit with appropriate code
}

main "$@"
```

**Contract Reference**: See [`contracts/tc-kit-validate.md`](contracts/tc-kit-validate.md)

---

## Common Utilities

**File**: `.specify/scripts/bash/tc-kit-common.sh`

Shared functions across all commands:

```bash
#!/usr/bin/env bash

# Detect TTY mode (reuse tc's logic)
function is_tty() {
  [ -t 1 ] && [ "${TC_FANCY_OUTPUT:-auto}" != "false" ]
}

# Auto-detect feature directory
function detect_feature_dir() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ -n "$branch" ] && [ -d "specs/$branch" ]; then
    echo "specs/$branch"
  else
    echo "ERROR: Cannot auto-detect feature directory" >&2
    exit 1
  fi
}

# Validate JSON file
function validate_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    echo "ERROR: Invalid JSON in $file" >&2
    return 1
  fi
}

# Zero-pad numbers for directory names
function zeropad() {
  printf '%02d' "$1"
}
```

---

## Testing Your Implementation

### Self-Test with tc

Test-kit should dogfood itself - use tc to test tc-kit:

```bash
# Generate tests for tc-kit itself
cd tc
/tc.specify --spec specs/008-explore-the-strategy/spec.md

# Run self-tests
tc tc/tests/008-explore-the-strategy --all

# Validate self-tests
/tc.validate
```

### Manual Verification Checklist

From [`checklists/test-generation.md`](checklists/test-generation.md):

- [ ] Spec parsing extracts all user stories correctly
- [ ] Acceptance criteria parsing handles Given/When/Then clauses
- [ ] Pattern mapping applies correct heuristics (<uuid>, <timestamp>, etc.)
- [ ] Directory structure matches naming convention (kebab-case, zero-padded)
- [ ] Run scripts are executable and contain NOT_IMPLEMENTED template
- [ ] Traceability.json has bidirectional consistency (forward ↔ reverse)
- [ ] Maturity.json initializes all suites at "concept" level
- [ ] TTY detection works correctly (colored output in terminal, plain in pipes)
- [ ] Error handling works for malformed specs, missing files

---

## Troubleshooting

### Issue: Tests not generated

**Symptoms**: `/tc.specify` exits with "No user stories found"

**Solution**:
```bash
# Verify spec structure
grep -E "^### User Story" spec.md

# Expected: At least one match
# If no matches: Check spec.md format (must use ### prefix)
```

### Issue: Traceability corruption

**Symptoms**: `ERROR: Corrupted traceability.json`

**Solution**:
```bash
# Backup and regenerate
cp tc/spec-kit/traceability.json tc/spec-kit/traceability.json.bak
/tc.specify --force
```

### Issue: Pattern mapping incorrect

**Symptoms**: Expected `<uuid>` but got `<string>`

**Solution**:
```bash
# Check acceptance criteria wording
grep -A 2 "**Then**" spec.md

# Ensure keywords present: "UUID", "unique ID", "identifier"
# OR: Use manual refinement
/tc.refine --interactive
```

---

## Next Steps

1. **Review Planning Artifacts**:
   - [plan.md](plan.md) - Technical context and structure
   - [research.md](research.md) - Technical decisions
   - [data-model.md](data-model.md) - Entity definitions
   - [contracts/](contracts/) - Slash command specifications

2. **Implement in Order**:
   - Start with `/tc.specify` (foundation)
   - Then `/tc.refine` (depends on maturity.json)
   - Finally `/tc.validate` (depends on both)

3. **Generate Tasks**:
   ```bash
   /speckit.tasks
   ```
   This will create `tasks.md` with dependency-ordered implementation steps.

4. **Begin Implementation**:
   ```bash
   /speckit.implement
   ```
   This will execute tasks from `tasks.md` in the correct order.

---

## Resources

- **tc Framework Docs**: `tc/docs/readme.md`
- **spec-kit Workflow**: `.specify/templates/commands/`
- **Pattern Matching Reference**: `tc/docs/readme.md#pattern-matching`
- **tc Custom Patterns**: `tc/docs/readme.md#custom-patterns`

---

**Ready to implement?** Start with [`contracts/tc-kit-specify.md`](contracts/tc-kit-specify.md) and work through each slash command systematically. Good luck! 🚁
