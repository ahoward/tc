# Template Format Contract

**Date**: 2025-10-12
**Feature**: Test Suite Generator
**Version**: 1.0

## Purpose

This contract defines the interface between the test generator and template files. Any template that adheres to this contract can be used with `tc new` to generate test suites.

## Template Structure

### Directory Layout

```
templates/{template-name}/
├── run.template         # Executable test runner template
├── README.template      # Metadata documentation template
├── input.template       # Sample input JSON template
└── expected.template    # Sample expected output template
```

### Required Files

- **`run.template`**: MUST be present, will become executable `run` script
- **`README.template`**: MUST be present, will become `README.md`
- **`input.template`**: MUST be present, will become `data/example-scenario/input.json`
- **`expected.template`**: MUST be present, will become `data/example-scenario/expected.json`

## Variable Substitution

### Mechanism

Templates use bash heredoc variable substitution. Variables are expanded when the template is processed.

**Syntax**:
- `${VAR_NAME}` - Variable substitution with braces (recommended)
- `$VAR_NAME` - Variable substitution without braces (less safe)

**Escaping**: To prevent substitution, use single-quoted heredocs in generation code:
```bash
cat > file <<'EOF'
$THIS_WILL_NOT_EXPAND
EOF
```

### Standard Variables

All templates have access to these variables during generation:

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `TEST_NAME` | string | Basename of test path | `login` |
| `TEST_PATH` | string | Full path to test suite | `tests/auth/login` |
| `DESCRIPTION` | string | Test description | `TODO: describe test purpose` |
| `TAGS` | string | Comma-separated tags | `auth, api` |
| `EXTRA_TAGS` | string | Formatted for README | `, \`auth\`, \`api\`` |
| `PRIORITY` | string | Priority level | `high`, `medium`, `low` |
| `DEPENDENCIES` | string | Space-separated dependencies | `tests/user/create` |
| `RUN_WHEN` | string | AI guidance for when to run | `testing auth` |
| `TIMESTAMP` | string | ISO 8601 timestamp | `2025-10-12T14:30:00Z` |

### Variable Defaults

If not provided by user flags:

```bash
DESCRIPTION="TODO: describe test purpose"
TAGS="pending, new"
EXTRA_TAGS=", \`pending\`, \`new\`"
PRIORITY="medium"
DEPENDENCIES=""
RUN_WHEN="testing ${derived_from_path}"
```

## Template Content Requirements

### `run.template`

**MUST**:
- Be a valid executable script (shebang required)
- Accept input file path as `$1`
- Output JSON to stdout
- Exit with non-zero code to indicate failure
- Include clear error message for unimplemented tests

**RECOMMENDED**:
- Use bash for consistency (`#!/usr/bin/env bash`)
- Include TODO comments showing where to add logic
- Demonstrate input parsing with jq
- Return structured error JSON

**Example**:
```bash
#!/usr/bin/env bash
# ${TEST_NAME} test runner
# Generated: ${TIMESTAMP}

set -e

input_file="$1"

# TODO: Parse input
# value=$(jq -r '.field' "$input_file")

# TODO: Implement test logic

# Return NOT_IMPLEMENTED error
cat <<'EOF'
{
  "error": "NOT_IMPLEMENTED",
  "message": "Test logic not yet implemented.",
  "next_steps": ["Edit 'run' script", "Update input/expected JSON", "Run 'tc run ${TEST_PATH}'"]
}
EOF

exit 1
```

### `README.template`

**MUST**:
- Include metadata header with: tags, what, depends, priority
- Use backtick-wrapped tags
- Include "## description" section
- Include "## scenarios" section
- Include "## ai notes" section with run/skip conditions

**Structure**:
```markdown
# ${TEST_NAME}

**tags**: \`pending\`, \`new\`${EXTRA_TAGS}
**what**: ${DESCRIPTION}
**depends**: ${DEPENDENCIES}
**priority**: ${PRIORITY}

## description

TODO: Detailed description of what this test validates

## scenarios

- \`example-scenario\` - TODO: Describe scenario

## ai notes

run this when: ${RUN_WHEN}
skip this when: test logic not yet implemented
after this: TODO: List related tests
```

### `input.template`

**MUST**:
- Be valid JSON
- Include example structure
- Contain TODO guidance

**Example**:
```json
{
  "TODO": "Replace with actual input data",
  "example_field": "example_value"
}
```

### `expected.template`

**MUST**:
- Be valid JSON
- Match structure that `run` script should produce
- Contain TODO guidance

**Example**:
```json
{
  "TODO": "Replace with expected output",
  "example_result": "expected_value"
}
```

## Generation Contract

### Input

Generator receives:
```bash
tc new <test_path> [OPTIONS]
```

**Parameters**:
- `test_path`: Required, target path for test suite
- `--from <template>`: Optional, template name (default: "default")
- `--tags <tag1,tag2>`: Optional, comma-separated tags
- `--priority <level>`: Optional, priority level
- `--description <text>`: Optional, test description
- `--depends <paths>`: Optional, space-separated dependencies
- `--force`: Optional, overwrite existing directory

### Output

Generator produces:
```
{test_path}/
├── run (executable, mode 755)
├── README.md
└── data/
    └── example-scenario/
        ├── input.json
        └── expected.json
```

### Exit Codes

- `0`: Success, test suite created
- `1`: Error (invalid name, path exists without --force, permission denied)

### Success Output

```
created test suite: {test_path} 🚁

structure:
  {tree view}

next steps:
  1. Edit {test_path}/run to add test logic
  2. Update data/example-scenario/*.json with real data
  3. Run: tc run {test_path}

the test will fail until you implement it - that's the point! 🚁
```

## Validation Rules

### Template Validation (at generation time)

- All required template files MUST exist
- All template files MUST be readable
- JSON templates MUST be valid JSON after substitution

### Generated Suite Validation (after generation)

- `run` script MUST be executable (chmod +x applied)
- `README.md` MUST contain required metadata fields
- All JSON files MUST be valid JSON
- Directory structure MUST match expected layout

## Extension Points

### Custom Templates

To create a custom template:

1. Create directory: `lib/templates/{name}/`
2. Add required template files (run, README, input, expected)
3. Use standard variables or add custom ones in generator code
4. Reference with `--from {name}`

### Additional Variables

Generators can define additional variables beyond the standard set. Document them in the template's own README.

### Additional Files

Templates can include additional files beyond the required four. They will be copied to the generated suite maintaining relative paths.

## Compatibility

- **Bash Version**: 4.0+ (POSIX-compatible)
- **Character Encoding**: UTF-8
- **Line Endings**: LF (Unix-style)
- **File Permissions**: run script MUST be 755, others 644

## Breaking Changes

Changes that break this contract:

- Removing or renaming standard variables
- Changing metadata format in README.template
- Changing directory structure requirements
- Removing required template files

## Version History

- **1.0** (2025-10-12): Initial contract for test generator MVP
