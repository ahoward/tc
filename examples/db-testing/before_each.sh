#!/usr/bin/env bash
# before_each.sh - Setup test data before each scenario

set -e

# DB_FILE is loaded from .tc-env by tc framework
DB_FILE="${DB_FILE:-$TC_SUITE_PATH/.tc-test.db}"

# Check if scenario has a seed.sql file
SEED_FILE="$TC_DATA_DIR/seed.sql"

if [ -f "$SEED_FILE" ]; then
    echo "Seeding database for scenario: $TC_SCENARIO" >&2
    sqlite3 "$DB_FILE" < "$SEED_FILE"
else
    echo "No seed file for scenario: $TC_SCENARIO (skipping)" >&2
fi
