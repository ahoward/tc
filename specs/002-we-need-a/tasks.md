# Tasks: Test Suite Generator

**Input**: Design documents from `/specs/002-we-need-a/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/template-format.md

**Feature**: `tc new` command for generating test suite scaffolding
**Tech Stack**: Bash 4.0+ (POSIX-compatible), jq, tc framework
**Organization**: Tasks grouped by user story for independent implementation

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and template files needed by all user stories

- [x] T001 Create lib/templates/ directory structure
- [x] T002 Create lib/templates/default/ directory for built-in template
- [x] T003 [P] Create lib/templates/default/run.template with NOT_IMPLEMENTED error pattern
- [x] T004 [P] Create lib/templates/default/README.template with AI-friendly metadata format
- [x] T005 [P] Create lib/templates/default/input.template with example JSON structure
- [x] T006 [P] Create lib/templates/default/expected.template with example JSON structure

**Checkpoint**: Template files ready for use by generator

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core generator infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Create lib/core/generator.sh with core generation functions
- [x] T008 Implement tc_validate_test_name() in lib/core/generator.sh (regex: `^[a-z0-9][a-z0-9-]*[a-z0-9]$`)
- [x] T009 Implement tc_parse_test_path() in lib/core/generator.sh (extract test_name, parent_dir, run_when)
- [x] T010 Implement tc_check_path_exists() in lib/core/generator.sh (check conflicts, --force handling)
- [x] T011 Implement tc_create_directory_structure() in lib/core/generator.sh (mkdir -p with validation)
- [x] T012 Implement tc_set_executable_permission() in lib/core/generator.sh (chmod +x run script)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Quick Test Scaffolding (Priority: P1) 🎯 MVP

**Goal**: Implement basic `tc new <test-path>` command that generates complete failing test suite

**Independent Test**: Run `tc new tests/my-feature`, verify directory structure created, run `tc run tests/my-feature`, verify NOT_IMPLEMENTED error shown

### Implementation for User Story 1

- [x] T013 [US1] Implement tc_generate_from_template() in lib/core/generator.sh
- [x] T014 [US1] Implement variable substitution for TEST_NAME, TEST_PATH, TIMESTAMP in lib/core/generator.sh
- [x] T015 [US1] Implement tc_generate_run_script() in lib/core/generator.sh (process run.template)
- [x] T016 [US1] Implement tc_generate_readme() in lib/core/generator.sh (process README.template with default metadata)
- [x] T017 [US1] Implement tc_generate_data_files() in lib/core/generator.sh (create data/example-scenario/ with input/expected.json)
- [x] T018 [US1] Implement tc_display_success_message() in lib/core/generator.sh (tree view + next steps)
- [x] T019 [US1] Add "new" command handler to bin/tc (parse <test-path> argument, call generator)
- [x] T020 [US1] Add basic error handling in bin/tc for invalid paths, permission denied, path exists

**Checkpoint**: Basic `tc new tests/my-feature` works, creates failing test with clear guidance

---

## Phase 4: User Story 2 - Guided Test Creation with Metadata (Priority: P2)

**Goal**: Support optional flags (--tags, --priority, --description, --depends) for AI-friendly metadata

**Independent Test**: Run `tc new tests/auth/login --tags "auth,api" --priority high`, verify README.md contains custom metadata, verify `tc list` shows new test with tags

### Implementation for User Story 2

- [x] T021 [US2] Implement tc_parse_optional_flags() in lib/core/generator.sh (parse --tags, --priority, --description, --depends)
- [x] T022 [US2] Implement tc_format_tags_for_readme() in lib/core/generator.sh (convert comma-separated to backtick-wrapped)
- [x] T023 [US2] Implement tc_build_template_variables() in lib/core/generator.sh (assemble all variables with defaults)
- [x] T024 [US2] Update tc_generate_readme() in lib/core/generator.sh to use custom DESCRIPTION, TAGS, PRIORITY, DEPENDENCIES variables
- [x] T025 [US2] Update "new" command handler in bin/tc to parse and pass optional flags
- [x] T026 [US2] Add --help flag to "new" command in bin/tc showing all available options

**Checkpoint**: `tc new` with flags works, generated tests integrate with `tc list`, `tc explain`, `tc tags`

---

## Phase 5: User Story 3 - Example-Based Generation (Priority: P3)

**Goal**: Support --from flag to copy structure from existing examples, and --list-examples flag

**Independent Test**: Run `tc new --list-examples`, verify examples shown, run `tc new tests/my-calc --from hello-world`, verify structure copied with names customized

### Implementation for User Story 3

- [ ] T027 [US3] Create lib/core/templates.sh for template discovery and management
- [ ] T028 [US3] Implement tc_discover_templates() in lib/core/templates.sh (find built-in + examples)
- [ ] T029 [US3] Implement tc_list_templates() in lib/core/templates.sh (format output for --list-examples)
- [ ] T030 [US3] Implement tc_validate_template_exists() in lib/core/templates.sh (check if template exists)
- [ ] T031 [US3] Implement tc_load_template_files() in lib/core/templates.sh (read template files, detect if heredoc or file-based)
- [ ] T032 [US3] Update tc_generate_from_template() in lib/core/generator.sh to support template parameter
- [ ] T033 [US3] Add --from flag parsing to "new" command in bin/tc
- [ ] T034 [US3] Add --list-examples command handler to bin/tc (call tc_list_templates)
- [ ] T035 [US3] Source lib/core/templates.sh in bin/tc

**Checkpoint**: Template discovery works, --from flag generates from examples, --list-examples shows available templates

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Refinements affecting multiple user stories

- [ ] T036 [P] Add comprehensive error messages for all validation failures (invalid names, permissions, etc.)
- [ ] T037 [P] Ensure all generated files use UTF-8 encoding and LF line endings
- [ ] T038 Add --force flag handling throughout generator (allow overwrite existing directories)
- [ ] T039 [P] Validate generated JSON files are valid JSON (parse with jq after creation)
- [ ] T040 [P] Verify generated README.md passes tc_extract_metadata() parser
- [ ] T041 Add repository root detection (walk up for .git or bin/tc)
- [ ] T042 [P] Document usage in docs/ (link to specs/002-we-need-a/quickstart.md)
- [ ] T043 Performance validation: ensure generation completes in <10 seconds
- [ ] T044 Test nested path creation (e.g., `tests/api/v2/auth/login`)
- [ ] T045 Test edge cases: existing directory, invalid names, permission denied, empty path

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 but can be tested independently
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends US1/US2 but can be tested independently

### Within Each Phase

**Phase 1 (Setup)**:
- T001, T002 must complete before T003-T006
- T003, T004, T005, T006 are [P] - can run in parallel

**Phase 2 (Foundational)**:
- T007 must complete first
- T008-T012 depend on T007 but can run sequentially

**Phase 3 (User Story 1)**:
- T013 depends on Phase 2 completion
- T014-T017 depend on T013
- T015, T016, T017 can be developed in parallel after T013/T014
- T018 can be done in parallel with T015-T017
- T019 depends on T015-T018
- T020 depends on T019

**Phase 4 (User Story 2)**:
- T021-T023 can start after Phase 2 (independent of US1 implementation details)
- T024 depends on T021-T023 and T016 (from US1)
- T025-T026 depend on T024

**Phase 5 (User Story 3)**:
- T027-T028 can start after Phase 2
- T029-T031 depend on T028
- T032 depends on T031 and T013 (from US1)
- T033-T035 depend on T032

**Phase 6 (Polish)**:
- T036, T037, T039, T040, T042 are [P] - can run in parallel
- T038 depends on generator completion
- T041 can run in parallel
- T043-T045 are validation tasks, run after all implementations

### Parallel Opportunities

- **Phase 1**: T003, T004, T005, T006 (all template files)
- **Phase 3**: T015, T016, T017, T018 (different generation functions)
- **Phase 6**: T036, T037, T039, T040, T042 (documentation and validation)
- **Across User Stories**: US2 and US3 can be developed in parallel after US1 completes

---

## Parallel Example: Phase 1 (Setup)

```bash
# Launch all template file creation in parallel:
Task: "Create lib/templates/default/run.template with NOT_IMPLEMENTED error pattern"
Task: "Create lib/templates/default/README.template with AI-friendly metadata format"
Task: "Create lib/templates/default/input.template with example JSON structure"
Task: "Create lib/templates/default/expected.template with example JSON structure"
```

---

## Parallel Example: Phase 6 (Polish)

```bash
# Launch documentation and validation in parallel:
Task: "Add comprehensive error messages for all validation failures"
Task: "Ensure all generated files use UTF-8 encoding and LF line endings"
Task: "Validate generated JSON files are valid JSON (parse with jq)"
Task: "Verify generated README.md passes tc_extract_metadata() parser"
Task: "Document usage in docs/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (template files)
2. Complete Phase 2: Foundational (core generator functions)
3. Complete Phase 3: User Story 1 (basic `tc new` command)
4. **STOP and VALIDATE**:
   - Run `tc new tests/example`
   - Verify structure created
   - Run `tc run tests/example`
   - Verify NOT_IMPLEMENTED error shows clear guidance
5. Deploy/demo MVP - developers can now generate test scaffolding

### Incremental Delivery

1. **Setup + Foundational** → Foundation ready (template files + core generator)
2. **Add User Story 1** → Test independently → Deploy/Demo (MVP! Basic generation works)
3. **Add User Story 2** → Test independently → Deploy/Demo (Metadata integration works)
4. **Add User Story 3** → Test independently → Deploy/Demo (Example-based generation works)
5. **Add Polish** → Final validation → Production ready

### Parallel Team Strategy

With multiple developers:

1. **Team completes Setup + Foundational together** (critical path)
2. **Once Foundational is done:**
   - Developer A: User Story 1 (T013-T020)
   - Developer B: User Story 2 (T021-T026) - can start structure in parallel
   - Developer C: User Story 3 (T027-T035) - can start structure in parallel
3. Integration points:
   - US2 integrates with US1's README generation
   - US3 integrates with US1's template processing
4. **Polish phase**: Divide T036-T045 among team

---

## Task Count Summary

- **Phase 1 (Setup)**: 6 tasks
- **Phase 2 (Foundational)**: 6 tasks
- **Phase 3 (US1 - MVP)**: 8 tasks
- **Phase 4 (US2)**: 6 tasks
- **Phase 5 (US3)**: 9 tasks
- **Phase 6 (Polish)**: 10 tasks

**Total**: 45 tasks

**By User Story**:
- Setup/Foundational: 12 tasks (shared infrastructure)
- User Story 1: 8 tasks
- User Story 2: 6 tasks
- User Story 3: 9 tasks
- Polish: 10 tasks

**Parallelizable Tasks**: 11 tasks marked [P]

---

## Notes

- **No test tasks**: Feature spec doesn't explicitly request TDD approach. Dogfooding (tc testing tc) mentioned in plan.md but not as required implementation tasks.
- **[P] tasks**: Different files, no dependencies - can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- **Each user story independently testable**:
  - US1: Basic generation works standalone
  - US2: Metadata flags work, integrates with existing tc commands
  - US3: Template discovery and --from flag work
- **MVP scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = 20 tasks
- **Commit strategy**: Commit after each logical task group (e.g., all template files, each generator function)
- **Validation checkpoints**: After each phase, run manual tests per "Independent Test" criteria
- **Template contract**: All template files must follow contracts/template-format.md specification
- **File paths**: All paths are relative to repository root (/home/drawohara/gh/ahoward/tc/)
- **Bash style**: POSIX-compatible, no bashisms, follows existing tc code style
- **Error handling**: Use tc_error() and tc_log() functions from existing tc codebase
- **Performance goal**: <10 seconds for complete generation (validated in T043)
