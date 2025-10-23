# tc Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-11

## Active Technologies
- Shell script (POSIX-compatible) for core framework, any language for test runners + None (zero external dependencies beyond standard POSIX tools: sh, jq for JSON handling, basic coreutils) (001-design-a-testing)
- Bash 4.0+ (POSIX-compatible shell scripting) + jq (JSON processing), existing tc framework (002-we-need-a)
- File system (generated templates and directories) (002-we-need-a)
- Bash 4.0+ (POSIX-compatible shell scripting) + jq (JSON processing), standard POSIX tools (sh, basename, dirname, find, grep, etc.) (003-refactor-tc-source)
- Filesystem-based (test suites as directories, results as .tc-result JSONL files) (003-refactor-tc-source)
- Bash 4.0+ (POSIX-compatible shell scripting) + Existing TC framework, jq (already required), standard POSIX tools (test, printf, tput) (004-heli-cool-stdout)
- JSONL files (`.tc-reports/report.jsonl`) (004-heli-cool-stdout)
- In-memory only (maps/hashes with correlation UUID keys) (006-i-want-to)
- Bash 4.0+ (POSIX-compatible shell scripting) + jq (JSON processing), standard POSIX tools (test, chmod, source) (007-description-add-lifecycle)
- Filesystem-based (hook scripts in test suite directories, .tc-env files for hook state) (007-description-add-lifecycle)
- Bash 4.0+ (POSIX-compatible shell scripting for slash commands) + tc framework (existing), jq (JSON processing), spec-kit markdown format (parsing) (008-explore-the-strategy)
- `./tc/spec-kit/` directory for traceability.json, validation reports, maturity metadata (008-explore-the-strategy)

## Project Structure
```
src/
tests/
```

## Commands
# Add commands for Shell script (POSIX-compatible) for core framework, any language for test runners

## Code Style
Shell script (POSIX-compatible) for core framework, any language for test runners: Follow standard conventions

## Recent Changes
- 008-explore-the-strategy: Added Bash 4.0+ (POSIX-compatible shell scripting for slash commands) + tc framework (existing), jq (JSON processing), spec-kit markdown format (parsing)
- 007-description-add-lifecycle: Added Bash 4.0+ (POSIX-compatible shell scripting) + jq (JSON processing), standard POSIX tools (test, chmod, source)
- 006-i-want-to: Added In-memory only (maps/hashes with correlation UUID keys)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
