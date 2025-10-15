# Feature Specification: TC Source Layout Refactoring

**Feature Branch**: `003-refactor-tc-source`
**Created**: 2025-10-12
**Status**: Draft
**Input**: User description: "Refactor TC source layout to ./tc/ directory structure. Move bin/tc to ./tc/run as the top-level CLI. Organize all framework code under ./tc/ directory with config.sh at root. Support test-specific config at test suite level. This provides a cleaner, more organized structure: ./tc/run (CLI), ./tc/config.sh (global config), ./tc/lib/ (libraries), ./tc/tests/ (self-tests). Test suites remain flexible but can optionally use ./tc/tests/suite-name/config.sh for suite-specific configuration. The goal is 'ultra tidy' organization with clear separation between framework and tests."

## User Scenarios & Testing

### User Story 1 - Developer Uses Refactored CLI (Priority: P1)

A developer working with TC needs to run tests and use all existing functionality after the refactoring. The new directory structure should be transparent to them - all commands work exactly the same way but with a cleaner, more organized source layout.

**Why this priority**: Core functionality must remain unbroken. This is the foundation that all other improvements build upon. If the refactoring breaks existing usage, the project becomes unusable.

**Independent Test**: Can be fully tested by running all existing tc commands (tc run, tc new, tc init, tc list, etc.) after the refactoring and verifying they produce identical results to the pre-refactoring version.

**Acceptance Scenarios**:

1. **Given** TC is installed with the new ./tc/ structure, **When** a developer runs `tc --version`, **Then** the version information displays correctly
2. **Given** existing test suites in the repository, **When** developer runs `tc run tests --all`, **Then** all tests execute successfully with identical results to pre-refactoring
3. **Given** the refactored structure, **When** developer generates a new test with `tc new`, **Then** test generation works identically to before
4. **Given** the new directory layout, **When** developer runs parallel execution with `--parallel`, **Then** parallel execution works without modification

---

### User Story 2 - Developer Navigates Source Code (Priority: P2)

A developer contributing to TC or debugging an issue needs to find framework code easily. The new ./tc/ structure groups all framework code in one clear location, separating it from project-level files like README and docs.

**Why this priority**: Improves developer experience and code maintainability but doesn't affect runtime functionality. Can be delivered after basic functionality is proven working.

**Independent Test**: Can be tested by asking a new contributor to locate specific components (CLI entry point, configuration, library modules) and measuring time to find vs. old structure.

**Acceptance Scenarios**:

1. **Given** a new contributor looking for the CLI entry point, **When** they check the repository structure, **Then** they immediately find ./tc/run as the obvious starting point
2. **Given** a developer debugging configuration issues, **When** they look for global config, **Then** they find ./tc/config.sh in a predictable location
3. **Given** someone exploring the codebase, **When** they want to understand organization, **Then** the ./tc/ directory clearly contains all framework code separate from documentation

---

### User Story 3 - Test Suite Uses Custom Configuration (Priority: P3)

A test suite author needs to override global TC configuration for specific test requirements (e.g., longer timeout, different comparison mode). They can create a config.sh file within their test suite directory that automatically gets loaded.

**Why this priority**: Adds flexibility for advanced use cases but most tests work fine with defaults. Nice-to-have feature that enhances power user experience.

**Independent Test**: Can be tested by creating a test suite with custom config.sh, verifying the settings override globals, and confirming other suites remain unaffected.

**Acceptance Scenarios**:

1. **Given** a test suite with ./tests/my-suite/config.sh defining custom timeout, **When** TC runs this suite, **Then** the custom timeout is used instead of the global default
2. **Given** multiple test suites with different configs, **When** TC runs all suites, **Then** each suite's config is applied independently without cross-contamination
3. **Given** a test suite without config.sh, **When** TC runs it, **Then** global configuration from ./tc/config.sh applies as expected

---

### Edge Cases

- What happens when installation methods (symlink, copy, PATH) interact with the new structure?
- How does the new structure affect existing user installations that need to upgrade?
- What if a test suite has both old-style and new-style config files?
- How does TC discover its own libraries when invoked from different working directories?
- What happens if ./tc/config.sh doesn't exist or is malformed?

## Requirements

### Functional Requirements

- **FR-001**: System MUST maintain all existing CLI functionality (run, new, init, list, tags, explain, parallel execution) without behavior changes
- **FR-002**: CLI entry point MUST be located at ./tc/run instead of bin/tc
- **FR-003**: Global framework configuration MUST be located at ./tc/config.sh
- **FR-004**: All framework libraries MUST be organized under ./tc/lib/ directory
- **FR-005**: Framework self-tests MUST be located under ./tc/tests/ directory
- **FR-006**: System MUST support optional test-specific configuration via config.sh files within test suite directories
- **FR-007**: TC MUST correctly discover and load its libraries regardless of invocation path or current working directory
- **FR-008**: Installation methods (PATH, symlink, system copy) MUST work with the new structure
- **FR-009**: Existing documentation and examples MUST be updated to reflect new paths
- **FR-010**: System MUST maintain backward compatibility with existing test suites (they shouldn't need modification)

### Key Entities

- **Framework Root (./tc/)**: Container for all TC framework code, separating it from project-level documentation and configuration
  - Contains: CLI entry point (run), global config (config.sh), libraries (lib/), self-tests (tests/)

- **CLI Entry Point (./tc/run)**: Main executable that provides all TC commands
  - Replaces: bin/tc
  - Must: Discover library paths, load configuration, route commands

- **Global Configuration (./tc/config.sh)**: Default settings for all TC operations
  - Contains: Timeouts, comparison modes, parallel defaults, logging levels
  - Can be overridden by suite-specific config

- **Test Suite Configuration (tests/suite-name/config.sh)**: Optional per-suite overrides
  - Scope: Applies only to specific test suite
  - Purpose: Custom timeouts, specialized comparison modes, suite-specific settings

## Success Criteria

### Measurable Outcomes

- **SC-001**: All existing TC commands produce identical outputs before and after refactoring (verified by running full test suite)
- **SC-002**: Contributors can locate the CLI entry point in under 10 seconds (./tc/run is obvious)
- **SC-003**: Framework code organization reduces time to find specific modules by 50% (measured by new contributor onboarding)
- **SC-004**: Zero test suite modifications required for existing tests to work with new structure
- **SC-005**: Installation instructions remain simple and clear (3 options, all work with new structure)
- **SC-006**: Documentation updates complete and accurate within same release as refactoring

## Assumptions

- Users install TC at the repository root, not subdirectories
- Test suites are independent entities that don't rely on specific TC internal paths
- Backward compatibility with existing test suites is critical for adoption
- The refactoring is internal reorganization - external API remains unchanged
- PATH-based installation adds ./tc to PATH, not ./tc/run directly
- Configuration loading follows source hierarchy (global → suite-specific)
- The term "ultra tidy" means logical grouping with clear separation of concerns

## Out of Scope

The following are explicitly excluded from this feature:

- Changes to test runner interface or behavior
- Modifications to test suite directory structure
- New configuration options or settings
- Performance optimizations
- Changes to output formatting or logging
- Database or external service integration
- New CLI commands or flags
- Changes to parallel execution logic
- Modifications to test discovery algorithm
- Updates to test generation templates (beyond path references)
