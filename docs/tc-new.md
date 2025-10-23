# tc new - Test Suite Generator

Generate test suite scaffolding for the tc testing framework.

## Quick Start

```bash
# generate a basic test suite
tc new tests/my-feature

# generate with custom metadata
tc new tests/auth/login \
  --tags "auth,api" \
  --priority high \
  --description "Test user login functionality"

# generate from an example template
tc new tests/my-calc --from hello-world

# list available templates
tc new --list-examples

# overwrite existing test
tc new tests/my-feature --force
```

## Usage

```
tc new <test-path> [options]
tc new --list-examples
```

### Options

- `--from <template>` - Use specific template (default: "default")
- `--tags <tag1,tag2>` - Comma-separated tags (e.g., "auth,api")
- `--priority <level>` - Priority: high, medium (default), low
- `--description <text>` - Test description
- `--depends <paths>` - Space-separated dependency paths
- `--force` - Overwrite existing test directory
- `--list-examples` - Show available templates
- `--help` - Show help for tc new command

## What Gets Generated

When you run `tc new tests/my-feature`, the following structure is created:

```
tests/my-feature/
├── run              # test runner script (executable)
├── README.md        # test documentation with AI-friendly metadata
└── data/
    └── example-scenario/
        ├── input.json      # test input data
        └── expected.json   # expected output data
```

### The `run` Script

The generated `run` script:
- Is executable and ready to run
- Accepts `input.json` path as first argument
- Outputs JSON to stdout
- Fails with NOT_IMPLEMENTED error until you add your logic
- Contains TODO comments guiding implementation

### The README.md

The generated README includes:
- AI-friendly metadata (tags, priority, dependencies)
- Description sections
- Scenario documentation
- AI integration hints

Example metadata format:
```markdown
**tags**: `pending`, `new`, `auth`, `api`
**what**: Test user login functionality
**depends**: tests/auth/setup
**priority**: high
```

### The Data Files

- `input.json` - Test scenario input (edit with your test data)
- `expected.json` - Expected output (edit with expected results)

## Templates

### Built-in Templates

**default** - Standard test suite template with NOT_IMPLEMENTED pattern

### Example-Based Templates

Any test suite in the `examples/` directory automatically becomes a template.

List available templates:
```bash
tc new --list-examples
```

Generate from a template:
```bash
tc new tests/my-calc --from hello-world
```

## Workflow: TDD with tc new

The `tc new` command enforces Test-Driven Development:

1. **Generate** - Create failing test scaffold
   ```bash
   tc new tests/feature-x
   ```

2. **Run** - Verify test fails with NOT_IMPLEMENTED
   ```bash
   tc run tests/feature-x
   ```

3. **Implement** - Edit `tests/feature-x/run` to add test logic

4. **Test** - Run again until it passes
   ```bash
   tc run tests/feature-x
   ```

The generated test **will fail until you implement it** - that's the point! This ensures you start with a test that fails for the right reason.

## AI Integration

The generated README.md includes metadata that AI assistants can parse:

```markdown
## ai notes

run this when: testing feature-x
skip this when: dependencies not ready
after this: run integration tests
```

This makes it easy for AI tools to:
- Discover what tests exist
- Understand test dependencies
- Run tests in the correct order
- Filter tests by tags or priority

## Examples

### Basic Test Generation

```bash
tc new tests/calculator/add
```

Creates a test suite for addition functionality with default settings.

### High-Priority API Test

```bash
tc new tests/api/users/create \
  --tags "api,users,create" \
  --priority high \
  --description "Test user creation endpoint" \
  --depends "tests/api/auth tests/db/setup"
```

Creates a test with rich metadata for AI-assisted test discovery and execution.

### Generate from Example

```bash
# list examples first
tc new --list-examples

# generate from hello-world example
tc new tests/greetings --from hello-world
```

Copies the structure of an existing working test.

### Deeply Nested Test

```bash
tc new tests/api/v2/auth/oauth/google
```

Creates all parent directories automatically.

## Tips

1. **Use descriptive paths** - `tests/feature/scenario` helps organize tests
2. **Add tags early** - Makes filtering and discovery easier
3. **Set priority** - Helps run critical tests first
4. **Document dependencies** - Ensures correct execution order
5. **Start simple** - Use default template, customize later
6. **Run immediately** - Verify NOT_IMPLEMENTED error appears

## See Also

- [Quickstart Guide](../specs/002-we-need-a/quickstart.md) - Detailed examples
- `tc init` - Initialize test directory with README
- `tc list` - List all test suites
- `tc run` - Execute test suites
- `tc explain` - Show test suite details

## Reference

For complete specification and contract details, see:
- [Feature Spec](../specs/002-we-need-a/spec.md)
- [Template Contract](../specs/002-we-need-a/contracts/template-format.md)
- [Implementation Tasks](../specs/002-we-need-a/tasks.md)
