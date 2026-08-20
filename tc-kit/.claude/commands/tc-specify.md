# Slash Command: /tc.specify

Generate technology-agnostic tc test suites from spec-kit specification documents.

## Command

Execute the test generation script:

```bash
.specify/scripts/bash/tc-kit-specify.sh "$@"
```

This command will:
1. Parse spec.md to extract user stories and acceptance scenarios
2. Generate tc test suites in `tc/tests/{feature}/user-story-{NN}/scenario-{NN}/`
3. Create input.json, expected.json, and run scripts for each scenario
4. Generate traceability.json (bidirectional spec↔test links)
5. Initialize maturity.json (all tests at "concept" level)

See `specs/{feature}/contracts/tc-kit-specify.md` for full interface documentation.
