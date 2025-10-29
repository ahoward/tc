# Slash Command: /tc.refine

Incrementally refine abstract tests into technology-specific assertions while preserving behavioral intent.

## Command

Execute the test refinement script:

```bash
.specify/scripts/bash/tc-kit-refine.sh "$@"
```

This command will:
1. Detect maturity signals (implementation commits, passing runs, pattern usage)
2. Suggest maturity level transitions (concept→exploration→implementation)
3. Offer refinement opportunities (patterns→concrete values)
4. Preserve baseline tests when applying refinements
5. Update maturity.json with new levels and signals

See `specs/{feature}/contracts/tc-kit-refine.md` for full interface documentation.
