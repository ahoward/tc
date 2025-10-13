# Feature Specification: Test Suite Generator

**Feature Branch**: `002-we-need-a`
**Created**: 2025-10-12
**Status**: Draft
**Input**: User description: "we need a nice way to be able to generate a test.. to prepopulate the test directory, etc.  this should alwasy produce a failing test.  i tshould clearly shot the used what they need to do next"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Test Scaffolding (Priority: P1)

A developer wants to create a new test suite but doesn't want to manually create all the directory structure, files, and boilerplate. They run a single command that generates a complete, failing test suite with clear guidance on what to implement next.

**Why this priority**: This is the core MVP - getting users from "I want to test X" to "I have a failing test for X" in seconds. Test-driven development (TDD) starts with a failing test, so this enables the proper workflow immediately.

**Independent Test**: Can be fully tested by running the generator command and verifying it creates a complete test suite directory structure with a failing test that includes helpful next-step guidance.

**Acceptance Scenarios**:

1. **Given** a developer wants to test a new feature, **When** they run `tc new <test-name>`, **Then** a complete test suite directory is created with skeleton files
2. **Given** the test suite is generated, **When** the developer runs `tc run` on it, **Then** the test fails with a clear message showing what needs to be implemented
3. **Given** the test suite is generated, **When** the developer examines the files, **Then** they see helpful comments and TODO markers indicating what to fill in
4. **Given** a developer specifies a nested path, **When** they run `tc new tests/auth/login`, **Then** the generator creates the full directory hierarchy

---

### User Story 2 - Guided Test Creation with Metadata (Priority: P2)

A developer wants the generated test to include AI-friendly metadata (tags, descriptions) so the test is immediately discoverable and understandable without extra manual setup.

**Why this priority**: Builds on the basic generator by making tests immediately discoverable through tc's AI features. This ensures generated tests integrate seamlessly with the ecosystem.

**Independent Test**: Can be tested by generating a test suite and verifying the README.md contains properly formatted metadata that can be parsed by `tc list` and `tc explain`.

**Acceptance Scenarios**:

1. **Given** a developer generates a test, **When** they run `tc list`, **Then** the new test appears with default tags like "pending", "new"
2. **Given** a generated test has a README, **When** the developer runs `tc explain <test>`, **Then** they see structured metadata with TODO prompts
3. **Given** a developer provides optional metadata during generation, **When** they run `tc new <name> --tags "auth,api"`, **Then** the README is pre-populated with those tags

---

### User Story 3 - Example-Based Generation (Priority: P3)

A developer wants to generate a test suite based on an existing example, copying the structure and pattern while adapting it to their specific use case.

**Why this priority**: Helps developers learn patterns by example. Lower priority because users can manually copy existing tests, but automation saves time and ensures consistency.

**Independent Test**: Can be tested by generating from an example suite and verifying the structure matches the template while names/paths are customized.

**Acceptance Scenarios**:

1. **Given** example test suites exist, **When** the developer runs `tc new <name> --from examples/hello-world`, **Then** the structure is copied with placeholders replaced
2. **Given** a developer wants to see available templates, **When** they run `tc new --list-examples`, **Then** they see a list of example suites they can use as templates

---

### Edge Cases

- What happens when the test suite directory already exists? (Should prompt for confirmation or use --force flag)
- How does the system handle invalid test names (spaces, special characters)?
- What if parent directories don't exist for nested paths?
- How does the generator behave when run from outside the repository root?
- What happens if the user doesn't have write permissions for the target directory?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a `tc new <test-suite-path>` command to generate test suite scaffolding
- **FR-002**: System MUST create a complete directory structure including: test suite directory, data subdirectory, and at least one scenario subdirectory
- **FR-003**: System MUST generate an executable `run` script with TODO comments indicating where to add test logic
- **FR-004**: System MUST create `input.json` and `expected.json` files with example placeholders
- **FR-005**: System MUST generate a README.md with AI-friendly metadata including tags, description, and next-step guidance
- **FR-006**: Generated test MUST fail when first run, with a clear error message explaining what needs to be implemented
- **FR-007**: System MUST display next-step instructions after generation showing the user exactly what to do
- **FR-008**: System MUST support nested test paths (e.g., `tests/auth/login`) and create parent directories as needed
- **FR-009**: System MUST check if target directory exists and handle conflicts appropriately
- **FR-010**: System MUST make the generated `run` script executable automatically
- **FR-011**: System MUST support optional flags for customization (--tags, --priority, --from template)
- **FR-012**: System MUST validate test suite names (reject invalid characters, spaces)

### Key Entities

- **Test Suite Skeleton**: A pre-configured directory structure with placeholder files that serves as the starting point for a new test
  - Contains: directory structure, run script template, data files, README template
  - Relationships: Generated from templates, customized based on user input

- **Template**: A reusable pattern for generating test suites
  - Contains: File structure blueprint, placeholder content, default metadata
  - Relationships: Can be built-in (default) or based on existing examples

- **Generation Metadata**: Information captured during test creation
  - Contains: Test name, path, tags, priority, template used, creation timestamp
  - Relationships: Embedded in generated README, used for documentation

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can generate a complete test suite in under 10 seconds (from command to ready-to-edit files)
- **SC-002**: Generated tests fail with a descriptive message on first run 100% of the time
- **SC-003**: Developers understand what to do next without reading documentation (measured by clear TODO comments and next-step output)
- **SC-004**: 90% of generated test suites require only filling in business logic, not restructuring files
- **SC-005**: Generated tests are immediately discoverable via `tc list` and `tc explain` commands
- **SC-006**: Test generation works from any directory within the repository

## Assumptions *(include if relevant)*

- Users have write permissions in the target directory
- Users are running the command from within a tc-compatible repository
- The default template follows tc's standard test suite structure (run script + data/ directory)
- Generated run scripts will be in bash by default (language-agnostic, users can replace)
- Test names follow Unix filename conventions (lowercase, hyphens, no spaces)

## Out of Scope *(include if relevant)*

- GUI-based test generation (command-line only)
- Automatic test implementation (generates skeleton only)
- Integration with specific testing frameworks beyond tc
- Multi-language run script generation (bash template only; users customize)
- Automatic git operations (no auto-commit of generated tests)
- Interactive wizard-style generation (flags-based only for MVP)

## Dependencies *(include if relevant)*

- Existing tc framework (must be installed and operational)
- File system with write permissions
- Template files or examples to copy from (for template-based generation)

## Related Features *(include if relevant)*

- Test metadata system (tags, README structure) - generated tests must integrate with existing metadata parsing
- Test discovery (`tc list`, `tc tags`) - generated tests must be immediately discoverable
- Test explanation (`tc explain`) - generated README must work with existing explanation system
