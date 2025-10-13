# Tasks: TC Source Layout Refactoring

**Input**: Design documents from `/specs/003-refactor-tc-source/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: This is a refactoring - existing test suites serve as regression tests. No new test tasks needed.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- Current structure: `bin/tc`, `lib/`, `tests/`
- Target structure: `tc/tc`, `tc/lib/`, `tc/tests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and prepare for refactoring

- [x] T001 Create new directory structure: `mkdir -p tc/lib/{core,utils} tc/tests/{unit,integration}`
- [x] T002 [P] Backup current structure: Create git commit with message "pre-refactor checkpoint"
- [x] T003 [P] Run baseline tests: `tc run tests --all` to capture pre-refactor results

**Checkpoint**: Baseline established, safe to proceed with refactoring

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core path resolution and library loading infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Move CLI entry point: `git mv bin/tc tc/tc`
- [x] T005 Update TC_ROOT calculation in `tc/tc` (line ~12): Remove `/../` from path resolution
- [x] T006 Move global config: `git mv lib/config/defaults.sh tc/config.sh`
- [x] T007 Update config source path in `tc/tc` (line ~15): `source "$TC_ROOT/config.sh"`
- [x] T008 [P] Move core libraries: `git mv lib/core/*.sh tc/lib/core/`
- [x] T009 [P] Move utility libraries: `git mv lib/utils/*.sh tc/lib/utils/`
- [x] T010 Update all library source paths in `tc/tc` (lines 16-23): Change `lib/` → `tc/lib/`
- [x] T011 Make `tc/tc` executable: `chmod +x tc/tc`
- [x] T012 Remove old directories: `git rm -r bin/ lib/`

**Checkpoint**: Foundation ready - basic CLI functionality restored with new paths

---

## Phase 3: User Story 1 - Developer Uses Refactored CLI (Priority: P1) 🎯 MVP

**Goal**: All existing CLI functionality works identically with new structure

**Independent Test**: Run `tc --version`, `tc --help`, `tc run tests --all` - all should produce identical results to baseline

### Implementation for User Story 1

- [x] T013 [US1] Verify TC_ROOT detection: Test `./tc/tc --version` from repo root
- [x] T014 [US1] Verify library loading: Check for any "source: not found" errors
- [x] T015 [US1] Test `tc run` command: `tc run examples/hello-world`
- [~] T016 [US1] Test `tc run --all` command: `tc run tests --all` (blocked by T024 - tests need new paths)
- [x] T017 [US1] Test `tc new` command: `tc new /tmp/test-refactor-verify`
- [x] T018 [US1] Test `tc init` command: `tc init /tmp/test-init-verify`
- [x] T019 [US1] Test `tc list` command: `tc list tests`
- [x] T020 [US1] Test `tc tags` command: `tc tags tests`
- [x] T021 [US1] Test `tc explain` command: `tc explain tests/unit/json-comparison`
- [x] T022 [US1] Test parallel execution: `tc run tests --all --parallel`
- [~] T023 [US1] Compare results: Diff current test output vs baseline (T003) (deferred to Phase 7)

**Checkpoint**: User Story 1 complete - all CLI commands work identically to pre-refactor

---

## Phase 4: User Story 2 - Developer Navigates Source Code (Priority: P2)

**Goal**: Source code organization is clear and navigable

**Independent Test**: New contributor can locate CLI entry point (tc/tc) and config (tc/config.sh) in <10 seconds

### Implementation for User Story 2

- [ ] T024 [P] [US2] Move framework self-tests: `git mv tests/ tc/tests/`
- [ ] T025 [P] [US2] Update test discovery to exclude tc/tests from user test runs
- [ ] T026 [P] [US2] Update README.md: Replace all `bin/tc` references with `tc/tc`
- [ ] T027 [P] [US2] Update README.md: Replace all `lib/` references with `tc/lib/`
- [ ] T028 [P] [US2] Update README.md: Update installation instructions (3 methods)
- [ ] T029 [P] [US2] Update docs/readme.md: Replace path references
- [ ] T030 [P] [US2] Update docs/tc-new.md: Replace path references
- [ ] T031 [US2] Add code comments to `tc/tc`: Document TC_ROOT resolution logic
- [ ] T032 [US2] Add code comments to `tc/config.sh`: Document configuration hierarchy
- [ ] T033 [US2] Verify directory structure matches plan.md target layout

**Checkpoint**: User Story 2 complete - source organization clear, documentation updated

---

## Phase 5: User Story 3 - Test Suite Uses Custom Configuration (Priority: P3)

**Goal**: Test suites can optionally override global configuration

**Independent Test**: Create test suite with custom `config.sh`, verify settings override globals

### Implementation for User Story 3

- [ ] T034 [US3] Add suite config loading to `tc/lib/core/executor.sh`: Detect and source `$suite_dir/config.sh`
- [ ] T035 [US3] Update config loading to respect environment variables: Use `${VAR:=default}` syntax
- [ ] T036 [US3] Create example suite with custom config: `examples/custom-config/config.sh`
- [ ] T037 [US3] Test configuration precedence: Verify env > suite > global order
- [ ] T038 [US3] Test configuration isolation: Verify suite configs don't leak between tests
- [ ] T039 [US3] Document configuration hierarchy in `quickstart.md` (already created in planning)
- [ ] T040 [US3] Add config override examples to documentation

**Checkpoint**: User Story 3 complete - per-suite configuration working

---

## Phase 6: Installation Methods & Integration

**Purpose**: Validate all installation methods work with new structure

- [ ] T041 [P] Test PATH installation: `export PATH="$PWD/tc:$PATH" && tc --version`
- [ ] T042 [P] Test symlink installation: Create symlink to `/tmp/tc-test`, verify works
- [ ] T043 [P] Test copy installation: Copy `tc/` to `/tmp/tc-install`, verify works
- [ ] T044 Verify TC_ROOT resolution for each installation method
- [ ] T045 Create migration guide for existing installations (append to README.md)
- [ ] T046 Add troubleshooting section to quickstart.md (already exists)

**Checkpoint**: All installation methods validated

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, documentation polish

- [ ] T047 [P] Run full regression suite: `tc run tc/tests --all` and compare to baseline
- [ ] T048 [P] Validate examples still work: `tc run examples/hello-world`
- [ ] T049 Check for broken symlinks or orphaned files: `find . -xtype l`
- [ ] T050 Update CLAUDE.md: Add note about new structure (already done by agent script)
- [ ] T051 Verify .gitignore excludes appropriate files
- [ ] T052 Clean up any temporary test artifacts
- [ ] T053 [P] Review all documentation for consistency
- [ ] T054 [P] Update any internal path references in comments
- [ ] T055 Create upgrade guide for users (section in README.md)
- [ ] T056 Final validation: Run `tc --version && tc run tests --all && tc new /tmp/final-test`

**Checkpoint**: Refactoring complete, all tests passing, documentation current

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1) - Can start immediately after Foundational
  - User Story 2 (P2) - Can start immediately after Foundational (independent of US1)
  - User Story 3 (P3) - Can start immediately after Foundational (independent of US1, US2)
- **Installation Methods (Phase 6)**: Depends on User Story 1 completion (basic CLI must work)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends only on Foundational - Core functionality must work first
- **User Story 2 (P2)**: Independent of US1 - Just documentation and organization
- **User Story 3 (P3)**: Independent of US1 and US2 - Adds optional feature

### Within Each User Story

- **US1**: Tasks must run sequentially (all testing same functionality)
- **US2**: Most tasks are [P] (different documentation files)
- **US3**: Tasks must run sequentially (configuration loading logic)

### Parallel Opportunities

**Phase 1 (Setup)**:
```bash
# Can run in parallel:
T002: Backup current structure
T003: Run baseline tests
```

**Phase 2 (Foundational)**:
```bash
# Can run in parallel after T004-T007 complete:
T008: Move core libraries
T009: Move utility libraries
```

**Phase 4 (User Story 2)**:
```bash
# Can run in parallel:
T024: Move framework self-tests
T025: Update test discovery
T026-T030: All documentation updates (different files)
```

**Phase 6 (Installation Methods)**:
```bash
# Can run in parallel:
T041: Test PATH installation
T042: Test symlink installation
T043: Test copy installation
```

**Phase 7 (Polish)**:
```bash
# Can run in parallel:
T047: Run regression suite
T048: Validate examples
T053: Review documentation
T054: Update internal comments
```

---

## Parallel Example: User Story 2 (Documentation Updates)

```bash
# Launch all documentation tasks together:
Task: "Update README.md: Replace all `bin/tc` references with `tc/tc`"
Task: "Update README.md: Replace all `lib/` references with `tc/lib/`"
Task: "Update README.md: Update installation instructions"
Task: "Update docs/readme.md: Replace path references"
Task: "Update docs/tc-new.md: Replace path references"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (establish baseline) - 3 tasks
2. Complete Phase 2: Foundational (move files, update paths) - 9 tasks
3. Complete Phase 3: User Story 1 (verify all commands work) - 11 tasks
4. **STOP and VALIDATE**: Compare results to baseline, ensure zero regressions
5. If validation passes, commit with message describing successful refactoring

**At this point, the refactoring is functionally complete. P2 and P3 are polish/enhancements.**

### Incremental Delivery

1. Complete Setup + Foundational → Core structure in place
2. Add User Story 1 → Test independently → **MVP COMPLETE** (CLI works)
3. Add User Story 2 → Documentation updated → More maintainable
4. Add User Story 3 → Config overrides added → Power user feature
5. Add Installation Methods → Verified across all use cases
6. Add Polish → Production ready

### Sequential Execution (Recommended for Solo Developer)

Complete phases in order: 1 → 2 → 3 → 4 → 5 → 6 → 7

Critical path: T001 → T004 → T005 → ... → T023 (User Story 1 complete)

### Parallel Team Strategy

This refactoring is primarily sequential due to file movements, but opportunities exist:

1. **Setup Phase**: One developer can run baseline while another prepares structure
2. **After Foundational**:
   - Developer A: Verify CLI functionality (US1)
   - Developer B: Update documentation (US2)
   - Developer C: Implement config overrides (US3)
3. **Integration**: Bring work together, validate, polish

---

## Validation Checkpoints

### After Foundational (Phase 2)
- [ ] `tc/tc` executable exists and has correct permissions
- [ ] `tc/config.sh` exists and is readable
- [ ] All library files exist in `tc/lib/core/` and `tc/lib/utils/`
- [ ] No "source: not found" errors when running `tc --version`

### After User Story 1 (Phase 3)
- [ ] `tc --version` displays version correctly
- [ ] `tc --help` displays help correctly
- [ ] `tc run tests --all` passes all tests
- [ ] Test results identical to baseline (T003 output)
- [ ] All commands (`run`, `new`, `init`, `list`, `tags`, `explain`) work

### After User Story 2 (Phase 4)
- [ ] Framework tests moved to `tc/tests/`
- [ ] All documentation references updated
- [ ] README installation instructions accurate
- [ ] New contributor can locate entry point quickly

### After User Story 3 (Phase 5)
- [ ] Suite-specific `config.sh` files load correctly
- [ ] Configuration precedence works (env > suite > global)
- [ ] Configuration isolation prevents cross-suite leakage
- [ ] Documentation explains configuration hierarchy

### After Installation Methods (Phase 6)
- [ ] PATH installation works
- [ ] Symlink installation works
- [ ] Copy installation works
- [ ] TC_ROOT resolves correctly for all methods

### Final Validation (Phase 7)
- [ ] Full regression suite passes
- [ ] Examples work without modification
- [ ] No broken symlinks or orphaned files
- [ ] Documentation complete and accurate
- [ ] Ready for PR and merge to main

---

## Regression Testing Strategy

**Baseline Capture** (T003):
```bash
tc run tests --all > /tmp/tc-baseline-output.txt 2>&1
tc run examples/hello-world >> /tmp/tc-baseline-output.txt 2>&1
```

**Post-Refactor Validation** (T023, T047):
```bash
tc run tests --all > /tmp/tc-refactored-output.txt 2>&1
tc run examples/hello-world >> /tmp/tc-refactored-output.txt 2>&1

# Compare (should be identical except timestamps and paths)
diff /tmp/tc-baseline-output.txt /tmp/tc-refactored-output.txt
```

**Acceptance Criteria**:
- All tests that passed before refactoring still pass
- All tests that failed before refactoring still fail identically
- Test results are byte-identical (excluding timestamps, absolute paths)

---

## Notes

- **No test generation tasks**: This is a refactoring, existing tests are the validation
- **[P] tasks**: Different files, no dependencies - safe to parallelize
- **[Story] labels**: Map tasks to user stories for traceability
- **Git operations**: Use `git mv` to preserve file history
- **Checkpoints**: Validate at each phase boundary before proceeding
- **Rollback safety**: Baseline commit (T002) enables easy rollback if needed
- **Breaking changes**: Zero breaking changes - this is pure internal refactoring

---

## Task Count Summary

- **Total Tasks**: 56
- **Setup (Phase 1)**: 3 tasks
- **Foundational (Phase 2)**: 9 tasks (CRITICAL - blocks all stories)
- **User Story 1 (Phase 3)**: 11 tasks (MVP - core functionality)
- **User Story 2 (Phase 4)**: 10 tasks (documentation and organization)
- **User Story 3 (Phase 5)**: 7 tasks (optional configuration feature)
- **Installation Methods (Phase 6)**: 6 tasks (validation)
- **Polish (Phase 7)**: 10 tasks (final validation and cleanup)

**Parallel Opportunities**: 21 tasks marked [P] (37.5% of total)

**MVP Scope**: Phases 1-3 (23 tasks) deliver fully functional refactored CLI

**Suggested MVP**: Complete through User Story 1 (Phase 3), validate, then continue

---

**Status**: Ready for implementation via `/speckit.implement`
**Next**: Execute tasks sequentially, validate at each checkpoint, commit when stable
