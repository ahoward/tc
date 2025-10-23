# Slash Command: /tc.validate

Validate that implementation-specific tests still satisfy original specification requirements, detecting spec-test drift.

## Command

Execute the validation script:

```bash
.specify/scripts/bash/tc-kit-validate.sh "$@"
```

This command will:
1. Calculate test coverage (% of spec scenarios with tests)
2. Detect spec-test divergence (refined tests with unchanged specs)
3. Generate coverage matrix (per-user-story coverage details)
4. Aggregate maturity breakdown (concept/exploration/implementation counts)
5. Output TTY-friendly markdown or machine-readable JSON
6. Always persist report to tc/spec-kit/validation-report.json

See `specs/{feature}/contracts/tc-kit-validate.md` for full interface documentation.
