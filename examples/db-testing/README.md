# Database Testing with Lifecycle Hooks

This example demonstrates how to use tc's lifecycle hooks for efficient database testing.

## The Pattern

Lifecycle hooks enable **stateful testing** where you can:

1. **Setup once** - Create database schema before all tests
2. **Seed per test** - Insert fresh test data before each scenario
3. **Cleanup per test** - Remove test data after each scenario
4. **Teardown once** - Drop database after all tests

This is much more efficient than creating/destroying the entire database for each test.

## Hook Files

### `setup.sh` - Runs once before all tests

Creates a SQLite database with the schema:

```bash
#!/usr/bin/env bash
set -e

DB_FILE="$TC_SUITE_PATH/.tc-test.db"
sqlite3 "$DB_FILE" < schema.sql

# Save DB path to .tc-env for other hooks
echo "export DB_FILE=\"$DB_FILE\"" > "$TC_SUITE_PATH/.tc-env"
```

### `teardown.sh` - Runs once after all tests

Removes the test database:

```bash
#!/usr/bin/env bash
set -e

rm -f "$DB_FILE"
rm -f "$TC_SUITE_PATH/.tc-env"
```

### `before_each.sh` - Runs before each scenario

Seeds test data specific to each scenario:

```bash
#!/usr/bin/env bash
set -e

# Seed file is scenario-specific: data/<scenario>/seed.sql
SEED_FILE="$TC_DATA_DIR/seed.sql"
if [ -f "$SEED_FILE" ]; then
    sqlite3 "$DB_FILE" < "$SEED_FILE"
fi
```

### `after_each.sh` - Runs after each scenario

Cleans up test data (keeps schema):

```bash
#!/usr/bin/env bash
set -e

sqlite3 "$DB_FILE" <<EOF
DELETE FROM posts;
DELETE FROM users;
EOF
```

## Environment Variables

tc provides these variables to hooks:

- `$TC_SUITE_PATH` - Absolute path to test suite directory
- `$TC_HOOK_TYPE` - Hook type (setup, teardown, before_each, after_each)
- `$TC_SCENARIO` - Scenario name (for before_each/after_each)
- `$TC_DATA_DIR` - Scenario data directory (for before_each/after_each)
- `$TC_ROOT` - tc framework root directory

## Sharing State Between Hooks

Use `.tc-env` file to share environment variables:

```bash
# In setup.sh - create and save state
echo "export DB_FILE=\"$TC_SUITE_PATH/.tc-test.db\"" > "$TC_SUITE_PATH/.tc-env"

# In other hooks - tc automatically sources .tc-env
# So $DB_FILE is available
```

## Test Scenarios

### `insert-user`
Tests inserting a new user (no seed data needed).

### `query-users`
Tests querying users (seeds 2 users in `data/query-users/seed.sql`).

### `update-user`
Tests updating a user (seeds 1 user in `data/update-user/seed.sql`).

## Running

```bash
# Run the database testing suite
tc run examples/db-testing

# Run with debug logging to see hook execution
TC_LOG_LEVEL=DEBUG tc run examples/db-testing
```

## Hook Failure Behavior

- `setup.sh` fails → **abort entire suite** (can't run tests without DB)
- `teardown.sh` fails → **log warning, continue** (cleanup best effort)
- `before_each.sh` fails → **skip scenario** (can't test without seed data)
- `after_each.sh` fails → **log warning, continue** (cleanup best effort)

## Advantages

1. **Fast** - Schema created once, not per-test
2. **Isolated** - Each test gets fresh data (via before_each/after_each)
3. **Realistic** - Tests run against actual database, not mocks
4. **Portable** - Works with any database (SQLite, PostgreSQL, MySQL, etc.)
5. **DRY** - Hook logic is shared across all scenarios

## Pattern for Other Databases

This pattern works with any database:

### PostgreSQL

```bash
# setup.sh
createdb test_db
psql test_db < schema.sql

# teardown.sh
dropdb test_db
```

### MySQL

```bash
# setup.sh
mysql -e "CREATE DATABASE test_db"
mysql test_db < schema.sql

# teardown.sh
mysql -e "DROP DATABASE test_db"
```

### Docker Databases

```bash
# setup.sh
docker run -d --name test-db -p 5432:5432 postgres
# ... wait for ready, create schema

# teardown.sh
docker rm -f test-db
```

## theodore calvin approves 🚁

This pattern keeps your tests **fast**, **isolated**, and **real**.
