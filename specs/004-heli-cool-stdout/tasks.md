# Tasks: Heli-Cool Stdout - Animated Test Runner Output

**Input**: Design documents from `/specs/004-heli-cool-stdout/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: This feature will dogfood TC's own test framework - new test suite will validate the fancy output behavior.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions
- New modules: `tc/lib/utils/{ansi.sh, status-line.sh, log-writer.sh}`
- Updated modules: `tc/lib/core/{executor.sh, runner.sh}`, `tc/lib/utils/reporter.sh`
- Config: `tc/config/defaults.sh`
- Tests: `tc/tests/integration/heli-output/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and environment setup

- [X] **T001** Create feature test suite directory: `mkdir -p tc/tests/integration/heli-output/data`
- [X] **T002** [P] Create baseline commit with message "pre-heli-output checkpoint"
- [X] **T003** [P] Capture baseline test output: `tc run tests --all > /tmp/tc-baseline-output.txt 2>&1`

**Checkpoint**: Baseline established, safe to proceed with implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core utility modules that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] **T004** Create `tc/lib/utils/ansi.sh` with ANSI color constants and basic functions
- [X] **T005** Implement `tc_ansi_supported()` function for TTY/ANSI capability detection in `ansi.sh`
- [X] **T006** Implement `tc_ansi_color(name)` function (green/red/yellow/reset) in `ansi.sh`
- [X] **T007** Implement `tc_ansi_clear_line()` function in `ansi.sh`
- [X] **T008** [P] Implement `tc_ansi_hide_cursor()` and `tc_ansi_show_cursor()` in `ansi.sh`
- [X] **T009** Add ansi.sh module to tc/bin/tc: `source "$TC_ROOT/lib/utils/ansi.sh"`
- [X] **T010** Update `tc/config/defaults.sh` to add TC_FANCY_OUTPUT, TC_REPORT_DIR, TC_LOG_FILE env vars
- [X] **T011** Update `tc/config/defaults.sh` to add TC_NO_ANIMATION, TC_NO_COLOR env vars with defaults

**Checkpoint**: Foundation ready - ANSI utilities and configuration available

---

## Phase 3: User Story 1 - Real-Time Test Status with Single-Line Updates (Priority: P1) 🎯 MVP

**Goal**: Single-line status that updates in place, showing test progress without scrolling

**Independent Test**: Run `tc run tests --all` in a TTY and verify only one line updates, replacing itself not creating new lines

### Implementation for User Story 1

- [X] **T012** [US1] Create `tc/lib/utils/status-line.sh` file structure with header comments
- [X] **T013** [US1] Implement `tc_terminal_width()` function in `status-line.sh` (uses tput cols, fallback 80)
- [X] **T014** [US1] Implement `tc_status_init()` function in `status-line.sh` (detect TTY mode, init state vars)
- [X] **T015** [US1] Implement basic `tc_status_update(suite, test, status, passed, failed)` in `status-line.sh` (TTY: CR+rewrite, non-TTY: new line)
- [X] **T016** [US1] Implement `tc_status_finish(passed, failed)` in `status-line.sh` (show cursor, print summary)
- [X] **T017** [US1] Add status-line.sh module to tc/bin/tc: `source "$TC_ROOT/lib/utils/status-line.sh"`
- [X] **T018** [US1] Update `tc/lib/core/executor.sh` to call `tc_status_init()` before suite execution
- [X] **T019** [US1] Update `tc/lib/core/executor.sh` to call `tc_status_update()` on each test completion
- [X] **T020** [US1] Update `tc/lib/core/executor.sh` to call `tc_status_finish()` after suite completes
- [X] **T021** [US1] Update `tc/lib/utils/reporter.sh` to detect TTY mode and skip multi-line output if fancy mode active

### Testing for User Story 1

- [ ] **T022** [US1] Create test suite `tc/tests/integration/heli-output/` with test scenarios for TTY vs non-TTY
- [ ] **T023** [US1] Add test scenario: verify single-line updates in simulated TTY mode
- [ ] **T024** [US1] Add test scenario: verify final summary appears after status line
- [ ] **T025** [US1] Run `tc run tc/tests/integration/heli-output` to validate User Story 1

**Checkpoint**: User Story 1 complete - single-line updating status works in TTY mode

---

## Phase 4: User Story 2 - Visual Test Status Indicators (Priority: P2)

**Goal**: Color-coded status labels and emoji markers for instant visual recognition

**Independent Test**: Verify status line includes 🚁 emoji, colored RUNNING/PASSED/FAILED labels, and animation

### Implementation for User Story 2

- [ ] **T026** [US2] Update `tc_status_update()` in `status-line.sh` to add emoji prefix (🚁)
- [ ] **T027** [US2] Update `tc_status_update()` in `status-line.sh` to add colored status labels (use tc_ansi_color)
- [ ] **T028** [US2] Update `tc_status_update()` in `status-line.sh` to format as: `emoji : COLOR_LABEL : info : animation`
- [ ] **T029** [US2] Implement animation state in `status-line.sh` (frame counter, spinner array)
- [ ] **T030** [US2] Implement `tc_animate_dots()` or `tc_next_spinner()` function in `status-line.sh`
- [ ] **T031** [US2] Update `tc_status_update()` to append animation to rightmost portion of line
- [ ] **T032** [US2] Implement terminal width handling in `tc_status_update()` (truncate long suite names with ...)

### Testing for User Story 2

- [ ] **T033** [US2] Add test scenario: verify emoji prefix appears in status line
- [ ] **T034** [US2] Add test scenario: verify RUNNING shows yellow, PASSED shows green, FAILED shows red
- [ ] **T035** [US2] Add test scenario: verify animation advances on each update
- [ ] **T036** [US2] Run `tc run tc/tests/integration/heli-output` to validate User Story 2

**Checkpoint**: User Story 2 complete - visual indicators and colors working

---

## Phase 5: User Story 4 - Graceful Non-TTY Fallback (Priority: P2)

**Goal**: Clean line-oriented plain text output when stdout is not a TTY (CI/CD compatibility)

**Independent Test**: Run `tc run tests --all > output.txt` and verify plain text without ANSI codes

### Implementation for User Story 4

- [ ] **T037** [US4] Update `tc_status_init()` in `status-line.sh` to detect non-TTY mode ([ -t 1 ])
- [ ] **T038** [US4] Update `tc_status_update()` in `status-line.sh` to use plain ASCII in non-TTY mode
- [ ] **T039** [US4] Update `tc_status_update()` in `status-line.sh` to output new line (not CR) in non-TTY mode
- [ ] **T040** [US4] Update `tc_ansi_supported()` in `ansi.sh` to return false for non-TTY
- [ ] **T041** [US4] Ensure NO_COLOR environment variable disables all ANSI codes

### Testing for User Story 4

- [ ] **T042** [US4] Add test scenario: verify non-TTY produces line-oriented output (pipe to file)
- [ ] **T043** [US4] Add test scenario: verify no ANSI escape codes in non-TTY output (grep for ESC)
- [ ] **T044** [US4] Add test scenario: verify NO_COLOR env var disables colors
- [ ] **T045** [US4] Run non-TTY tests: `tc run tc/tests/integration/heli-output > /tmp/output.txt 2>&1`

**Checkpoint**: User Story 4 complete - non-TTY fallback working for CI/CD

---

## Phase 6: User Story 3 - Machine-Readable Detailed Logs (Priority: P3)

**Goal**: JSONL log files with detailed test execution data for analysis and debugging

**Independent Test**: Verify logs written to `.tc-reports/report.jsonl` and parseable with jq

### Implementation for User Story 3

- [ ] **T046** [US3] Create `tc/lib/utils/log-writer.sh` file structure
- [ ] **T047** [US3] Implement `tc_log_init()` function in `log-writer.sh` (create .tc-reports/ dir)
- [ ] **T048** [US3] Implement `tc_log_write(suite_path, test_name, status, duration_ms, error?)` in `log-writer.sh`
- [ ] **T049** [US3] Implement `tc_log_get_path()` function in `log-writer.sh` (returns log file path)
- [ ] **T050** [US3] Implement JSON timestamp formatting (ISO 8601) in `log-writer.sh`
- [ ] **T051** [US3] Implement JSONL append logic in `log-writer.sh` (one JSON object per line)
- [ ] **T052** [US3] Add log-writer.sh module to tc/bin/tc: `source "$TC_ROOT/lib/utils/log-writer.sh"`
- [ ] **T053** [US3] Update `tc/lib/core/executor.sh` to call `tc_log_init()` at start
- [ ] **T054** [US3] Update `tc/lib/core/executor.sh` to call `tc_log_write()` after each test execution
- [ ] **T055** [US3] Handle optional error parameter in `tc_log_write()` for failed tests

### Testing for User Story 3

- [ ] **T056** [US3] Add test scenario: verify `.tc-reports/report.jsonl` file is created
- [ ] **T057** [US3] Add test scenario: verify each test produces one JSONL entry
- [ ] **T058** [US3] Add test scenario: verify log entries include required fields (timestamp, suite_path, test_name, status, duration_ms)
- [ ] **T059** [US3] Add test scenario: verify log is parseable with jq: `jq '.' .tc-reports/report.jsonl`
- [ ] **T060** [US3] Add test scenario: verify log file appends (run tests twice, check entry count)
- [ ] **T061** [US3] Run `tc run tc/tests/integration/heli-output` to validate User Story 3

**Checkpoint**: User Story 3 complete - JSONL logging working

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, edge cases, documentation, cleanup

- [ ] **T062** [P] Handle edge case: terminal width < 40 chars (truncate gracefully)
- [ ] **T063** [P] Handle edge case: very long suite names (truncate with ellipsis)
- [ ] **T064** [P] Handle edge case: TERM=dumb (fallback to plain ASCII)
- [ ] **T065** [P] Add inline code comments to ansi.sh explaining ANSI codes
- [ ] **T066** [P] Add inline code comments to status-line.sh explaining state management
- [ ] **T067** [P] Add inline code comments to log-writer.sh explaining JSONL format
- [ ] **T068** Test all terminal emulators: bash, zsh, tmux, screen, vscode terminal
- [ ] **T069** [P] Run full regression: `tc run tests --all` (all TC tests, not just heli-output)
- [ ] **T070** [P] Run examples: `tc run examples --all`
- [ ] **T071** Verify no performance regression: test execution time should be within 10% of baseline
- [ ] **T072** Create example in quickstart.md showing JSONL log analysis with jq
- [ ] **T073** Update main README.md to mention fancy output feature (optional section)
- [ ] **T074** Final validation: compare current output vs baseline (visual and functional)

**Checkpoint**: Polish complete, all edge cases handled, ready for PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase
  - User Story 1 (P1) - Can start immediately after Foundational
  - User Story 2 (P2) - Depends on User Story 1 (builds on status line)
  - User Story 4 (P2) - Can run in parallel with User Story 2 (independent)
  - User Story 3 (P3) - Independent of US1/US2/US4 (can run in parallel if desired)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundation only - implements basic status line
- **User Story 2 (P2)**: **Depends on US1** - enhances status line with colors/emoji/animation
- **User Story 3 (P3)**: Independent - adds logging orthogonally
- **User Story 4 (P2)**: **Depends on US1** - adds non-TTY behavior to status line

### Within Each User Story

- **US1**: Tasks must run sequentially (building up status-line.sh functionality)
- **US2**: Tasks must run sequentially (enhancing US1 implementation)
- **US3**: Tasks can be mostly sequential (building up log-writer.sh)
- **US4**: Tasks must run sequentially (modifying US1 behavior)

### Parallel Opportunities

**Phase 1 (Setup)**:
```bash
# Can run in parallel:
T002: Git commit (baseline checkpoint)
T003: Capture baseline test output
```

**Phase 2 (Foundational)**:
```bash
# Can run in parallel after T004-T007 complete:
T008: Implement cursor hide/show functions
```

**Phase 3 (User Story 1) - Sequential** - each task builds on previous

**Phase 4 (User Story 2) - Sequential** - each task enhances US1

**Phase 5 (User Story 4) - Sequential** - each task modifies US1

**Phase 6 (User Story 3) - Mostly Sequential**:
```bash
# Can run in parallel (different concerns):
T046-T052: Build log-writer.sh module (file operations)
T053-T055: Integrate into executor.sh (when log-writer.sh ready)
```

**Phase 7 (Polish)**:
```bash
# Can run in parallel (independent concerns):
T062: Handle terminal width edge case
T063: Handle long suite names edge case
T064: Handle TERM=dumb edge case
T065-T067: Add documentation comments (different files)
T069: Run regression tests
T070: Run examples
```

---

## Parallel Example: Foundational Phase

```bash
# Sequential prerequisite:
Task: "Create ansi.sh with color constants and basic functions (T004)"
Task: "Implement TTY/ANSI detection (T005)"
Task: "Implement color functions (T006)"
Task: "Implement clear line function (T007)"

# Then in parallel:
Task: "Implement cursor control functions (T008)"
```

---

## Parallel Example: User Story 3 (Logging)

```bash
# Build log-writer module:
Task: "Create log-writer.sh structure (T046)"
Task: "Implement tc_log_init() (T047)"
Task: "Implement tc_log_write() (T048)"
Task: "Implement tc_log_get_path() (T049)"
Task: "Implement timestamp formatting (T050)"
Task: "Implement JSONL append (T051)"
Task: "Add to tc/bin/tc (T052)"

# Once module ready, integrate:
Task: "Call tc_log_init() in executor.sh (T053)"
Task: "Call tc_log_write() in executor.sh (T054)"
Task: "Handle error parameter (T055)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (3 tasks)
2. Complete Phase 2: Foundational (8 tasks)
3. Complete Phase 3: User Story 1 (14 tasks)
4. **STOP and VALIDATE**: Test single-line status updates work in TTY
5. If validation passes, commit with message describing MVP completion

**At this point, you have a working single-line animated status line - MVP COMPLETE!**

### Incremental Delivery

1. After MVP (US1): Add User Story 2 → Visual indicators (colors, emoji, animation)
2. After US2: Add User Story 4 → Non-TTY fallback (CI/CD compatibility) - can run parallel with US3
3. After US4: Add User Story 3 → JSONL logging (analysis/debugging feature) - can run parallel with US4
4. After all stories: Add Polish → Edge cases and documentation
5. Final validation → Production ready

### Sequential Execution (Recommended for Solo Developer)

Complete phases in order: 1 → 2 → 3 → 4 → 5 → 6 → 7

Critical path: T001 → T004 → T012 → T018 → T026 → T037 → T046 (builds up feature incrementally)

### Parallel Team Strategy

This feature is primarily sequential due to file dependencies, but opportunities exist:

1. **After Foundational Phase**:
   - Developer A: Implement User Story 1 (basic status line)
   - Developer B: Build User Story 3 (logging module) in parallel
2. **After US1 Complete**:
   - Developer A: Add User Story 2 (visual enhancements)
   - Developer C: Add User Story 4 (non-TTY fallback)
3. **Integration**: Bring work together, test, polish

---

## Validation Checkpoints

### After Foundational (Phase 2)
- [ ] `tc/lib/utils/ansi.sh` exists and is sourced
- [ ] TTY detection works: `[ -t 1 ] && echo "TTY" || echo "not TTY"`
- [ ] Color functions work: `echo "$(tc_ansi_color green)PASS$(tc_ansi_color reset)"`
- [ ] Config vars exist: `echo $TC_FANCY_OUTPUT $TC_REPORT_DIR`

### After User Story 1 (Phase 3)
- [ ] `tc/lib/utils/status-line.sh` exists and is sourced
- [ ] `tc run tests --all` shows single-line updating status (not scrolling)
- [ ] Status line updates in place without creating new lines
- [ ] Final summary appears as clean multi-line output after tests complete

### After User Story 2 (Phase 4)
- [ ] Status line includes 🚁 emoji prefix
- [ ] RUNNING shows yellow, PASSED shows green, FAILED shows red
- [ ] Animation cycles through dots or spinner at end of line
- [ ] Status format is: `🚁 : COLOR_LABEL : suite/test : animation`

### After User Story 4 (Phase 5)
- [ ] `tc run tests --all > output.txt` produces plain text (no ANSI codes)
- [ ] Non-TTY output is line-oriented (new line per update, not in-place)
- [ ] `grep -c '\033' output.txt` returns 0 (no escape codes)
- [ ] NO_COLOR=1 disables all colors

### After User Story 3 (Phase 6)
- [ ] `.tc-reports/report.jsonl` file exists after test run
- [ ] Each test produces one JSONL entry with required fields
- [ ] `jq '.' .tc-reports/report.jsonl` parses without errors
- [ ] Multiple test runs append to same file (entry count grows)
- [ ] Failed tests include error field in JSON

### After Polish (Phase 7)
- [ ] All edge cases handled (narrow terminals, long names, dumb term)
- [ ] All code has inline comments
- [ ] All terminal emulators tested and working
- [ ] Performance within 10% of baseline
- [ ] Documentation updated
- [ ] Ready for PR and merge

---

## Task Count Summary

- **Total Tasks**: 74
- **Setup (Phase 1)**: 3 tasks
- **Foundational (Phase 2)**: 8 tasks (CRITICAL - blocks all stories)
- **User Story 1 (Phase 3)**: 14 tasks (MVP - basic status line)
- **User Story 2 (Phase 4)**: 11 tasks (visual enhancements)
- **User Story 4 (Phase 5)**: 9 tasks (non-TTY fallback)
- **User Story 3 (Phase 6)**: 16 tasks (JSONL logging)
- **Polish (Phase 7)**: 13 tasks (edge cases and docs)

**Parallel Opportunities**: 12 tasks marked [P] (16% of total)

**MVP Scope**: Phases 1-3 (25 tasks) deliver working single-line status updates

**Suggested Approach**: Complete through User Story 1 (Phase 3), validate, then continue with enhancements

---

**Status**: Ready for implementation via `/speckit.implement`
**Next**: Execute tasks sequentially, validate at each checkpoint, commit when stable
