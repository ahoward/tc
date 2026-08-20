# Research: Test Suite Generator

**Date**: 2025-10-12
**Feature**: Test Suite Generator (`tc new` command)
**Plan**: [plan.md](plan.md)

## Research Findings

### 1. Template Format & Variable Substitution

**Decision**: Use shell heredocs with variable substitution

**Rationale**:
- Bash-native, no external dependencies
- Clear, readable syntax for multi-line templates
- Direct variable expansion (`$VAR` or `${VAR}`)
- Can escape with single quotes for literal content
- Familiar to shell scripters

**Alternatives Considered**:
- `envsubst`: Requires GNU gettext utils (not always available)
- `sed` replacements: Complex for multi-line, error-prone escaping
- `jq` templates: Overkill for simple text files, JSON-specific
- Separate template files: Extra I/O, harder to maintain, deployment complexity

**Implementation Approach**:
```bash
# Generate file with variable substitution
cat > "$target_file" <<EOF
# ${TEST_NAME}

**tags**: \`pending\`, \`new\`
**what**: ${DESCRIPTION}
EOF
```

**For literal content** (prevent variable expansion):
```bash
cat > "$run_script" <<'EOF'
#!/usr/bin/env bash
# TODO: implement test logic
echo '{"error": "NOT_IMPLEMENTED", "message": "Test logic not yet implemented"}'
exit 1
EOF
```

---

### 2. Clear Failing Test Error Messages

**Decision**: Structured error output with explicit next steps

**Rationale**:
- JSON format aligns with tc's comparison engine
- Explicit "NOT_IMPLEMENTED" status immediately recognizable
- Multi-line message can provide guidance
- Non-zero exit code ensures test fails
- Matches tc's existing error patterns

**Pattern**:
```json
{
  "error": "NOT_IMPLEMENTED",
  "message": "Test logic not yet implemented. Edit the 'run' script to add your test implementation.",
  "next_steps": [
    "1. Open the 'run' script in this directory",
    "2. Replace the TODO section with your test logic",
    "3. Read input.json and produce output matching expected.json",
    "4. Run 'tc run <test-path>' to verify"
  ]
}
```

**Why this works**:
- Immediate visual feedback (JSON structure, explicit error)
- Clear call to action ("Edit the 'run' script")
- Specific guidance (numbered steps)
- Self-documenting (user knows what to do without docs)

---

### 3. Repository Root Detection

**Decision**: Walk up directory tree looking for `.git` or tc markers

**Rationale**:
- Common pattern in dev tools (git, npm, cargo)
- Works from any subdirectory
- No configuration needed
- Graceful failure if outside repo

**Implementation**:
```bash
tc_find_repo_root() {
    local dir="$PWD"

    while [ "$dir" != "/" ]; do
        # Check for .git or tc marker files
        if [ -d "$dir/.git" ] || [ -f "$dir/bin/tc" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done

    return 1  # Not in repo
}
```

**Fallback**: If not found, use current directory with warning

---

### 4. Test Suite Name Validation

**Decision**: Unix filename conventions - lowercase, hyphens, alphanumeric

**Rationale**:
- Cross-platform compatibility (works on all OS)
- URL-safe (useful for CI/CD, web displays)
- Readable and conventional
- Matches tc's existing test naming

**Pattern**: `^[a-z0-9][a-z0-9-]*[a-z0-9]$`

**Rules**:
- Start and end with lowercase letter or digit
- Middle can contain hyphens
- No underscores (avoid confusion with programming identifiers)
- No spaces (shell-friendly)
- No uppercase (consistency, avoid case-sensitivity issues)

**Examples**:
- ✅ `auth-login`
- ✅ `user-profile-update`
- ✅ `api-v2-tokens`
- ❌ `Auth-Login` (uppercase)
- ❌ `auth_login` (underscore)
- ❌ `auth login` (space)
- ❌ `-auth` (starts with hyphen)

---

### 5. Template Discovery & Listing

**Decision**: Two-tier system - built-in templates + example references

**Rationale**:
- Built-in "default" template always available
- Examples directory provides real working tests to copy
- Clear separation between "starter" and "by example"
- Examples are versioned with the project

**Structure**:
```
lib/templates/
├── default/          # Built-in starter template
│   ├── run.template
│   ├── README.template
│   ├── input.template
│   └── expected.template
└── examples -> ../../examples/  # Symlink to examples dir
```

**Discovery Logic**:
```bash
tc new --list-examples
# Output:
# Built-in templates:
#   default - Basic test suite structure
#
# Example templates (from examples/):
#   hello-world - Simple arithmetic test
#   (other examples as available)
```

**Usage**:
```bash
tc new my-test                    # Uses default template
tc new my-test --from default     # Explicit default
tc new my-test --from hello-world # Copies examples/hello-world structure
```

---

### 6. CLI Scaffolding Best Practices

**Research from similar tools**:

**Rails** (`rails generate`):
- Prints file tree as it creates
- Color-coded output (create/exist/skip)
- Summary at end

**Cargo** (`cargo new`):
- Minimal output, just "Created <name>"
- Assumes success unless error
- Shows next command to run

**Create React App**:
- Progress indicator
- Verbose file listing
- Big success message with commands

**Decision for tc**: Cargo-style minimalism with tc flavor

**Output format**:
```
created test suite: tests/auth/login 🚁

structure:
  tests/auth/login/
  ├── run
  ├── README.md
  └── data/
      └── example-scenario/
          ├── input.json
          └── expected.json

next steps:
  1. Edit tests/auth/login/run to add test logic
  2. Update data/example-scenario/*.json with real test data
  3. Run: tc run tests/auth/login

the test will fail until you implement it - that's the point! 🚁
```

**Rationale**:
- Minimal but informative
- Tree view shows what was created
- Clear next steps
- Helicopter emoji (tc brand consistency)
- Friendly TDD reminder

---

### 7. Path Handling & Directory Creation

**Decision**: Use `mkdir -p` with validation

**Rationale**:
- `mkdir -p` creates parent directories automatically
- POSIX-standard, works everywhere
- Idempotent (safe to run multiple times)
- Returns exit code for error handling

**Safety Checks**:
```bash
# Check if already exists
if [ -d "$target_path" ]; then
    if [ "$force" != "true" ]; then
        tc_error "Directory already exists: $target_path"
        tc_error "Use --force to overwrite"
        return 1
    fi
fi

# Validate write permissions
if ! mkdir -p "$target_path" 2>/dev/null; then
    tc_error "Cannot create directory: $target_path"
    tc_error "Check permissions"
    return 1
fi
```

---

### 8. Metadata Integration

**Decision**: Generate README matching existing tc format exactly

**Template**:
```markdown
# ${TEST_NAME}

**tags**: \`pending\`, \`new\`${EXTRA_TAGS}
**what**: ${DESCRIPTION}
**depends**: ${DEPENDENCIES}
**priority**: ${PRIORITY}

## description

TODO: Add detailed description of what this test validates

## scenarios

- \`example-scenario\` - TODO: describe what this scenario tests

## ai notes

run this when: ${RUN_WHEN}
skip this when: test logic not yet implemented
after this: TODO: list related tests to run
```

**Variables**:
- `${TEST_NAME}`: Derived from path (e.g., "auth-login")
- `${EXTRA_TAGS}`: Optional from `--tags` flag (e.g., ", \`auth\`, \`api\`")
- `${DESCRIPTION}`: Default "TODO: describe test purpose" or from `--description`
- `${DEPENDENCIES}`: Default empty or from `--depends`
- `${PRIORITY}`: Default "medium" or from `--priority`
- `${RUN_WHEN}`: Default "testing ${feature-area}" (derived from path)

**Validation**: Generated README must pass `tc_extract_metadata()` parser

---

## Implementation Strategy

### Phase 1: Core Generation (MVP)

Focus: Get basic `tc new <name>` working

**Components**:
1. Command parsing in `bin/tc`
2. `lib/core/generator.sh` with generation logic
3. Default templates in `lib/templates/default/`
4. Basic validation (name, path, conflicts)

**Deliverable**: Can generate simple test suite with failing test

### Phase 2: Metadata & Integration

Focus: AI-friendly features

**Components**:
1. README generation with metadata
2. Optional flags (`--tags`, `--priority`)
3. Integration with `tc list` and `tc explain`

**Deliverable**: Generated tests discoverable via existing tc commands

### Phase 3: Example-Based Generation

Focus: Learning by example

**Components**:
1. `--from` flag to copy from examples
2. `--list-examples` to show available templates
3. Path/name substitution when copying

**Deliverable**: Users can bootstrap from working examples

---

## Risks & Mitigations

**Risk**: Template content becomes stale as tc evolves
**Mitigation**: Keep templates simple, reference external docs, periodic review

**Risk**: Name validation too restrictive
**Mitigation**: Clear error messages explaining rules, document conventions

**Risk**: Generated tests don't match tc patterns
**Mitigation**: Dogfood the generator (use tc to test itself), validate with existing parsers

**Risk**: Path handling edge cases (symlinks, permissions, special chars)
**Mitigation**: Robust validation, clear error messages, don't try to be too clever

---

## Technology Stack Summary

**Language**: Bash 4.0+ (no bashisms, POSIX-compatible)
**Dependencies**: jq (already required by tc)
**External Tools**: None (no envsubst, no templates engines)
**Template Engine**: Bash heredocs with variable substitution
**Validation**: Regex for names, file system checks for paths
**Integration**: Existing tc metadata system, no changes required

---

## Open Questions

None - all research questions resolved with concrete decisions

