# Tasks: Test-Kit Integration with Spec-Kit

**Input**: Design documents from `/specs/008-explore-the-strategy/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: This feature follows test-first discipline (Assumption 3) with tc dogfooding. All slash commands will have tc test suites.

**Organization**: Tasks are grouped by user story (P1, P2, P3) to enable independent implementation and testing of each slash command.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Slash commands**: `.specify/scripts/bash/tc-kit-*.sh`
- **Templates**: `.specify/templates/commands/tc-kit-*.md`
- **Tests**: `tc/tests/tc-kit/tc-kit-*/`
- **State storage**: `tc/spec-kit/*.json`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and shared utilities for all slash commands

- [x] T001 Create tc-kit directory structure in `.specify/scripts/bash/`
- [x] T002 [P] Create `tc/spec-kit/` state directory for traceability, maturity, validation reports
- [x] T003 [P] Implement shared utilities in `.specify/scripts/bash/tc-kit-common.sh`:
  - TTY detection (is_tty)
  - Feature directory auto-detection (detect_feature_dir)
  - JSON validation (validate_json)
  - Number formatting (zeropad)
- [x] T004 [P] Create slash command templates in `.specify/templates/commands/`:
  - `tc-kit-specify.md` (test generation command)
  - `tc-kit-refine.md` (refinement command)
  - `tc-kit-validate.md` (validation command)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**Note**: This feature has no foundational blockers - each slash command (user story) is independent and can be implemented in parallel after Setup.

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Spec-First Test Creation (Priority: P1) 🎯 MVP

**Goal**: Generate technology-agnostic tc test suites from spec.md, creating input.json, expected.json, and run scripts with NOT_IMPLEMENTED placeholders

**Independent Test**: Create a spec.md, run `/tc.specify`, verify tc test suites generated in `tc/tests/{feature}/user-story-NN/scenario-NN/` with proper directory structure and traceability.json

### Tests for User Story 1 (Test-First)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T005 [P] [US1] Create test suite directory `tc/tests/tc-kit/tc-kit-specify/basic-generation/`
- [x] T006 [P] [US1] Write test scenario: basic generation from valid spec
  - Input: Minimal spec.md with 1 user story, 1 scenario
  - Expected: Test directory created, run script exists, traceability.json valid
  - Location: `tc/tests/tc-kit/tc-kit-specify/basic-generation/data/`
- [x] T007 [P] [US1] Write test scenario: pattern mapping heuristics
  - Input: Acceptance criteria with keywords (UUID, timestamp, count)
  - Expected: Correct patterns in expected.json (<uuid>, <timestamp>, <number>)
  - Location: `tc/tests/tc-kit/tc-kit-specify/pattern-mapping/data/`
- [x] T008 [P] [US1] Write test scenario: traceability bidirectional consistency
  - Input: Spec with 3 user stories, 9 scenarios
  - Expected: traceability.json forward/reverse maps consistent
  - Location: `tc/tests/tc-kit/tc-kit-specify/traceability/data/`
- [x] T009 [P] [US1] Write test scenario: partial failure handling
  - Input: Spec with 1 malformed scenario (missing Then clause)
  - Expected: Exit 2, warning logged, other scenarios generated
  - Location: `tc/tests/tc-kit/tc-kit-specify/partial-failure/data/`
- [x] T010 [P] [US1] Write test scenario: dry-run mode
  - Input: --dry-run flag, valid spec
  - Expected: No files created, preview shown
  - Location: `tc/tests/tc-kit/tc-kit-specify/dry-run/data/`

### Implementation for User Story 1

- [x] T011 [US1] Implement spec parsing functions in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `parse_user_stories()` - Extract user story titles, numbers, priorities
  - `parse_acceptance_scenarios()` - Extract Given/When/Then clauses
  - Use grep/sed patterns from research.md Decision 1
- [x] T012 [US1] Implement pattern mapping heuristics in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `map_to_pattern()` - Apply keyword-based rules
  - Support <uuid>, <timestamp>, <number>, <boolean>, <null>, <string>
  - Use heuristics from research.md Decision 2
- [x] T013 [US1] Implement test directory generation in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `generate_test_suite()` - Create kebab-case, zero-padded directories
  - Format: `tc/tests/{feature}/user-story-{NN}/scenario-{NN}/`
  - Use naming convention from research.md Decision 3
- [x] T014 [US1] Implement JSON file generation in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `generate_input_json()` - Map Given clause to input.json
  - `generate_expected_json()` - Map Then clause with patterns to expected.json
- [x] T015 [US1] Implement run script generation in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `generate_run_script()` - Create NOT_IMPLEMENTED template
  - Include spec reference, traceability metadata
  - Make executable (chmod +x)
  - Use template from research.md Decision 4
- [x] T016 [US1] Implement traceability.json generation in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `generate_traceability()` - Create dual-index structure
  - Build forward map (spec → tests)
  - Build reverse map (tests → spec)
  - Use schema from research.md Decision 5, data-model.md Entity 8
- [x] T017 [US1] Implement maturity.json initialization in `.specify/scripts/bash/tc-kit-specify.sh`:
  - `initialize_maturity()` - Set all tests to "concept" level
  - Record creation timestamp
  - Set has_implementation = false
  - Use schema from research.md Decision 6, data-model.md Entity 6
- [x] T018 [US1] Implement error handling in `.specify/scripts/bash/tc-kit-specify.sh`:
  - Fatal errors: spec not found, no user stories (exit 1)
  - Recoverable errors: malformed scenario, skip and warn (exit 2)
  - Use strategy from research.md Decision 7
- [x] T019 [US1] Implement main execution flow in `.specify/scripts/bash/tc-kit-specify.sh`:
  - Auto-detect feature directory
  - Parse spec.md
  - Generate all test suites
  - Generate traceability and maturity metadata
  - Report summary (user stories, scenarios, tests, coverage)
- [x] T020 [US1] Add command-line options to `.specify/scripts/bash/tc-kit-specify.sh`:
  - --spec, --output, --dry-run, --force, --verbose
  - See contracts/tc-kit-specify.md for full interface

**Checkpoint**: At this point, `/tc.specify` should be fully functional - run `tc tc/tests/tc-kit/tc-kit-specify --all` to verify all tests pass

---

## Phase 4: User Story 2 - Progressive Test Refinement (Priority: P2)

**Goal**: Detect maturity level signals (implementation commits, passing runs) and suggest/apply test refinements while preserving baseline tests

**Independent Test**: Take existing test suite, modify run script, run tests multiple times, then run `/tc.refine --suggest` - verify exploration level suggested and refinement opportunities shown

### Tests for User Story 2 (Test-First)

- [x] T021 [P] [US2] Create test suite directory `tc/tests/tc-kit/tc-kit-refine/signal-detection/`
- [x] T022 [P] [US2] Write test scenario: concept → exploration detection
  - Input: Test suite with modified run script, maturity.json at concept level
  - Expected: Exploration level suggested, signals.has_implementation = true
  - Location: `tc/tests/tc-kit/tc-kit-refine/signal-detection/data/`
- [x] T023 [P] [US2] Write test scenario: baseline preservation
  - Input: Apply refinement with --apply flag
  - Expected: Original test copied to scenario-NN-concept-baseline/
  - Location: `tc/tests/tc-kit/tc-kit-refine/baseline-preservation/data/`
- [x] T024 [P] [US2] Write test scenario: over-specification warning
  - Input: Force implementation level with only 2 passing runs
  - Expected: Warning shown, confirmation required
  - Location: `tc/tests/tc-kit/tc-kit-refine/over-specification/data/`
- [x] T025 [P] [US2] Write test scenario: interactive mode
  - Input: --interactive flag, user responses (Y/n/s)
  - Expected: Prompts shown, only selected refinements applied
  - Location: `tc/tests/tc-kit/tc-kit-refine/interactive/data/`

### Implementation for User Story 2

- [x] T026 [US2] Implement signal detection in `.specify/scripts/bash/tc-kit-refine.sh`:
  - `detect_maturity_signals()` - Check run script modification, passing runs, pattern usage
  - Use git log or mtime for modification detection
  - Parse tc execution logs for passing runs
  - Analyze expected.json for pattern types
- [x] T027 [US2] Implement maturity level suggestion in `.specify/scripts/bash/tc-kit-refine.sh`:
  - `suggest_maturity_level()` - Apply transition rules
  - Concept → Exploration: implementation detected
  - Exploration → Implementation: 5+ passing runs
  - Use rules from research.md Decision 6
- [x] T028 [US2] Implement baseline preservation in `.specify/scripts/bash/tc-kit-refine.sh`:
  - `preserve_baseline()` - Copy original test to baseline directory
  - Naming: scenario-NN-{level}-baseline/
  - Prevent overwrite if baseline exists (append timestamp)
- [x] T029 [US2] Implement refinement suggestion logic in `.specify/scripts/bash/tc-kit-refine.sh`:
  - `suggest_refinements()` - Analyze patterns, suggest concrete values or custom patterns
  - For <uuid>: suggest concrete UUID from passing runs
  - For <timestamp>: suggest custom pattern <timestamp_recent>
  - Detect over-specification risks
- [x] T030 [US2] Implement refinement application in `.specify/scripts/bash/tc-kit-refine.sh`:
  - `apply_refinements()` - Update expected.json with refined values
  - Use jq to modify JSON paths
  - Preserve unrefined patterns
- [x] T031 [US2] Implement maturity.json updates in `.specify/scripts/bash/tc-kit-refine.sh`:
  - `update_maturity()` - Update maturity level, signals, last_transition
  - Record manual override if --level flag used
  - Use schema from data-model.md Entity 6
- [x] T032 [US2] Implement interactive mode in `.specify/scripts/bash/tc-kit-refine.sh`:
  - Prompt for level transition (Y/n)
  - Prompt for each refinement opportunity (Y/n/s)
  - Skip all on 's' response
- [x] T033 [US2] Implement main execution flow in `.specify/scripts/bash/tc-kit-refine.sh`:
  - Load maturity.json and traceability.json
  - For each test suite: detect signals, suggest level
  - If --apply: preserve baseline, apply refinements, update metadata
  - Report summary (tests analyzed, refinements suggested/applied, transitions)
- [x] T034 [US2] Add command-line options to `.specify/scripts/bash/tc-kit-refine.sh`:
  - --level, --suite, --interactive, --suggest, --apply, --dry-run
  - See contracts/tc-kit-refine.md for full interface

**Checkpoint**: At this point, `/tc.refine` should be fully functional - run `tc tc/tests/tc-kit/tc-kit-refine --all` to verify all tests pass

---

## Phase 5: User Story 3 - Cross-Phase Test Validation (Priority: P3)

**Goal**: Calculate test coverage, detect spec-test divergence, generate coverage matrix, output TTY/JSON validation reports

**Independent Test**: Create spec with known coverage (e.g., 8/9 scenarios tested), run `/tc.validate`, verify coverage 88.9%, divergence warnings shown, validation-report.json written

### Tests for User Story 3 (Test-First)

- [x] T035 [P] [US3] Create test suite directory `tc/tests/tc-kit/tc-kit-validate/full-coverage/`
- [x] T036 [P] [US3] Write test scenario: full coverage validation
  - Input: Spec with 9 scenarios, all tested, traceability complete
  - Expected: Coverage 100%, validation pass, no warnings
  - Location: `tc/tests/tc-kit/tc-kit-validate/full-coverage/data/`
- [x] T037 [P] [US3] Write test scenario: below threshold failure
  - Input: 85% coverage, threshold 90%
  - Expected: Exit 2, coverage failure message
  - Location: `tc/tests/tc-kit/tc-kit-validate/below-threshold/data/`
- [x] T038 [P] [US3] Write test scenario: divergence detection
  - Input: Refined test, unchanged spec (spec mtime < test mtime)
  - Expected: Warning logged in divergence_warnings array
  - Location: `tc/tests/tc-kit/tc-kit-validate/divergence/data/`
- [x] T039 [P] [US3] Write test scenario: TTY vs non-TTY output
  - Input: TTY mode (--format markdown), non-TTY mode (--format json)
  - Expected: Colored markdown for TTY, plain JSON for non-TTY
  - Location: `tc/tests/tc-kit/tc-kit-validate/output-modes/data/`
- [x] T040 [P] [US3] Write test scenario: JSON persistence
  - Input: Any validation run
  - Expected: tc/spec-kit/validation-report.json written with complete data
  - Location: `tc/tests/tc-kit/tc-kit-validate/json-persistence/data/`

### Implementation for User Story 3

- [x] T041 [US3] Implement coverage calculation in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `calculate_coverage()` - Count total scenarios in spec, mapped tests
  - Coverage % = (mapped / total) * 100
  - Identify untested scenarios (in spec but not in traceability.forward)
- [x] T042 [US3] Implement divergence detection in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `detect_divergence()` - Compare spec mtime vs test mtime for refined tests
  - Check maturity level (exploration/implementation) vs spec modification
  - Identify out-of-scope tests (in traceability.reverse but not in current spec)
  - Generate warnings array
- [x] T043 [US3] Implement coverage matrix generation in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `generate_coverage_matrix()` - Build per-user-story coverage table
  - Include: user_story, title, priority, scenarios_count, tests_generated, tests_passing, maturity_level
  - Use jq to process traceability.json and maturity.json
- [x] T044 [US3] Implement maturity breakdown in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `generate_maturity_breakdown()` - Count tests by level (concept/exploration/implementation)
  - Identify tests failing at concept but passing at implementation (spec-code mismatch)
- [x] T045 [US3] Implement TTY output rendering in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `render_tty_report()` - Rich markdown with colors, emoji, tables
  - Use Unicode box drawing for section dividers
  - Color codes: ✅ green, ❌ red, ⚠️  yellow
  - Reuse TTY detection from tc-kit-common.sh
- [x] T046 [US3] Implement non-TTY output in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `render_plain_report()` - Plain text summary, no colors/emoji
  - Include JSON file path reference
  - Machine-parseable format for CI
- [x] T047 [US3] Implement JSON report generation in `.specify/scripts/bash/tc-kit-validate.sh`:
  - `generate_json_report()` - Write validation-report.json
  - Include: version, timestamp, summary, coverage_matrix, divergence_warnings, maturity_breakdown
  - Use schema from data-model.md Entity 9
  - Always persist to tc/spec-kit/validation-report.json
- [x] T048 [US3] Implement validation gates in `.specify/scripts/bash/tc-kit-validate.sh`:
  - Check coverage >= threshold (default 90%)
  - Check --strict mode (fail on any warnings)
  - Return appropriate exit codes (0=pass, 1=error, 2=validation failure)
- [x] T049 [US3] Implement main execution flow in `.specify/scripts/bash/tc-kit-validate.sh`:
  - Load spec.md, traceability.json, maturity.json
  - Calculate coverage, detect divergence, generate matrix
  - Render output based on TTY detection and --format flag
  - Generate JSON report (always)
  - Apply gates and exit with appropriate code
- [x] T050 [US3] Add command-line options to `.specify/scripts/bash/tc-kit-validate.sh`:
  - --spec, --format, --output, --strict, --coverage-threshold
  - See contracts/tc-kit-validate.md for full interface

**Checkpoint**: At this point, `/tc.validate` should be fully functional - run `tc tc/tests/tc-kit/tc-kit-validate --all` to verify all tests pass

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final integration

- [x] T051 [P] Integration testing: Run all three slash commands in sequence on this feature's spec
  - `/tc.specify` → generate tests
  - Manually implement a run script
  - `/tc.refine --suggest` → verify exploration suggested
  - `/tc.validate` → verify coverage and maturity reporting
- [x] T052 [P] Documentation: Update `README.md` with tc-kit section and slash command examples
- [x] T053 [P] Documentation: Update `quickstart.md` based on actual implementation (if changes from design)
- [x] T054 Performance optimization: Benchmark test generation for 50+ user stories
  - Target: <30 seconds (SC-001)
  - Add performance warnings if threshold exceeded
- [x] T055 Performance optimization: Benchmark validation for 50+ user stories
  - Target: <5 seconds
  - Optimize jq queries if needed
- [x] T056 [P] Dogfooding validation: Run tc-kit on itself
  - Verify all tc-kit tests pass: `tc tc/tests/tc-kit --all`
  - Generate tc-kit's own coverage report: `/tc.validate`
- [x] T057 Error message review: Ensure all error messages are clear and actionable
- [x] T058 [P] Add examples to documentation: Include real-world spec.md and generated tests

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BUT this phase is empty (no foundational blockers)
- **User Stories (Phase 3-5)**: All depend on Setup completion only
  - User stories are INDEPENDENT and can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3) for single developer
- **Polish (Phase 6)**: Depends on all three user stories being complete

### User Story Dependencies

- **User Story 1 (P1) - `/tc.specify`**: Can start after Setup - No dependencies on other stories
- **User Story 2 (P2) - `/tc.refine`**: Can start after Setup - No dependencies on other stories (reads maturity.json but doesn't require US1 complete)
- **User Story 3 (P3) - `/tc.validate`**: Can start after Setup - No dependencies on other stories (reads traceability.json but doesn't require US1/US2 complete)

**Key Insight**: All three user stories are INDEPENDENT slash commands. After Setup, they can be implemented in parallel by a team of 3, or sequentially by a single developer in priority order.

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Implementation tasks follow logical dependency order (parsing → generation → metadata)
- Core functions before command-line options
- All tests for a story must pass before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup)**:
- T002, T003, T004 can all run in parallel (different directories/files)

**Phase 3 (User Story 1)**:
- T005-T010 (all test scenarios) can run in parallel (different test suites)

**Phase 4 (User Story 2)**:
- T021-T025 (all test scenarios) can run in parallel (different test suites)

**Phase 5 (User Story 3)**:
- T035-T040 (all test scenarios) can run in parallel (different test suites)

**Phase 6 (Polish)**:
- T052, T053, T056, T058 can run in parallel (different documentation files)

**Cross-Story Parallelism** (if team of 3):
- After Setup (Phase 1), one developer can work on US1, another on US2, another on US3 simultaneously

---

## Parallel Example: User Story 1

```bash
# Launch all test scenarios for User Story 1 together (T005-T010):
Task: "Write test scenario: basic generation from valid spec"
Task: "Write test scenario: pattern mapping heuristics"
Task: "Write test scenario: traceability bidirectional consistency"
Task: "Write test scenario: partial failure handling"
Task: "Write test scenario: dry-run mode"

# Then implement sequentially:
Task: "Implement spec parsing functions" (T011)
Task: "Implement pattern mapping heuristics" (T012)
# ... etc
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Skip Phase 2: Foundational (empty - no blockers)
3. Complete Phase 3: User Story 1 (T005-T020)
4. **STOP and VALIDATE**: Run `tc tc/tests/tc-kit/tc-kit-specify --all`
5. **DOGFOOD**: Run `/tc.specify` on this feature's spec.md
6. Deploy/demo if ready - teams can now generate tests from specs!

### Incremental Delivery

1. Complete Setup → Foundation ready
2. Add User Story 1 (`/tc.specify`) → Test independently → **Deploy/Demo (MVP!)** 🎯
   - Teams can now generate technology-agnostic tests from specs
   - All tests start at "concept" maturity level
3. Add User Story 2 (`/tc.refine`) → Test independently → Deploy/Demo
   - Teams can now refine tests as implementation progresses
   - Maturity tracking enables progressive refinement
4. Add User Story 3 (`/tc.validate`) → Test independently → Deploy/Demo
   - Teams can now validate coverage and detect spec-test drift
   - Complete tc-kit workflow available
5. Each story adds value without breaking previous stories

### Parallel Team Strategy (3 Developers)

With a team of 3 developers:

1. **Team completes Setup together** (T001-T004) - ~1 hour
2. Once Setup is done, split into 3 tracks:
   - **Developer A**: User Story 1 (T005-T020) - `/tc.specify` - ~2-3 days
   - **Developer B**: User Story 2 (T021-T034) - `/tc.refine` - ~2-3 days
   - **Developer C**: User Story 3 (T035-T050) - `/tc.validate` - ~2-3 days
3. Stories complete independently and integrate at Phase 6 (Polish)
4. **Total time**: ~3-4 days instead of 9-12 days sequential

---

## Task Summary

**Total Tasks**: 58
- **Setup (Phase 1)**: 4 tasks
- **Foundational (Phase 2)**: 0 tasks (no blockers)
- **User Story 1 (Phase 3)**: 16 tasks (6 tests + 10 implementation)
- **User Story 2 (Phase 4)**: 14 tasks (5 tests + 9 implementation)
- **User Story 3 (Phase 5)**: 16 tasks (6 tests + 10 implementation)
- **Polish (Phase 6)**: 8 tasks

**Parallel Opportunities**: 27 tasks marked [P] (46% parallelizable)

**Test Coverage**:
- 17 test scenarios across 3 slash commands
- Tests written FIRST (TDD approach)
- Dogfooding: tc-kit tests itself using tc framework

**MVP Scope**: User Story 1 only (T001-T020) = 20 tasks (~2-3 days for single developer)

**Full Feature**: All 3 user stories (T001-T058) = ~9-12 days sequential, ~3-4 days with team of 3

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story for traceability (US1, US2, US3)
- Each user story is independently completable and testable
- Tests must fail before implementing (TDD)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All three slash commands are independent - no cross-story dependencies
- Dogfooding: Use `/tc.specify` on this very spec.md to generate tests for tc-kit itself
