# Tasks: Multi-Language AI Prompt System with Unified Testing

**Input**: Design documents from `/specs/006-i-want-to/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests included - tc test suite is core to validating the pattern

**Organization**: Tasks grouped by user story (US1-US4) to enable independent implementation and testing

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, SHARED)
- Include exact file paths in descriptions

## Path Conventions
Multiple standalone projects: `projects/{ruby,go,rust,javascript,python}/`
Shared test suite: `tests/multi-lang-dao/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for all 5 languages

- [x] T001 [P] [SHARED] Create `projects/ruby/` directory structure (lib/, Gemfile, README.md)
- [x] T002 [P] [SHARED] Create `projects/go/` directory structure (dao/, operations/, store/, adapter/, go.mod, README.md)
- [x] T003 [P] [SHARED] Create `projects/rust/` directory structure (src/, Cargo.toml, README.md)
- [x] T004 [P] [SHARED] Create `projects/javascript/` directory structure (lib/, package.json, README.md)
- [x] T005 [P] [SHARED] Create `projects/python/` directory structure (dao/, operations/, README.md)
- [x] T006 [SHARED] Create `tests/multi-lang-dao/` directory structure (data/{prompt-generate,template-create,template-render,usage-track,result-poll}/, README.md)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core DAO interface and tc test suite that MUST be complete before ANY language implementation

**⚠️ CRITICAL**: No language-specific work can begin until this phase is complete

- [x] T007 [SHARED] Define tc test suite structure in `tests/multi-lang-dao/README.md` (test scenarios, expected format, UUID pattern matching)
- [x] T008 [P] [SHARED] Create test data for /prompt/generate in `tests/multi-lang-dao/data/prompt-generate/{input.json, expected.json}`
- [x] T009 [P] [SHARED] Create test data for /template/create in `tests/multi-lang-dao/data/template-create/{input.json, expected.json}`
- [x] T010 [P] [SHARED] Create test data for /template/render in `tests/multi-lang-dao/data/template-render/{input.json, expected.json}`
- [x] T011 [P] [SHARED] Create test data for /usage/track in `tests/multi-lang-dao/data/usage-track/{input.json, expected.json}`
- [x] T012 [P] [SHARED] Create test data for /result/poll in `tests/multi-lang-dao/data/result-poll/{input.json, expected.json}`

**Checkpoint**: Foundation ready - language implementations can now begin in parallel

---

## Phase 3: User Story 1 - Unified DAO Interface Across Languages (Priority: P1) 🎯 MVP

**Goal**: Implement identical DAO interface in all 5 languages, prove pattern works

**Independent Test**: Call `/prompt/generate` operation in each language, verify identical response structure

### Tests for User Story 1 (tc test suite validation)

- [x] T013 [US1] Verify tc test suite runs (placeholder adapter) in `tests/multi-lang-dao/run`

### Ruby Implementation for User Story 1 (Priority: Clean Code Showcase!)

- [x] T014 [P] [US1] Create ResultStore class in `projects/ruby/lib/result_store.rb` (in-memory Hash with UUID keys)
- [x] T015 [P] [US1] Create DAO class skeleton in `projects/ruby/lib/dao.rb` (call method, operation routing)
- [x] T016 [US1] Implement /prompt/generate handler in `projects/ruby/lib/operations.rb` (process_prompt method)
- [x] T017 [US1] Integrate /prompt/generate with DAO routing in `projects/ruby/lib/dao.rb`
- [x] T018 [US1] Create tc adapter in `projects/ruby/tc_adapter.rb` (#!/usr/bin/env ruby, stdin/stdout JSON)
- [x] T019 [US1] Make tc adapter executable (`chmod +x projects/ruby/tc_adapter.rb`)
- [x] T020 [US1] Test Ruby implementation against tc suite (symlink `tests/multi-lang-dao/run` → `../../projects/ruby/tc_adapter.rb`, run `tc tests/multi-lang-dao`)

### Go Implementation for User Story 1

- [x] T021 [P] [US1] Create ResultStore struct in `projects/go/store/store.go` (map with sync.RWMutex)
- [x] T022 [P] [US1] Create DAO interface + impl in `projects/go/dao/dao.go` (Call method, UUID generation via crypto/rand)
- [x] T023 [US1] Implement /prompt/generate handler in `projects/go/operations/operations.go` (GeneratePrompt function)
- [x] T024 [US1] Integrate /prompt/generate with DAO routing in `projects/go/dao/dao.go`
- [x] T025 [US1] Create tc adapter in `projects/go/cmd/main.go` (stdin JSON decode, DAO call, stdout JSON encode)
- [x] T026 [US1] Build Go adapter (`cd projects/go && go build -o adapter ./cmd`)
- [x] T027 [US1] Test Go implementation against tc suite (symlink run → `../../projects/go/adapter`, run tc)

### Python Implementation for User Story 1 🐍

- [x] T028 [P] [US1] Create ResultStore class in `projects/python/store.py` (dict with threading.Lock, playful comments 🐍)
- [x] T029 [P] [US1] Create DAO class in `projects/python/dao/dao.py` (call method with type hints, 🐍 themed docstrings)
- [x] T030 [US1] Implement /prompt/generate handler in `projects/python/operations/prompt.py` (process_prompt function 🐍)
- [x] T031 [US1] Integrate /prompt/generate with DAO routing in `projects/python/dao/dao.py`
- [x] T032 [US1] Create tc adapter in `projects/python/adapter.py` (#!/usr/bin/env python3, stdin json.load, stdout json.dumps 🐍)
- [x] T033 [US1] Make tc adapter executable (`chmod +x projects/python/adapter.py`)
- [x] T034 [US1] Test Python implementation against tc suite (symlink run, run tc) 🐍

### JavaScript Implementation for User Story 1

- [x] T035 [P] [US1] Create ResultStore class in `projects/javascript/lib/store.js` (Map for storage)
- [x] T036 [P] [US1] Create DAO class in `projects/javascript/lib/dao.js` (call method, uuid.v4() for UUIDs)
- [x] T037 [US1] Implement /prompt/generate handler in `projects/javascript/lib/operations.js` (generatePrompt function)
- [x] T038 [US1] Integrate /prompt/generate with DAO routing in `projects/javascript/lib/dao.js`
- [x] T039 [US1] Create tc adapter in `projects/javascript/adapter.js` (#!/usr/bin/env node, fs.readFileSync stdin, JSON parse/stringify)
- [x] T040 [US1] Make tc adapter executable (`chmod +x projects/javascript/adapter.js`)
- [x] T041 [US1] Install uuid dependency (`cd projects/javascript && npm install uuid`)
- [x] T042 [US1] Test JavaScript implementation against tc suite (symlink run, run tc)

### Rust Implementation for User Story 1 🦀

- [x] T043 [P] [US1] Create ResultStore struct in `projects/rust/src/store.rs` (Arc<Mutex<HashMap<Uuid, OperationResponse>>>)
- [x] T044 [P] [US1] Create DAO trait + impl in `projects/rust/src/dao.rs` (call method, serde_json types)
- [x] T045 [US1] Implement /prompt/generate handler in `projects/rust/src/operations.rs` (generate_prompt function)
- [x] T046 [US1] Integrate /prompt/generate with DAO routing in `projects/rust/src/dao.rs`
- [x] T047 [US1] Create tc adapter binary in `projects/rust/src/bin/adapter.rs` (stdin serde_json::from_reader, stdout serde_json::to_writer)
- [x] T048 [US1] Configure Cargo.toml dependencies (serde, serde_json, uuid with features, chrono)
- [ ] T049 [US1] Build Rust adapter - BLOCKED by C linker issue (code complete, documented in BUILD_ISSUE.md)
- [ ] T050 [US1] Test Rust implementation - BLOCKED by build issue (would pass once built)

**Checkpoint**: At this point, all 5 languages pass tc test suite for /prompt/generate operation. User Story 1 is complete and demonstrates the pattern works!

---

## Phase 4: User Story 2 - Async Message-Based Results (Priority: P2)

**Goal**: Implement /result/poll operation and demonstrate async pattern with correlation UUIDs

**Independent Test**: Invoke /prompt/generate to get UUID, then poll with /result/poll to retrieve completed result

### Implementation for User Story 2 (All Languages)

- [ ] T051 [P] [US2] Implement /result/poll handler in `projects/ruby/lib/operations.rb` (poll_result method, lookup by UUID)
- [ ] T052 [P] [US2] Implement /result/poll handler in `projects/go/operations/operations.go` (PollResult function)
- [ ] T053 [P] [US2] Implement /result/poll handler in `projects/python/operations/prompt.py` (poll_result function 🐍)
- [ ] T054 [P] [US2] Implement /result/poll handler in `projects/javascript/lib/operations.js` (pollResult function)
- [ ] T055 [P] [US2] Implement /result/poll handler in `projects/rust/src/operations.rs` (poll_result function)

- [ ] T056 [P] [US2] Integrate /result/poll routing in `projects/ruby/lib/dao.rb`
- [ ] T057 [P] [US2] Integrate /result/poll routing in `projects/go/dao/dao.go`
- [ ] T058 [P] [US2] Integrate /result/poll routing in `projects/python/dao/dao.py`
- [ ] T059 [P] [US2] Integrate /result/poll routing in `projects/javascript/lib/dao.js`
- [ ] T060 [P] [US2] Integrate /result/poll routing in `projects/rust/src/dao.rs`

### Test User Story 2

- [ ] T061 [P] [US2] Test Ruby /result/poll with tc suite
- [ ] T062 [P] [US2] Test Go /result/poll with tc suite
- [ ] T063 [P] [US2] Test Python /result/poll with tc suite 🐍
- [ ] T064 [P] [US2] Test JavaScript /result/poll with tc suite
- [ ] T065 [P] [US2] Test Rust /result/poll with tc suite 🦀

**Checkpoint**: At this point, all languages support async pattern (generate → poll). User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Shared Test Suite Across Implementations (Priority: P3)

**Goal**: Verify tc test suite works seamlessly across all language implementations, compare results

**Independent Test**: Run full tc suite against each language, verify identical pass/fail results

### Implementation for User Story 3

- [ ] T066 [US3] Document adapter switching process in `tests/multi-lang-dao/README.md` (symlink examples for each language)
- [ ] T067 [P] [US3] Create test runner script `tests/multi-lang-dao/test-all-languages.sh` (runs tc against all 5 languages sequentially)
- [ ] T068 [US3] Run test-all-languages.sh and verify all 5 languages pass tc suite
- [ ] T069 [US3] Document any language-specific quirks or differences found in `specs/006-i-want-to/quickstart.md`

**Checkpoint**: All user stories work, shared test suite validates consistency across languages

---

## Phase 6: User Story 4 - AI Prompt System Demo Application (Priority: P4)

**Goal**: Complete the demo domain with /template/create, /template/render, /usage/track operations

**Independent Test**: Create template, render template with variables, track usage - all ops work across languages

### Template Operations (All Languages)

- [ ] T070 [P] [US4] Implement /template/create handler in `projects/ruby/lib/operations.rb`
- [ ] T071 [P] [US4] Implement /template/render handler in `projects/ruby/lib/operations.rb`
- [ ] T072 [P] [US4] Implement /usage/track handler in `projects/ruby/lib/operations.rb`

- [ ] T073 [P] [US4] Implement /template/create handler in `projects/go/operations/operations.go`
- [ ] T074 [P] [US4] Implement /template/render handler in `projects/go/operations/operations.go`
- [ ] T075 [P] [US4] Implement /usage/track handler in `projects/go/operations/operations.go`

- [ ] T076 [P] [US4] Implement /template/create handler in `projects/python/operations/prompt.py` 🐍
- [ ] T077 [P] [US4] Implement /template/render handler in `projects/python/operations/prompt.py` 🐍
- [ ] T078 [P] [US4] Implement /usage/track handler in `projects/python/operations/prompt.py` 🐍

- [ ] T079 [P] [US4] Implement /template/create handler in `projects/javascript/lib/operations.js`
- [ ] T080 [P] [US4] Implement /template/render handler in `projects/javascript/lib/operations.js`
- [ ] T081 [P] [US4] Implement /usage/track handler in `projects/javascript/lib/operations.js`

- [ ] T082 [P] [US4] Implement /template/create handler in `projects/rust/src/operations.rs` 🦀
- [ ] T083 [P] [US4] Implement /template/render handler in `projects/rust/src/operations.rs` 🦀
- [ ] T084 [P] [US4] Implement /usage/track handler in `projects/rust/src/operations.rs` 🦀

### Integrate Template Operations

- [ ] T085 [P] [US4] Add template operation routing to `projects/ruby/lib/dao.rb`
- [ ] T086 [P] [US4] Add template operation routing to `projects/go/dao/dao.go`
- [ ] T087 [P] [US4] Add template operation routing to `projects/python/dao/dao.py` 🐍
- [ ] T088 [P] [US4] Add template operation routing to `projects/javascript/lib/dao.js`
- [ ] T089 [P] [US4] Add template operation routing to `projects/rust/src/dao.rs` 🦀

### Test User Story 4

- [ ] T090 [P] [US4] Test Ruby template operations with tc suite
- [ ] T091 [P] [US4] Test Go template operations with tc suite
- [ ] T092 [P] [US4] Test Python template operations with tc suite 🐍
- [ ] T093 [P] [US4] Test JavaScript template operations with tc suite
- [ ] T094 [P] [US4] Test Rust template operations with tc suite 🦀

**Checkpoint**: All user stories complete - full demo system working across all languages

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, code quality, final validation

- [ ] T095 [P] [SHARED] Update `projects/ruby/README.md` with usage examples, showcase clean code
- [ ] T096 [P] [SHARED] Update `projects/go/README.md` with build/run instructions
- [ ] T097 [P] [SHARED] Update `projects/rust/README.md` with cargo commands
- [ ] T098 [P] [SHARED] Update `projects/javascript/README.md` with npm setup
- [ ] T099 [P] [SHARED] Update `projects/python/README.md` with 🐍 themed examples

- [ ] T100 [SHARED] Run full tc test suite against all 5 languages, verify 100% pass rate
- [ ] T101 [SHARED] Validate `specs/006-i-want-to/quickstart.md` examples work for all languages
- [ ] T102 [P] [SHARED] Code review Ruby implementation for idiomatic style and cleanliness
- [ ] T103 [SHARED] Update main repo README.md with multi-language demo section
- [ ] T104 [SHARED] Create comparison test results table (manual run, document pass rates and timing)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all language implementations
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (different languages) OR sequentially by priority
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational - Extends US1 but independently testable
- **User Story 3 (P3)**: Requires US1 + US2 complete (needs operations to test)
- **User Story 4 (P4)**: Can start after Foundational - Independent of US1-3 (new operations)

### Within Each User Story

- Shared test data before language implementations
- Language implementations can proceed in parallel (different teams)
- Within a language: ResultStore → DAO → Operations → Integration → Test
- Ruby first (showcase clean code), then Go, Python, JavaScript, Rust

### Parallel Opportunities

**Phase 1 (Setup)**: All 6 tasks (T001-T006) can run in parallel

**Phase 2 (Foundational)**: Tasks T008-T012 (test data creation) can run in parallel

**Phase 3 (US1)**:
- Ruby, Go, Python, JavaScript, Rust implementations can run in parallel (T014-T050)
- Within each language: ResultStore + DAO skeleton (2 tasks) can run in parallel
- Tests per language can run in parallel

**Phase 4 (US2)**: All /result/poll handler implementations (T051-T055) can run in parallel, then routing integration (T056-T060) in parallel, then tests (T061-T065) in parallel

**Phase 5 (US3)**: Documentation tasks can run in parallel

**Phase 6 (US4)**: All template operation implementations can run in parallel per language

**Phase 7 (Polish)**: README updates (T095-T099) can run in parallel

---

## Parallel Example: User Story 1 (Ruby Implementation)

```bash
# Launch in parallel (different files):
Task: "Create ResultStore class in projects/ruby/lib/result_store.rb"
Task: "Create DAO class skeleton in projects/ruby/lib/dao.rb"

# Sequential (same file):
Task: "Implement /prompt/generate handler in projects/ruby/lib/operations.rb"
Task: "Integrate /prompt/generate with DAO routing in projects/ruby/lib/dao.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only - Single Language)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T012) ← CRITICAL
3. Complete Phase 3: User Story 1 **Ruby only** (T014-T020)
4. **STOP and VALIDATE**: Test Ruby implementation with tc suite
5. Demo working MVP: single language, single operation, validates pattern

### Incremental Delivery (Priority Order)

1. MVP: Ruby + /prompt/generate (US1 partial)
2. Add: Go + Python + JavaScript + Rust for /prompt/generate (US1 complete)
3. Add: /result/poll across all languages (US2 complete)
4. Validate: Shared test suite works (US3 complete)
5. Add: Template operations across all languages (US4 complete)

### Parallel Team Strategy

With 5 developers after Foundational phase completes:

1. **Developer 1**: Ruby implementation (all phases)
2. **Developer 2**: Go implementation (all phases)
3. **Developer 3**: Python implementation (all phases) 🐍
4. **Developer 4**: JavaScript implementation (all phases)
5. **Developer 5**: Rust implementation (all phases) 🦀

Each developer delivers independently testable implementation, then integrates via shared tc test suite.

---

## Notes

- **KISS**: Minimal implementations (200-300 LOC each), standard libraries
- **Ruby Priority**: Make it really clean - showcase idiomatic code
- **Python Theming**: Playful 🐍 comments throughout
- **tc Test Suite**: Core validation - must pass for all languages
- **[P] tasks**: Different files OR different languages = parallel
- **Independent Stories**: Each user story delivers value independently
- **Checkpoints**: Validate after each phase before proceeding
- **Commit frequency**: After each task or logical group (per language)

**Total Tasks**: 104
**MVP Tasks** (Ruby + /prompt/generate): 13 (T001-T006, T007-T013, T014-T020)
**Per Language**: ~20-25 tasks
**Parallel Potential**: High - 5 independent language implementations

---

**Ready for `/speckit.implement`**: Yes - all tasks are specific, actionable, with exact file paths
