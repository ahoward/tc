# Data Model: Test-Kit Entities and Relationships

**Feature**: Test-Kit Integration with Spec-Kit
**Phase**: 1 - Design
**Date**: 2025-10-18

## Overview

This document defines all entities, their fields, relationships, validation rules, and state transitions for the tc-kit system.

---

## Entity 1: Spec Document

**Description**: Technology-agnostic specification with user stories and acceptance criteria (spec-kit format)

**Source**: `specs/{feature}/spec.md` (markdown file)

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `feature_name` | string | Yes | Directory name (e.g., "008-explore-the-strategy") |
| `spec_path` | path | Yes | Absolute path to spec.md |
| `user_stories` | UserStory[] | Yes | Extracted user stories (1+) |
| `created_at` | timestamp | Yes | Spec creation date (from metadata) |
| `last_modified` | timestamp | Yes | File modification time |

**Relationships**:
- **1:N** with Test Suite (one spec generates multiple test suites)
- **1:1** with Traceability Link (each spec has one traceability mapping)

**Validation Rules**:
- Must contain at least one user story with "### User Story" heading
- Each user story must have "**Acceptance Scenarios**:" section
- Feature name must match directory name pattern (NNN-kebab-case)

**Parsing Rules** (from research.md):
```bash
# Extract user stories
grep -E "^### User Story [0-9]+" spec.md | sed 's/### User Story //'

# Extract priority
grep -oP 'Priority:\s+P\d+' spec.md

# Extract acceptance scenarios
sed -n '/^**Acceptance Scenarios**:/,/^---/p' spec.md
```

---

## Entity 2: User Story

**Description**: Individual user story within a spec, containing multiple acceptance scenarios

**Source**: Extracted from Spec Document markdown

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `story_number` | integer | Yes | Sequential number (1, 2, 3...) |
| `title` | string | Yes | Story title (e.g., "Spec-First Test Creation") |
| `priority` | enum | Yes | P1, P2, P3 (extracted from title) |
| `description` | string | Yes | Story narrative paragraph |
| `acceptance_scenarios` | Scenario[] | Yes | List of Given/When/Then scenarios (1+) |

**Relationships**:
- **N:1** with Spec Document (many stories belong to one spec)
- **1:N** with Acceptance Scenario (one story has multiple scenarios)

**Validation Rules**:
- Title must match pattern: "User Story N - {title} (Priority: PN)"
- Priority must be P1, P2, or P3
- Must have at least one acceptance scenario

---

## Entity 3: Acceptance Scenario

**Description**: Single Given/When/Then acceptance criterion within a user story

**Source**: Extracted from User Story **Acceptance Scenarios** section

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `scenario_number` | integer | Yes | Sequential within user story (1, 2, 3...) |
| `given` | string | Yes | Precondition (from "**Given**" clause) |
| `when` | string | Yes | Action (from "**When**" clause) |
| `then` | string | Yes | Expected outcome (from "**Then**" clause) |
| `pattern_hints` | string[] | No | Keywords for pattern mapping ("UUID", "timestamp", etc.) |

**Relationships**:
- **N:1** with User Story (many scenarios belong to one story)
- **1:1** with Test Scenario (each acceptance scenario generates one test)

**Validation Rules**:
- Must contain all three clauses: Given, When, Then
- Each clause must be non-empty

**Pattern Extraction** (from research.md):
```bash
# Extract keywords for pattern mapping
echo "$then" | grep -ioE '(uuid|unique id|identifier|timestamp|created|date|time|count|total|number|enabled|active|null|empty)'
```

---

## Entity 4: Test Suite

**Description**: Collection of tc test scenarios derived from acceptance criteria, organized by user story

**File System**: `tc/tests/{feature-name}/user-story-{NN}/`

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `suite_path` | path | Yes | Absolute path to suite directory |
| `user_story_ref` | string | Yes | Reference to source user story (e.g., "user-story-01") |
| `scenarios` | TestScenario[] | Yes | List of test scenarios in suite (1+) |
| `maturity_level` | enum | Yes | concept / exploration / implementation |
| `created_at` | timestamp | Yes | Suite generation timestamp |

**Directory Structure**:
```
tc/tests/{feature-name}/user-story-{NN}/
└── scenario-{NN}/     # Individual test scenarios
    ├── run            # Executable test runner
    └── data/
        ├── input.json
        └── expected.json
```

**Relationships**:
- **N:1** with Spec Document (many suites from one spec)
- **1:1** with User Story (one suite per user story)
- **1:N** with Test Scenario (one suite contains multiple scenarios)

**Validation Rules**:
- Suite path must match naming convention: `tc/tests/{feature}/user-story-{NN}/`
- NN must be zero-padded to 2 digits
- Must contain at least one test scenario

---

## Entity 5: Test Scenario

**Description**: Single executable test case with input.json, expected.json, and run script validating one acceptance criterion

**File System**: `tc/tests/{feature-name}/user-story-{NN}/scenario-{NN}/`

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `scenario_path` | path | Yes | Absolute path to scenario directory |
| `input_json` | JSON object | Yes | Test input (from Given clause mapping) |
| `expected_json` | JSON object | Yes | Expected output (from Then clause, with patterns) |
| `run_script` | path | Yes | Executable run script (bash, chmod +x) |
| `spec_ref` | string | Yes | Traceability reference (e.g., "user-story-1.scenario-2") |
| `status` | enum | Yes | NOT_IMPLEMENTED / PASSING / FAILING |

**File Structure**:
```
scenario-{NN}/
├── run                # Executable bash script
└── data/
    ├── input.json     # Test input
    └── expected.json  # Expected output with patterns
```

**Relationships**:
- **N:1** with Test Suite (many scenarios in one suite)
- **1:1** with Acceptance Scenario (one test per acceptance scenario)
- **1:1** with Traceability Link (bidirectional spec↔test link)

**Validation Rules**:
- `run` script must be executable (chmod +x)
- `input.json` and `expected.json` must be valid JSON
- Scenario path must match: `tc/tests/{feature}/user-story-{NN}/scenario-{NN}/`
- Both NN must be zero-padded to 2 digits

**State Transitions**:
```
NOT_IMPLEMENTED → PASSING  (when run script returns exit 0)
NOT_IMPLEMENTED → FAILING  (when run script returns exit 1+)
PASSING → FAILING          (when implementation breaks)
FAILING → PASSING          (when bugs fixed)
```

---

## Entity 6: Test Maturity Level

**Description**: Classification of test abstraction (concept/exploration/implementation) indicating refinement progress

**Source**: `tc/spec-kit/maturity.json`

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `suite_path` | path | Yes | Reference to test suite |
| `maturity_level` | enum | Yes | concept / exploration / implementation |
| `detected_signals` | object | Yes | Evidence for maturity level |
| `manual_override` | enum | No | User-forced level (overrides signals) |
| `last_transition` | timestamp | No | When level last changed |

**Maturity Levels**:
- **concept**: Pure pattern-based tests (`<uuid>`, `<timestamp>`), NOT_IMPLEMENTED run scripts
- **exploration**: Mixed patterns + concrete values, partially implemented run scripts
- **implementation**: Mostly concrete values, fully implemented run scripts with assertions

**Signal Detection**:
```json
{
  "has_implementation": false,        // Run script modified beyond template?
  "passing_runs": 0,                  // Consecutive passing test runs
  "last_modified": "2025-10-18...",   // Run script modification time
  "pattern_types": ["<uuid>", ...]    // Patterns used in expected.json
}
```

**State Transitions** (from research.md, Clarification §2025-10-18):
```
concept → exploration:
  - First implementation commit detected (run script modified)
  - OR manual override: `--level exploration`

exploration → implementation:
  - 5+ consecutive passing test runs
  - Pattern usage decreased (more exact values in expected.json)
  - OR manual override: `--level implementation`
```

**Relationships**:
- **1:1** with Test Suite (each suite has one maturity level)

**Validation Rules**:
- `maturity_level` must be one of: concept, exploration, implementation
- `passing_runs` must be non-negative integer
- If `manual_override` set, it must match `maturity_level`

---

## Entity 7: Pattern Mapping

**Description**: Relationship between abstract patterns in expected.json and concrete implementation validations

**Source**: Generated during test creation, refined during `/tc.refine`

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pattern_type` | enum | Yes | `<uuid>`, `<timestamp>`, `<number>`, `<string>`, `<boolean>`, `<null>`, `<any>` |
| `json_path` | string | Yes | Location in expected.json (e.g., "$.data.user.id") |
| `original_spec_text` | string | Yes | Source text from acceptance criteria |
| `refined_value` | any | No | Concrete value (when refined to implementation level) |

**Pattern Types** (from tc framework + research.md):
| Pattern | Validates | Example |
|---------|-----------|---------|
| `<uuid>` | UUID v4 format | "550e8400-e29b-41d4-a716-446655440000" |
| `<timestamp>` | ISO 8601 | "2025-10-18T12:34:56Z" |
| `<number>` | Any JSON number | 42, 3.14 |
| `<string>` | Any string value | "hello" |
| `<boolean>` | true or false | true |
| `<null>` | null value | null |
| `<any>` | Anything | (wildcard) |

**Heuristic Mapping** (from research.md):
```
Spec text: "unique identifier" → <uuid>
Spec text: "timestamp"         → <timestamp>
Spec text: "count"             → <number>
Spec text: "pending"           → "pending" (exact match - specific value stated)
```

**Relationships**:
- **N:1** with Test Scenario (many patterns in one expected.json)

**Validation Rules**:
- `pattern_type` must be valid tc pattern or custom pattern (TC_CUSTOM_PATTERNS)
- `json_path` must be valid JSONPath expression
- If `refined_value` exists, it must match `pattern_type` validation

---

## Entity 8: Traceability Link

**Description**: Connection between spec requirement ID and corresponding test scenario(s)

**Source**: `tc/spec-kit/traceability.json`

**Schema**:
```json
{
  "version": "1.0",
  "feature": "008-explore-the-strategy",
  "spec_path": "/absolute/path/to/spec.md",
  "generated_at": "2025-10-18T12:34:56Z",
  "forward": {
    "user-story-1": {
      "title": "Spec-First Test Creation",
      "priority": "P1",
      "scenarios": {
        "scenario-1": "tc/tests/008-explore-the-strategy/user-story-01/scenario-01",
        "scenario-2": "tc/tests/008-explore-the-strategy/user-story-01/scenario-02"
      }
    }
  },
  "reverse": {
    "tc/tests/008-explore-the-strategy/user-story-01/scenario-01": {
      "spec_ref": "user-story-1.scenario-1",
      "user_story": "Spec-First Test Creation",
      "given_when_then": "Given a spec-kit specification with user stories..."
    }
  }
}
```

**Fields**:
- **version**: Schema version (semantic versioning)
- **feature**: Feature name (directory name)
- **spec_path**: Absolute path to source spec.md
- **generated_at**: Timestamp of traceability generation
- **forward**: Spec → Test mapping (O(1) lookup)
- **reverse**: Test → Spec mapping (O(1) lookup)

**Relationships**:
- **1:1** with Spec Document (each spec has one traceability file)
- **1:N** with Test Scenario (maps all test scenarios to spec)

**Validation Rules**:
- `version` must match semantic versioning (X.Y format)
- `forward` and `reverse` must be consistent (bidirectional integrity)
- All paths in `reverse` must exist on filesystem
- All `spec_ref` must reference valid user-story-N.scenario-M

**Integrity Check**:
```bash
# Verify bidirectional consistency
for test_path in reverse.keys:
  assert forward[spec_ref].scenarios contains test_path
```

---

## Entity 9: Validation Report

**Description**: Analysis showing spec coverage, test alignment, and drift detection across maturity levels

**Source**: Generated by `/tc.validate`, persisted to `tc/spec-kit/validation-report.json`

**Schema**:
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
      "scenarios_count": 3,
      "tests_generated": 3,
      "tests_passing": 0,
      "maturity_level": "concept"
    }
  ],
  "divergence_warnings": [
    {
      "test_path": "tc/tests/.../scenario-02",
      "issue": "Test refined but spec unchanged",
      "severity": "warning"
    }
  ],
  "maturity_breakdown": {
    "concept": 9,
    "exploration": 0,
    "implementation": 0
  },
  "out_of_scope_tests": []
}
```

**Fields**:
- **summary**: High-level coverage statistics
- **coverage_matrix**: Per-user-story coverage details
- **divergence_warnings**: Tests that diverged from spec intent
- **maturity_breakdown**: Test distribution by maturity level
- **out_of_scope_tests**: Tests not mapped to spec requirements

**Relationships**:
- **N:1** with Spec Document (many reports over time for one spec)
- **Reads From**: Traceability Link, Test Maturity Level, Test Scenario

**Validation Rules**:
- `coverage_percentage` must be 0-100
- `summary.total_tests` must equal sum of `coverage_matrix[*].tests_generated`
- All test paths in `divergence_warnings` must exist

**Output Modes** (from research.md, Clarification §2025-10-18):
- **TTY**: Rich markdown with colored tables, emoji indicators
- **Non-TTY**: Plain text summary + JSON file path
- **JSON file**: Always persisted to `tc/spec-kit/validation-report.json`

---

## Entity Relationship Diagram

```
Spec Document (spec.md)
  ├─── 1:N ───> User Story
  │               ├─── 1:N ───> Acceptance Scenario
  │               │               └─── 1:1 ───> Test Scenario
  │               │                               ├─── run script
  │               │                               ├─── input.json
  │               │                               ├─── expected.json
  │               │                               └─── N:1 ───> Pattern Mapping
  │               └─── 1:1 ───> Test Suite
  │                               └─── 1:1 ───> Test Maturity Level
  ├─── 1:1 ───> Traceability Link (traceability.json)
  └─── 1:N ───> Validation Report (validation-report.json)
```

---

## Summary

**Total Entities**: 9
- **Core Entities**: Spec Document, User Story, Acceptance Scenario
- **Test Entities**: Test Suite, Test Scenario
- **Metadata Entities**: Test Maturity Level, Pattern Mapping, Traceability Link, Validation Report

**Key Relationships**:
- Spec Document → User Story → Acceptance Scenario → Test Scenario (generation flow)
- Test Scenario ↔ Traceability Link (bidirectional mapping)
- Test Suite ↔ Test Maturity Level (refinement tracking)

**Next Phase**: Generate slash command contracts
