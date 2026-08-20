# tasks: tc - theodore calvin's language-agnostic testing framework 🚁

**input**: design docs from `/specs/001-design-a-testing/`
**prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/test-suite-interface.md

**organization**: tasks grouped by user story for independent implementation and delivery

## format: `[ID] [P?] [Story] description`
- **[P]**: can run in parallel (different files, no deps)
- **[Story]**: which user story (US1, US2, etc)
- paths are relative to repo root

## path conventions
single project structure (see plan.md):
- `bin/tc` - main cli entry point
- `lib/core/` - core framework modules
- `lib/utils/` - utility functions
- `lib/config/` - configuration
- `tests/` - framework self-tests (dogfooding!)
- `docs/` - user documentation
- `examples/` - sample test suites

---

## phase 1: setup (shared infrastructure)

**purpose**: project initialization, basic structure, tooling

- [x] T001 create directory structure per plan.md (bin/, lib/core/, lib/utils/, lib/config/, tests/, docs/, examples/)
- [x] T002 [P] create bin/tc entry point script with shebang and version flag
- [x] T003 [P] create lib/config/defaults.sh with global defaults (timeout=300, comparison=semantic_json, parallel=auto)
- [x] T004 [P] add .gitignore for .tc-result files and temp artifacts
- [x] T005 [P] create LICENSE file (choose appropriate open source license)

**checkpoint**: project skeleton ready

---

## phase 2: foundational (blocking prerequisites)

**purpose**: core infrastructure that MUST complete before ANY user story

**⚠️ critical**: no user story work can begin until this phase is complete

- [x] T006 [P] implement lib/utils/log.sh - stderr logging functions (info, warn, error, debug)
- [x] T007 [P] implement lib/utils/json.sh - jq wrapper functions for json parsing and comparison
- [x] T008 [P] implement lib/utils/platform.sh - platform detection (linux, macos, windows/wsl)
- [x] T009 implement lib/core/discovery.sh - find test suites by walking directory tree
- [x] T010 implement lib/core/validator.sh - validate test suite structure (runner exists, executable, data/ dir, scenarios)

**checkpoint**: foundation ready - user stories can now proceed in parallel

---

## phase 3: user story 1 - run single test suite independently (priority: p1) 🎯 mvp

**goal**: developer can run one test suite, see pass/fail, get clear feedback

**independent test**: create test suite dir with runner + data/scenario/{input,expected}.json, run it, verify output comparison works

### implementation for user story 1

- [x] T011 [P] [US1] implement lib/core/runner.sh - execute test runner with scenario input file
- [x] T012 [P] [US1] implement lib/core/comparator.sh - semantic json comparison using jq (order-independent)
- [x] T013 [P] [US1] implement lib/utils/timer.sh - timeout management with TERM→KILL escalation
- [x] T014 [US1] implement lib/core/executor.sh - orchestrate: load scenario → run → capture output → compare
- [x] T015 [US1] implement lib/utils/reporter.sh - format single suite results (pass/fail counts, scenario details)
- [x] T016 [US1] wire up bin/tc to handle `tc run <suite-path>` command
- [x] T017 [US1] add exit code 0 for pass, non-zero for fail
- [x] T018 [US1] add basic error handling (missing runner, invalid json, timeout)

**checkpoint**: at this point, US1 should be fully functional - can run one test suite end-to-end

---

## phase 4: user story 2 - install and use without dependencies (priority: p2)

**goal**: new user can install tc in <2min, run first test with zero config

**independent test**: on clean system, follow install steps, run test suite, verify works without extra deps

### implementation for user story 2

- [ ] T019 [US2] create docs/readme.md - unix hacker style, theodore calvin theme, helicopter emoji 🚁
- [ ] T020 [US2] add ascii art or image reference to readme (magnum pi vibes)
- [ ] T021 [US2] document installation: clone repo, add bin/ to PATH, verify jq installed
- [ ] T022 [US2] create examples/hello-world/ - minimal test suite (add two numbers)
- [ ] T023 [US2] add examples/hello-world/run script (bash implementation)
- [ ] T024 [US2] add examples/hello-world/data/add-positive/input.json and expected.json
- [ ] T025 [US2] test installation flow on clean VM (linux, macos if available)
- [ ] T026 [US2] add bin/tc --version and bin/tc --help output

**checkpoint**: user story 2 complete - anyone can install and run their first test in <2min

---

## phase 5: user story 3 - organize tests hierarchically (priority: p3)

**goal**: run tests from any level in hierarchy, results aggregate up

**independent test**: create nested suites (feature/subfeature/suite), run from parent, verify all execute

### implementation for user story 3

- [ ] T027 [US3] update lib/core/discovery.sh - recursive suite finding from any directory level
- [ ] T028 [US3] add `tc run <path> --all` flag to run all suites in subtree
- [ ] T029 [US3] update lib/utils/reporter.sh - hierarchical result aggregation
- [ ] T030 [US3] add suite path display in output (e.g., "suite: auth/login")
- [ ] T031 [US3] create examples/nested/ - demonstrate hierarchical organization
- [ ] T032 [US3] update docs/readme.md - document hierarchical structure

**checkpoint**: user story 3 complete - tests can be organized hierarchically

---

## phase 6: user story 4 - execute tests in parallel (priority: p4)

**goal**: run multiple suites concurrently, reduce total time by 75%+

**independent test**: create 10+ suites, run in parallel, measure speedup vs sequential

### implementation for user story 4

- [ ] T033 [US4] implement lib/utils/platform.sh - detect_cpu_cores() for linux/macos/windows
- [ ] T034 [US4] implement lib/core/parallel.sh - job control with max_jobs limit
- [ ] T035 [US4] add `--parallel` flag to bin/tc (default: auto, accepts --parallel=N)
- [ ] T036 [US4] update lib/core/executor.sh - parallel suite execution with background jobs
- [ ] T037 [US4] handle parallel result collection without conflicts (wait for all jobs)
- [ ] T038 [US4] add timing to reporter - show total time, note speedup
- [ ] T039 [US4] create examples/parallel/ - 5+ small suites to demo parallelism

**checkpoint**: user story 4 complete - parallel execution works, fast feedback achieved

---

## phase 7: user story 5 - run selective test groups (priority: p5)

**goal**: run specific subsets by pattern, skip others

**independent test**: create mixed suites, run with pattern (e.g., `*/auth/*`), verify selection

### implementation for user story 5

- [ ] T040 [US5] add `--pattern` flag to bin/tc (glob-style matching)
- [ ] T041 [US5] update lib/core/discovery.sh - filter suites by pattern
- [ ] T042 [US5] update lib/utils/reporter.sh - show which suites included/excluded
- [ ] T043 [US5] create examples/selective/ - demo different patterns
- [ ] T044 [US5] update docs/readme.md - document pattern syntax

**checkpoint**: user story 5 complete - selective test execution available

---

## phase 8: user story 6 - port application to new language (priority: p6)

**goal**: same test suite validates different language implementations

**independent test**: implement simple feature in 2 languages, use same test suite for both

### implementation for user story 6

- [ ] T045 [US6] create examples/polyglot/ - same feature in bash and python
- [ ] T046 [US6] both implementations use identical test suite (shared data/)
- [ ] T047 [US6] verify both pass same tests
- [ ] T048 [US6] document language-agnostic runner interface in docs/
- [ ] T049 [US6] update docs/readme.md - highlight polyglot capability

**checkpoint**: user story 6 complete - language-agnostic approach validated

---

## phase 9: user story 7 - capture results persistently (priority: p7)

**goal**: results written to .tc-result file, logs captured for debugging

**independent test**: run suite, verify .tc-result file created with jsonl format

### implementation for user story 7

- [ ] T050 [US7] implement result writer in lib/utils/reporter.sh - write jsonl to .tc-result
- [ ] T051 [US7] include scenario status, duration, timestamp, diff (if failed)
- [ ] T052 [US7] capture stderr from test runner (logs) in result details
- [ ] T053 [US7] overwrite .tc-result each run (single file strategy)
- [ ] T054 [US7] update .gitignore to exclude .tc-result files
- [ ] T055 [US7] add `tc results <suite>` command to pretty-print .tc-result file
- [ ] T056 [US7] update docs/readme.md - document result file format

**checkpoint**: user story 7 complete - persistent results enable debugging without re-runs

---

## phase 10: polish & cross-cutting concerns

**purpose**: improvements affecting multiple stories, docs, self-tests

- [ ] T057 [P] create tests/fixtures/ - sample test suites for framework self-testing
- [ ] T058 [P] implement tests/integration/test_single_suite.sh - verify US1 works
- [ ] T059 [P] implement tests/integration/test_parallel.sh - verify US4 works
- [ ] T060 [P] implement tests/integration/test_hierarchical.sh - verify US3 works
- [ ] T061 [P] add lib/core/comparator.sh - whitespace normalization mode (configurable)
- [ ] T062 [P] add lib/core/comparator.sh - fuzzy matching mode (optional, levenshtein distance)
- [ ] T063 [P] implement .tc-config file parser in lib/config/loader.sh
- [ ] T064 [P] add suite-level timeout override support
- [ ] T065 [P] add suite-level comparison mode override support
- [ ] T066 [P] create docs/getting-started.md - step-by-step tutorial
- [ ] T067 [P] create docs/test-suite-authoring.md - how to write runners
- [ ] T068 [P] add easter eggs in source - theodore calvin references, helicopter comments
- [ ] T069 create examples/comparison-modes/ - demo semantic json vs whitespace vs fuzzy
- [ ] T070 run full self-test suite (tests/ directory)
- [ ] T071 verify quickstart.md scenarios all work
- [ ] T072 performance benchmark - verify <10% overhead, 75% parallel speedup

**checkpoint**: framework feature-complete, self-tested, documented

---

## dependencies & execution order

### phase dependencies

- **setup (phase 1)**: no deps - start immediately
- **foundational (phase 2)**: depends on setup - BLOCKS all user stories
- **user stories (phase 3-9)**: all depend on foundational phase
  - can proceed in parallel (if team capacity)
  - or sequentially by priority (p1 → p2 → p3...)
- **polish (phase 10)**: depends on desired user stories being complete

### user story dependencies

- **US1 (p1)**: no deps on other stories - pure mvp
- **US2 (p2)**: needs US1 to exist (can't install nothing)
- **US3 (p3)**: builds on US1 (single suite execution)
- **US4 (p4)**: builds on US1 + US3 (parallel execution of discovered suites)
- **US5 (p5)**: builds on US3 (selective from hierarchical organization)
- **US6 (p6)**: validates US1 (language-agnostic execution)
- **US7 (p7)**: enhances US1 (persistent results for debugging)

### within each user story

- parallel tasks marked [P] can run simultaneously
- sequential tasks must complete in order
- each story should be independently testable at its checkpoint

### parallel opportunities

**setup phase**: T002, T003, T004, T005 can all run in parallel

**foundational phase**: T006, T007, T008 can run in parallel (different files)

**US1**: T011, T012, T013 can run in parallel, then T014-T018 sequentially

**US2**: T019-T026 mostly parallel (different files/examples)

**US4**: T033, T034 in parallel, then rest sequentially

**polish**: T057-T068 all parallel (different test files, docs, examples)

---

## parallel example: user story 1

```bash
# launch these in parallel (different files):
Task: "implement lib/core/runner.sh - execute test runner"
Task: "implement lib/core/comparator.sh - semantic json comparison"
Task: "implement lib/utils/timer.sh - timeout management"

# then sequentially:
Task: "implement lib/core/executor.sh - orchestrate execution"
Task: "wire up bin/tc run command"
# ... etc
```

---

## implementation strategy

### mvp first (user story 1 only)

1. complete phase 1: setup
2. complete phase 2: foundational (CRITICAL)
3. complete phase 3: user story 1
4. **STOP and VALIDATE**: run examples/hello-world/ test suite
5. can now run single test suite end-to-end!

### incremental delivery

1. setup + foundational → foundation ready
2. add US1 → test independently → **mvp delivered!** 🎯
3. add US2 → test independently → easier installation
4. add US3 → test independently → hierarchical organization
5. add US4 → test independently → fast parallel execution
6. each story adds value without breaking previous stories

### parallel team strategy

with multiple devs:

1. team completes setup + foundational together
2. once foundational done:
   - dev a: user story 1 (mvp)
   - dev b: user story 2 (installation)
   - dev c: user story 3 (hierarchy)
3. stories complete independently, integrate cleanly

---

## notes

- keep it simple, unix hacker aesthetic
- theodore calvin (tc) easter eggs in code comments 🚁
- lowercase where possible in docs/output
- favor shell idioms over complex logic
- test each story independently at checkpoints
- jq is only external dep - document it clearly
- framework tests itself (dogfooding in tests/ dir)
- examples/ shows users how to write test suites

## success metrics (from spec.md)

before calling it done, verify:
- ✅ install and run first test in <2min (US2)
- ✅ create new test suite in <5min (US1 + US2)
- ✅ framework overhead <10% (measure in polish phase)
- ✅ parallel execution achieves 75% speedup with 10+ suites (US4)
- ✅ works on linux, macos, windows/wsl (test in US2)
- ✅ zero external deps beyond jq (architecture decision)
- ✅ self-tests pass (polish phase)

---

**total tasks**: 72
**estimated mvp** (US1+US2): 26 tasks
**estimated full feature**: 72 tasks

**next step**: start with T001 (create directory structure) and work through phases sequentially, or parallelize within phases as marked [P]
