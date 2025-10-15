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
- 006-i-want-to: Added In-memory only (maps/hashes with correlation UUID keys)
- 004-heli-cool-stdout: Added Bash 4.0+ (POSIX-compatible shell scripting) + Existing TC framework, jq (already required), standard POSIX tools (test, printf, tput)
- 003-refactor-tc-source: Added Bash 4.0+ (POSIX-compatible shell scripting) + jq (JSON processing), standard POSIX tools (sh, basename, dirname, find, grep, etc.)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
