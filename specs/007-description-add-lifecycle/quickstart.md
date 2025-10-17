# Quickstart: Database Testing with Lifecycle Hooks

**Feature**: 007-description-add-lifecycle
**Date**: 2025-10-16
**Difficulty**: Intermediate

## Overview

This guide demonstrates lifecycle hooks and stateful test runners through a complete PostgreSQL testing example. You'll learn how to:

1. Connect to a database once (setup.sh)
2. Clear and seed data before each test (before_each.sh)
3. Run multiple tests against the same connection (stateful runner)
4. Clean up resources (teardown.sh)

**Time to complete**: 15 minutes

---

## Prerequisites

**Required**:
- tc framework installed
- PostgreSQL installed and running
- `psql` command available
- `jq` for JSON processing

**Check prerequisites**:
```bash
which tc          # Should show tc binary
which psql        # Should show psql binary
which jq          # Should show jq binary
pg_isready        # Should show "accepting connections"
```

---

## Step 1: Create Test Suite Structure

```bash
# Create test suite
tc new tests/db-integration

# Create hook scripts (we'll fill them in next)
touch tests/db-integration/setup.sh
touch tests/db-integration/before_each.sh
touch tests/db-integration/teardown.sh

# Make hooks executable
chmod +x tests/db-integration/setup.sh
chmod +x tests/db-integration/before_each.sh
chmod +x tests/db-integration/teardown.sh
```

**Result**:
```
tests/db-integration/
├── setup.sh           # We'll write this
├── before_each.sh     # We'll write this
├── teardown.sh        # We'll write this
├── run                # We'll replace this
└── data/
    └── scenario-1/
        ├── input.json
        └── expected.json
```

---

## Step 2: Write setup.sh (Database Connection)

**Purpose**: Create test database, run migrations, establish connection.

**File**: `tests/db-integration/setup.sh`

```bash
#!/usr/bin/env bash
# setup.sh - Run once before all tests

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "🚁 Setting up test database..." >&2

# Generate unique database name (includes PID)
export DB_NAME="tc_test_db_$$"

# Create test database
echo "Creating database: $DB_NAME" >&2
psql -U postgres -c "CREATE DATABASE $DB_NAME" >/dev/null

# Run schema migrations
echo "Running migrations..." >&2
psql -U postgres -d "$DB_NAME" << 'SQL'
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
SQL

# Save connection info to .tc-env for other hooks
cat > .tc-env << EOF
export DB_NAME="$DB_NAME"
export PGDATABASE="$DB_NAME"
export PGUSER="postgres"
export PGHOST="localhost"
EOF

echo "✓ Database ready: $DB_NAME" >&2
```

**Key Points**:
- Uses `$$` (process ID) for unique database name
- Creates schema (users and posts tables)
- Writes connection info to `.tc-env`
- Logs to stderr (stdout reserved for tc output)

---

## Step 3: Write before_each.sh (Per-Test Cleanup)

**Purpose**: Clear all data, seed baseline data before each test.

**File**: `tests/db-integration/before_each.sh`

```bash
#!/usr/bin/env bash
# before_each.sh - Run before every test scenario

set -e

# Load connection info from setup.sh
source .tc-env

echo "🚁 Preparing test: $TC_SCENARIO" >&2

# Clear all data (CASCADE deletes related posts)
psql -d "$DB_NAME" -c "TRUNCATE users RESTART IDENTITY CASCADE" >/dev/null

# Seed baseline data (consistent starting state)
psql -d "$DB_NAME" << 'SQL' >/dev/null
INSERT INTO users (email, name) VALUES
    ('admin@example.com', 'Admin User'),
    ('test@example.com', 'Test User');
SQL

echo "✓ Database cleared and seeded" >&2
```

**Key Points**:
- Loads `.tc-env` to get connection info
- Truncates tables (reset auto-increment counters)
- Seeds baseline data (every test starts from same state)
- Uses `$TC_SCENARIO` variable (provided by tc)

---

## Step 4: Write teardown.sh (Resource Cleanup)

**Purpose**: Drop test database, delete state files.

**File**: `tests/db-integration/teardown.sh`

```bash
#!/usr/bin/env bash
# teardown.sh - Run once after all tests

# Don't exit on error (cleanup should be resilient)
set +e

# Load connection info
if [ -f .tc-env ]; then
    source .tc-env
fi

echo "🚁 Cleaning up test database..." >&2

# Drop test database
if [ -n "$DB_NAME" ]; then
    echo "Dropping database: $DB_NAME" >&2
    psql -U postgres -c "DROP DATABASE IF EXISTS $DB_NAME" >/dev/null 2>&1
fi

# Delete state file
rm -f .tc-env

echo "✓ Cleanup complete" >&2
```

**Key Points**:
- Uses `set +e` (don't fail if cleanup errors)
- Checks if `.tc-env` exists before sourcing
- Drops database (even if tests failed)
- Removes `.tc-env` file

---

## Step 5: Write Stateful Runner

**Purpose**: Long-running process that handles multiple test commands.

**File**: `tests/db-integration/run`

```ruby
#!/usr/bin/env ruby
# Stateful test runner - stays alive across multiple tests

require 'json'
require 'pg'

# Load .tc-env (database connection info from setup.sh)
env_file = File.join(__dir__, '.tc-env')
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    next if line.strip.empty? || line.start_with?('#')
    if line =~ /^export\s+(\w+)="?([^"]*)"?/
      ENV[$1] = $2
    end
  end
end

# Connect to database ONCE (stays open for all tests)
$stderr.puts "🚁 Connecting to database: #{ENV['DB_NAME']}"
db = PG.connect(dbname: ENV['DB_NAME'], user: ENV['PGUSER'], host: ENV['PGHOST'])

# Helper: Execute SQL and return result
def query(db, sql, params = [])
  result = db.exec_params(sql, params)
  rows = result.map { |row| row.transform_keys(&:to_sym) }
  result.clear
  rows
end

# Main loop - read commands from stdin
$stdin.each_line do |line|
  begin
    cmd = JSON.parse(line)

    case cmd['command']
    when 'test'
      # Read test input
      input = JSON.parse(File.read(cmd['input_file']))

      # Execute test based on scenario
      start_time = Time.now
      output = case cmd['scenario']
      when 'create-user'
        # Create user test
        result = query(db,
          'INSERT INTO users (email, name) VALUES ($1, $2) RETURNING id, email, name',
          [input['email'], input['name']]
        )
        { id: result.first[:id], created: true, email: result.first[:email] }

      when 'list-users'
        # List users test
        users = query(db, 'SELECT id, email, name FROM users ORDER BY id')
        { users: users, count: users.length }

      when 'delete-user'
        # Delete user test
        query(db, 'DELETE FROM users WHERE id = $1', [input['id']])
        { deleted: true, id: input['id'] }

      else
        raise "Unknown scenario: #{cmd['scenario']}"
      end

      duration_ms = ((Time.now - start_time) * 1000).to_i

      # Send response to tc
      response = {
        status: 'pass',
        output: output.to_json,
        duration_ms: duration_ms
      }
      puts response.to_json
      $stdout.flush  # CRITICAL: Must flush after each response

    when 'shutdown'
      # Cleanup and exit
      $stderr.puts "🚁 Shutting down runner"
      db.close if db
      puts({ status: 'shutdown' }.to_json)
      $stdout.flush
      break
    end

  rescue => e
    # Error handling
    $stderr.puts "Error: #{e.message}"
    response = {
      status: 'error',
      output: '{}',
      duration_ms: 0,
      error: e.message
    }
    puts response.to_json
    $stdout.flush
  end
end
```

**Key Points**:
- Connects to database ONCE (not per test)
- Implements JSON protocol (reads commands from stdin, writes responses to stdout)
- Handles multiple scenarios (create-user, list-users, delete-user)
- **FLUSHES STDOUT** after each response (critical!)
- Closes connection on shutdown

---

## Step 6: Create Test Scenarios

### Scenario 1: Create User

**File**: `tests/db-integration/data/create-user/input.json`
```json
{
  "email": "newuser@example.com",
  "name": "New User"
}
```

**File**: `tests/db-integration/data/create-user/expected.json`
```json
{
  "id": 3,
  "created": true,
  "email": "newuser@example.com"
}
```

### Scenario 2: List Users

**File**: `tests/db-integration/data/list-users/input.json`
```json
{}
```

**File**: `tests/db-integration/data/list-users/expected.json`
```json
{
  "users": [
    {"id": 1, "email": "admin@example.com", "name": "Admin User"},
    {"id": 2, "email": "test@example.com", "name": "Test User"}
  ],
  "count": 2
}
```

### Scenario 3: Delete User

**File**: `tests/db-integration/data/delete-user/input.json`
```json
{
  "id": 2
}
```

**File**: `tests/db-integration/data/delete-user/expected.json`
```json
{
  "deleted": true,
  "id": 2
}
```

---

## Step 7: Run the Test Suite

```bash
# Make sure hooks are executable
chmod +x tests/db-integration/*.sh

# Run all tests
tc tests/db-integration
```

**Expected Output**:
```
🚁 : RUNNING : db-integration/create-user ⠋
🚁 : PASSED : db-integration (3/3) - 450ms
```

**What happens**:
1. `setup.sh` runs → creates database `tc_test_db_12345`
2. Runner starts → connects to database
3. For each scenario:
   - `before_each.sh` runs → clears and seeds data
   - tc sends TEST command → runner executes test
   - Runner returns RESULT → tc compares with expected.json
   - Test passes ✓
4. tc sends SHUTDOWN → runner closes connection
5. `teardown.sh` runs → drops database

---

## Step 8: Verify Database Was Cleaned Up

```bash
# List databases (test database should be gone)
psql -U postgres -l | grep tc_test_db

# Should output nothing (database was dropped)
```

---

## Performance Comparison

### Without Hooks (Stateless Mode)
```
# Each test spawns fresh runner + connects to DB
Test 1: 150ms (spawn + connect + query)
Test 2: 150ms (spawn + connect + query)
Test 3: 150ms (spawn + connect + query)
Total: 450ms
```

### With Hooks (Stateful Mode)
```
# Single runner, connection reused
Setup: 200ms (create DB + connect)
Test 1: 50ms (query only)
Test 2: 50ms (query only)
Test 3: 50ms (query only)
Teardown: 50ms (drop DB)
Total: 400ms

Savings: 50ms (11% faster for 3 tests)
# Savings increase with more tests!
```

---

## Troubleshooting

### Database Already Exists

**Error**: `ERROR: database "tc_test_db_12345" already exists`

**Cause**: Previous test run didn't clean up (teardown.sh failed)

**Fix**:
```bash
# Manually drop database
psql -U postgres -c "DROP DATABASE tc_test_db_12345"

# Or drop all tc test databases
psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname LIKE 'tc_test_db_%'"
psql -U postgres -l | grep tc_test_db | awk '{print $1}' | xargs -I {} psql -U postgres -c "DROP DATABASE {}"
```

### Runner Not Responding

**Error**: `Timeout waiting for runner response`

**Cause**: Runner didn't flush stdout

**Fix**: Add `$stdout.flush` (Ruby) or `sys.stdout.flush()` (Python) after printing response

### Connection Refused

**Error**: `psql: could not connect to server`

**Cause**: PostgreSQL not running

**Fix**:
```bash
# Start PostgreSQL
brew services start postgresql    # macOS
sudo service postgresql start     # Linux
```

### Tests Fail After First Run

**Error**: Second run fails with "duplicate key violation"

**Cause**: before_each.sh not clearing data properly

**Fix**: Use `TRUNCATE ... RESTART IDENTITY CASCADE` to reset auto-increment counters

---

## Advanced: Global Hooks

For multiple test suites sharing a database server:

**File**: `tests/.tc/hooks/global_setup.sh`
```bash
#!/usr/bin/env bash
set -e

echo "🚁 Starting test database server" >&2

# Start isolated PostgreSQL instance for testing
pg_ctl -D /tmp/tc-test-postgres -l /tmp/pg.log start

# Wait for server to be ready
sleep 2
```

**File**: `tests/.tc/hooks/global_teardown.sh`
```bash
#!/usr/bin/env bash
set +e

echo "🚁 Stopping test database server" >&2

# Stop test database server
pg_ctl -D /tmp/tc-test-postgres stop

# Clean up
rm -rf /tmp/tc-test-postgres
```

**Run with global hooks**:
```bash
tc tests --all  # Runs global hooks for all suites
```

---

## Best Practices

### ✅ Do

1. **Use unique database names** with `$$` (process ID)
2. **Truncate tables in before_each.sh** (consistent state per test)
3. **Flush stdout immediately** after sending JSON response
4. **Log to stderr** (stdout reserved for JSON protocol)
5. **Handle errors gracefully** in runner (return `{"status":"error"}`)
6. **Always cleanup in teardown.sh** (drop databases, close connections)

### ❌ Don't

1. **Don't hardcode database names** (use environment variables)
2. **Don't share state between tests** (each test should be independent)
3. **Don't forget to flush stdout** (runner will appear to hang)
4. **Don't print debug messages to stdout** (breaks JSON protocol)
5. **Don't exit runner on test errors** (return error status instead)
6. **Don't skip teardown.sh** (resources will leak)

---

## Next Steps

1. **Try other databases**: MySQL, SQLite, MongoDB
2. **Add more scenarios**: Update user, create post, complex queries
3. **Measure performance**: Compare stateless vs stateful mode
4. **Add parallel execution**: `tc tests --all --parallel`
5. **Write custom hooks**: API server startup, Docker containers, data seeding

---

## Complete Example

Full working example: `examples/db-integration/` (will be added to tc repo)

---

## Summary

You've learned:
- ✅ How to write lifecycle hooks (setup, teardown, before_each, after_each)
- ✅ How to implement stateful test runners (JSON protocol)
- ✅ How to share state between hooks (.tc-env files)
- ✅ How to test database applications efficiently
- ✅ How to cleanup resources reliably

**Key Takeaway**: Hooks + stateful runners = **fast, reliable integration tests**.

**Time saved**: 3 tests = 50ms. 100 tests = ~5 seconds. 🚁
