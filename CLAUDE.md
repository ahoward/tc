# tc Development Guidelines

Last updated: 2025-10-29

## Project Structure

tc is a simple, language-agnostic testing framework with an optional spec-driven addon.

```
tc/
├── tc/                    # Core testing framework
│   ├── bin/tc            # Test runner
│   ├── lib/              # Framework libraries
│   │   ├── config/
│   │   ├── core/
│   │   └── utils/
│   └── tests/            # Generated test suites
├── examples/              # Test examples
├── tests/                 # tc's own tests
├── docs/                  # Core documentation
├── projects/              # Multi-language DAO examples
└── tc-kit/               # Optional spec-driven addon
    ├── .specify/         # Templates and scripts
    ├── .claude/          # Slash commands (optional)
    ├── specs/            # Feature specifications
    ├── data/             # Traceability data
    └── docs/             # tc-kit documentation
```

## Core Technologies

**tc core** (keep simple):
- Shell script (POSIX-compatible)
- jq for JSON handling
- Standard POSIX tools
- Filesystem-based (test suites as directories)
- JSONL for reports

**tc-kit addon** (optional, experimental):
- Bash 4.0+ for automation scripts
- spec-kit integration
- AI-assisted workflows
- Slash commands for Claude Code

## Code Style

- POSIX-compatible shell scripts
- Follow KISS principle
- Minimize dependencies
- Focus on testing framework core

## Philosophy

Keep tc **simple**, **portable**, **language-agnostic**, and **unix**-focused.

- Core testing framework: tight and focused
- Optional addons: separate in subdirectories
- Avoid feature creep in core
- Experimental features go in tc-kit/

## Notes

- tc core = just testing (simple, stable)
- tc-kit = optional spec-driven workflow (experimental)
- Keep clear separation between core and addons

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
