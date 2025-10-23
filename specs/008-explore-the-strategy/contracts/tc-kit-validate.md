# Slash Command Contract: /tc.validate

**Command**: `/tc.validate`
**Purpose**: Validate that implementation-specific tests still satisfy original specification requirements, detecting spec-test drift
**Priority**: P3 (Cross-Phase Validation - User Story 3)

## Interface

### Command Syntax

```bash
/tc.validate [options]
```

### Options

| Flag | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `--spec` | path | No | Auto-detect | Path to spec.md (defaults to current feature) |
| `--format` | enum | No | auto | Output format: auto/markdown/json/both |
| `--output` | path | No | stdout | Write report to file instead of stdout |
| `--strict` | boolean | No | false | Fail on any warnings (exit 2 instead of 0) |
| `--coverage-threshold` | number | No | 90 | Minimum coverage % (fail if below) |

### Arguments

None (command uses options only)

### Environment Variables

| Variable | Type | Description |
|----------|------|-------------|
| `TC_FANCY_OUTPUT` | boolean | Override TTY detection (true/false/auto) |
| `VALIDATION_THRESHOLD` | number | Default coverage threshold (overridden by --coverage-threshold) |

## Behavior

### Preconditions

1. spec.md must exist
2. Test suites must exist (`/tc.specify` has been run)
3. `tc/spec-kit/traceability.json` must exist
4. `tc/spec-kit/maturity.json` must exist

### Success Criteria (FR-011, FR-012, FR-013, FR-014, FR-015)

**Input**: Spec, tests, traceability metadata
**Output**:
- **TTY mode**: Rich markdown report with colored tables, coverage matrix, warnings
- **Non-TTY mode**: Plain text summary + JSON file path
- **JSON file**: Always persisted to `tc/spec-kit/validation-report.json`

**Exit Codes**:
- `0` - Success (all validations pass, coverage above threshold)
- `1` - Fatal error (missing spec/tests/metadata)
- `2` - Validation failures (coverage below threshold, spec-test drift detected)

### Algorithm

```
1. Load inputs:
   - Read spec.md and extract all acceptance scenarios
   - Read tc/spec-kit/traceability.json (spec↔test mappings)
   - Read tc/spec-kit/maturity.json (maturity levels)
   - Read tc test results (from tc/tmp/report.jsonl if available)

2. Calculate coverage:
   - Count total acceptance scenarios in spec
   - Count mapped test scenarios from traceability.json
   - Coverage % = (mapped / total) * 100
   - Identify untested scenarios (in spec but not in traceability.forward)

3. Detect divergence:
   - For each test at exploration/implementation level:
     - Check if spec section has been modified since test creation
     - Compare test intent (from traceability.reverse) with current spec
     - Flag tests that diverged from original spec behavior
   - Identify out-of-scope tests (in traceability.reverse but not in spec)

4. Aggregate maturity breakdown:
   - Count tests by maturity level (concept/exploration/implementation)
   - Identify tests failing at concept but passing at implementation (spec-code mismatch)

5. Generate reports:
   - TTY mode: Render markdown with colored tables and emoji indicators
   - Non-TTY mode: Output plain text summary
   - JSON mode: Write full report to tc/spec-kit/validation-report.json

6. Apply gates:
   - If coverage < threshold: EXIT 2
   - If --strict and any warnings: EXIT 2
   - Else: EXIT 0
```

## Input/Output Examples

### Example 1: Successful Validation (TTY Mode)

**Input**:
```bash
/tc.validate
```

**Terminal Output** (TTY with colors):
```
🔍 Test-Kit Validation Report
═══════════════════════════════════════════════════════════

Feature: 008-explore-the-strategy
Spec: specs/008-explore-the-strategy/spec.md
Generated: 2025-10-18 12:34:56

📊 Coverage Summary
──────────────────────────────────────────────────────────
  Total User Stories:        3
  Total Acceptance Scenarios: 9
  Total Tests Generated:     9
  Coverage:                  100.0% ✅ (threshold: 90%)
  Untested Scenarios:        0

📋 Coverage Matrix
──────────────────────────────────────────────────────────
| User Story | Priority | Scenarios | Tests | Passing | Maturity |
|------------|----------|-----------|-------|---------|----------|
| US-1: Spec-First Test Creation | P1 | 3 | 3 | 0 | concept |
| US-2: Progressive Test Refinement | P2 | 3 | 3 | 0 | concept |
| US-3: Cross-Phase Test Validation | P3 | 3 | 3 | 0 | concept |

📈 Maturity Breakdown
──────────────────────────────────────────────────────────
  Concept:        9 tests (100%)
  Exploration:    0 tests (0%)
  Implementation: 0 tests (0%)

✅ Validation Status: PASS

  ✅ All acceptance scenarios have test coverage
  ✅ No spec-test divergence detected
  ✅ No out-of-scope tests found
  ✅ Coverage above threshold (100% >= 90%)

Report saved to: tc/spec-kit/validation-report.json

Next steps:
  - Implement test runners to progress beyond concept level
  - Run tests: tc tc/tests/008-explore-the-strategy --all
  - Refine tests: /tc.refine --suggest
```

### Example 2: Validation with Warnings (Non-TTY Mode)

**Input**:
```bash
/tc.validate
```

**Terminal Output** (non-TTY, CI/CD):
```
Test-Kit Validation Report
Feature: 008-explore-the-strategy
Generated: 2025-10-18 12:34:56

Summary:
  Total User Stories: 3
  Total Scenarios: 9
  Tests Generated: 8
  Coverage: 88.9% (below threshold: 90%)
  Untested Scenarios: 1

Warnings:
  - Coverage below threshold: 88.9% < 90%
  - Untested scenario: user-story-2.scenario-3
  - Spec-test drift detected: tc/tests/.../user-story-01/scenario-02
    (spec modified on 2025-10-18, test generated on 2025-10-17)

Status: FAIL (coverage below threshold)
Report: tc/spec-kit/validation-report.json

Exit code: 2
```

### Example 3: Spec-Test Divergence Detected

**Input**:
```bash
/tc.validate
```

**Terminal Output** (TTY with divergence warning):
```
🔍 Test-Kit Validation Report
═══════════════════════════════════════════════════════════

...

⚠️  Divergence Warnings (2)
──────────────────────────────────────────────────────────

1. Test Refined but Spec Unchanged
   Test: tc/tests/008-explore-the-strategy/user-story-01/scenario-02
   Issue: Test maturity promoted to implementation but spec unchanged since generation
   Severity: warning

   Original Spec Intent (from traceability):
     "Given technology-agnostic tests... Then /tc.refine offers options..."

   Current Test State:
     Maturity: implementation
     Last Modified: 2025-10-18 10:00:00

   Spec Last Modified: 2025-10-17 14:00:00 (before test refinement)

   Recommendation:
     - Review spec to ensure it matches implementation-level test
     - OR: Revert test to exploration level if spec not finalized
     - Run: /tc.refine --level exploration tc/tests/.../scenario-02

2. Out-of-Scope Test Detected
   Test: tc/tests/008-explore-the-strategy/user-story-01/scenario-04
   Issue: Test exists but not mapped to any spec acceptance scenario
   Severity: warning

   Possible Causes:
     - Manual test added without spec
     - Spec scenario deleted but test remains

   Recommendation:
     - Add corresponding scenario to spec.md
     - OR: Delete test if no longer needed
     - Run: /tc.specify --force to regenerate from updated spec

⚠️  Validation Status: PASS WITH WARNINGS (2)

Report saved to: tc/spec-kit/validation-report.json

Action required:
  - Address 2 divergence warnings above
  - Re-run: /tc.validate --strict (to enforce failures on warnings)
```

### Example 4: JSON Output

**Input**:
```bash
/tc.validate --format json --output validation.json
```

**validation.json** (tc/spec-kit/validation-report.json):
```json
{
  "version": "1.0",
  "generated_at": "2025-10-18T12:34:56Z",
  "feature": "008-explore-the-strategy",
  "spec_path": "/absolute/path/to/spec.md",
  "summary": {
    "total_user_stories": 3,
    "total_scenarios": 9,
    "total_tests": 9,
    "coverage_percentage": 100.0,
    "untested_scenarios": []
  },
  "coverage_matrix": [
    {
      "user_story": "user-story-1",
      "title": "Spec-First Test Creation",
      "priority": "P1",
      "scenarios_count": 3,
      "tests_generated": 3,
      "tests_passing": 0,
      "maturity_level": "concept"
    },
    {
      "user_story": "user-story-2",
      "title": "Progressive Test Refinement",
      "priority": "P2",
      "scenarios_count": 3,
      "tests_generated": 3,
      "tests_passing": 0,
      "maturity_level": "concept"
    },
    {
      "user_story": "user-story-3",
      "title": "Cross-Phase Test Validation",
      "priority": "P3",
      "scenarios_count": 3,
      "tests_generated": 3,
      "tests_passing": 0,
      "maturity_level": "concept"
    }
  ],
  "divergence_warnings": [],
  "maturity_breakdown": {
    "concept": 9,
    "exploration": 0,
    "implementation": 0
  },
  "out_of_scope_tests": [],
  "validation_status": "pass",
  "coverage_threshold": 90.0,
  "coverage_met": true
}
```

**Terminal Output**:
```
Validation report written to: validation.json
Status: PASS (100% coverage, no warnings)
```

## Error Handling

### Fatal Errors (Exit 1)

| Error | Condition | Message |
|-------|-----------|---------|
| Spec not found | spec.md missing | `ERROR: spec.md not found at {path}` |
| No tests exist | tc/tests/ empty | `ERROR: No tests found (run /tc.specify first)` |
| Missing traceability | traceability.json missing | `ERROR: Traceability missing (regenerate with /tc.specify)` |
| Corrupted metadata | Invalid JSON in metadata files | `ERROR: Corrupted {file} (backup and regenerate)` |

### Validation Failures (Exit 2)

| Failure | Condition | Message |
|---------|-----------|---------|
| Coverage below threshold | coverage < --coverage-threshold | `FAIL: Coverage {X}% < {threshold}%` |
| Strict mode warnings | --strict flag with any warnings | `FAIL: Validation warnings detected (strict mode)` |
| Untested scenarios | Scenarios in spec but not in tests | `FAIL: {N} untested scenarios found` |

### Warnings (Exit 0, unless --strict)

| Warning | Condition | Severity |
|---------|-----------|----------|
| Spec-test drift | Test refined but spec unchanged | warning |
| Out-of-scope tests | Tests not mapped to spec | warning |
| Concept-level failures | Tests fail even with patterns | warning |
| Maturity mismatch | Test maturity doesn't match signals | info |

## Output Modes

### TTY Mode (Interactive)

**Enabled when**:
- stdout is a TTY
- AND `TC_FANCY_OUTPUT != false`
- OR `--format markdown`

**Features**:
- Colored output (✅ green, ❌ red, ⚠️  yellow)
- Emoji indicators for status
- Formatted markdown tables
- Section dividers with Unicode box drawing

### Non-TTY Mode (CI/CD)

**Enabled when**:
- stdout is not a TTY
- OR `TC_FANCY_OUTPUT == false`
- OR `--format json`

**Features**:
- Plain text summary (no colors/emoji)
- JSON file path reference
- Machine-parseable output
- Exit codes for CI integration

### JSON Mode

**Enabled when**:
- `--format json` or `--format both`

**Features**:
- Complete validation data in JSON format
- Parseable by CI tools (jq, yq, etc.)
- Always persisted to `tc/spec-kit/validation-report.json`
- Schema versioned for compatibility

## Testing Contract

**TC Test Suite**: `tc/tests/tc-kit/tc-kit-validate/`

**Test Scenarios**:
1. **Full coverage**: 100% scenarios mapped → pass with green status
2. **Below threshold**: 85% coverage, threshold 90% → exit 2, fail message
3. **Divergence detection**: Refined test, unchanged spec → warning logged
4. **Out-of-scope test**: Test not in spec → warning logged
5. **TTY vs non-TTY**: Detect mode correctly → appropriate output format
6. **JSON persistence**: All modes → validation-report.json written

## Dependencies

- **tc framework**: For test result history (tc/tmp/report.jsonl)
- **jq**: For JSON parsing and generation
- **traceability.json**: Spec↔test bidirectional mappings
- **maturity.json**: Test maturity levels
- **git** (optional): For spec/test modification timestamps

## Performance

**Target** (SC-006): <5 seconds for validation of 50 user stories

**Benchmarks**:
- 10 user stories, 30 scenarios: <1 second
- 50 user stories, 150 scenarios: <5 seconds
- 100 user stories, 300 scenarios: <10 seconds

## Related Requirements

- FR-011: Maintain bidirectional spec↔test links
- FR-012: Show coverage matrix mapping requirements to scenarios
- FR-013: Detect when tests diverge from spec intent
- FR-014: Flag spec requirements with no test coverage
- FR-015: Identify implementation features tested but not in spec
- FR-022: Include spec traceability metadata in results
- FR-023: Aggregate results by maturity level
- FR-024: Highlight concept-level failures vs implementation-level passes
- SC-004: 95% accuracy in spec-test divergence detection
- SC-007: Detect 100% of untested spec requirements
- SC-009: Maintain traceability through entire lifecycle

## Integration with Spec-Kit

### `/speckit.analyze` Integration (FR-019)

**Workflow**:
1. `/tc.validate` generates validation-report.json
2. `/speckit.analyze` reads validation-report.json
3. Cross-artifact consistency checking includes:
   - spec.md ↔ tests (from validation-report.json)
   - plan.md ↔ tests (implementation alignment)
   - tasks.md ↔ tests (task coverage)

**Report Section in `/speckit.analyze`**:
```
Test Coverage (from /tc.validate):
  ✅ All spec scenarios have test coverage (100%)
  ⚠️  2 tests refined but spec unchanged (potential drift)

  Recommendation: Review refined tests or update spec to match implementation.
```
